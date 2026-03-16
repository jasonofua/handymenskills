-- Migration: Add LGA column to profiles and create state/LGA-based worker search
-- This replaces the GPS/PostGIS-based search_workers_nearby with a state/LGA filter approach.

-- 1. Add LGA column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS lga TEXT;

-- 2. Create index for state + LGA lookups
CREATE INDEX IF NOT EXISTS idx_profiles_state_lga ON profiles (state, lga);

-- 3. Create RPC function for searching workers by state and LGA
CREATE OR REPLACE FUNCTION search_workers_by_location(
  p_state TEXT DEFAULT NULL,
  p_lga TEXT DEFAULT NULL,
  p_skill_id UUID DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_min_rating NUMERIC DEFAULT NULL,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  worker_profile_id UUID,
  user_id UUID,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  headline TEXT,
  is_available BOOLEAN,
  verification_status verification_status,
  average_rating NUMERIC,
  total_reviews INTEGER,
  total_jobs_completed INTEGER,
  worker_state TEXT,
  worker_lga TEXT,
  skills JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    wp.id AS worker_profile_id,
    wp.user_id,
    p.full_name,
    p.avatar_url,
    wp.bio,
    wp.headline,
    wp.is_available,
    wp.verification_status,
    wp.average_rating,
    wp.total_reviews,
    wp.total_jobs_completed,
    p.state AS worker_state,
    p.lga AS worker_lga,
    COALESCE(
      (SELECT jsonb_agg(jsonb_build_object(
        'skill_id', ws.skill_id,
        'skill_name', s.name,
        'proficiency', ws.proficiency,
        'hourly_rate', ws.hourly_rate,
        'years_experience', ws.years_experience
      ))
      FROM worker_skills ws
      JOIN skills s ON s.id = ws.skill_id
      WHERE ws.worker_id = wp.id),
      '[]'::jsonb
    ) AS skills
  FROM worker_profiles wp
  JOIN profiles p ON p.id = wp.user_id
  WHERE wp.is_available = true
    AND wp.verification_status = 'verified'
    AND p.account_status = 'active'
    AND (p_state IS NULL OR p.state = p_state)
    AND (p_lga IS NULL OR p.lga = p_lga)
    AND (p_min_rating IS NULL OR wp.average_rating >= p_min_rating)
    AND (p_skill_id IS NULL OR EXISTS (
      SELECT 1 FROM worker_skills ws
      WHERE ws.worker_id = wp.id AND ws.skill_id = p_skill_id
    ))
    AND (p_category_id IS NULL OR EXISTS (
      SELECT 1 FROM worker_skills ws
      JOIN skills s ON s.id = ws.skill_id
      WHERE ws.worker_id = wp.id AND s.category_id = p_category_id
    ))
  ORDER BY wp.average_rating DESC, wp.total_jobs_completed DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;
