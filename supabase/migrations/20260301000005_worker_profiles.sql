-- Worker profiles, skills, schedule, and portfolio

CREATE TABLE worker_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,

  -- Bio
  bio TEXT,
  headline TEXT,
  experience_years INTEGER DEFAULT 0,

  -- Availability
  is_available BOOLEAN NOT NULL DEFAULT FALSE,
  service_radius_km INTEGER DEFAULT 25,

  -- Verification
  verification_status verification_status NOT NULL DEFAULT 'unverified',
  id_document_url TEXT,
  verification_notes TEXT,
  verified_at TIMESTAMPTZ,
  verified_by UUID,

  -- Location (can differ from profile address)
  location GEOGRAPHY(Point, 4326),

  -- Stats (denormalized, updated by triggers)
  average_rating NUMERIC(3,2) NOT NULL DEFAULT 0,
  total_reviews INTEGER NOT NULL DEFAULT 0,
  total_jobs_completed INTEGER NOT NULL DEFAULT 0,
  total_earnings NUMERIC(12,2) NOT NULL DEFAULT 0,
  completion_rate NUMERIC(5,2) NOT NULL DEFAULT 0,

  -- Portfolio images (array of storage URLs)
  portfolio_images TEXT[] DEFAULT '{}',

  -- Bank details for payouts
  bank_name TEXT,
  bank_account_number TEXT,
  bank_account_name TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Worker skills (many-to-many with proficiency)
CREATE TABLE worker_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id UUID NOT NULL REFERENCES worker_profiles(id) ON DELETE CASCADE,
  skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  proficiency proficiency_level NOT NULL DEFAULT 'beginner',
  years_experience INTEGER DEFAULT 0,
  hourly_rate NUMERIC(10,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(worker_id, skill_id)
);

-- Worker weekly schedule
CREATE TABLE worker_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id UUID NOT NULL REFERENCES worker_profiles(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday
  start_time TIME,
  end_time TIME,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,

  UNIQUE(worker_id, day_of_week)
);

CREATE TRIGGER worker_profiles_updated_at
  BEFORE UPDATE ON worker_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
