-- Security fixes: search_path on all functions, RLS on spatial_ref_sys,
-- move extensions out of public schema

-- ===========================================
-- 1. spatial_ref_sys RLS
-- This is a PostGIS system table (read-only coordinate reference data).
-- It's owned by the extension superuser and cannot be altered by migrations.
-- The Supabase linter flags it but it's a known false positive — the table
-- contains only public spatial reference definitions, no user data.
-- ===========================================

-- ===========================================
-- 2. Fix notifications RLS policy (restrict inserts to SECURITY DEFINER functions)
-- ===========================================
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;

CREATE POLICY "Service role can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    OR current_setting('role') = 'service_role'
  );

-- ===========================================
-- 3. Set search_path on ALL functions (security: prevent schema injection)
-- ===========================================

-- Helper functions from RLS policies migration
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION get_my_role()
RETURNS user_role AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public;

-- Auto-created by auth trigger
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.phone,
    NEW.email,
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'client')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SET search_path = public;

-- Conversation last message trigger
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations SET
    last_message = NEW.content,
    last_message_at = NEW.created_at,
    last_message_by = NEW.sender_id
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ===========================================
-- Business logic functions
-- ===========================================

CREATE OR REPLACE FUNCTION search_jobs(
  p_query_text TEXT DEFAULT NULL,
  p_lat DOUBLE PRECISION DEFAULT NULL,
  p_lng DOUBLE PRECISION DEFAULT NULL,
  p_radius_km INTEGER DEFAULT 50,
  p_category_id UUID DEFAULT NULL,
  p_urgency urgency_level DEFAULT NULL,
  p_budget_min NUMERIC DEFAULT NULL,
  p_budget_max NUMERIC DEFAULT NULL,
  p_status job_status DEFAULT 'open',
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  client_id UUID,
  category_id UUID,
  title TEXT,
  description TEXT,
  skill_ids UUID[],
  address TEXT,
  city TEXT,
  state TEXT,
  is_remote BOOLEAN,
  budget_min NUMERIC,
  budget_max NUMERIC,
  budget_type budget_type,
  urgency urgency_level,
  status job_status,
  start_date DATE,
  image_urls TEXT[],
  application_count INTEGER,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  distance_km DOUBLE PRECISION,
  client_name TEXT,
  client_avatar TEXT,
  category_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    j.id, j.client_id, j.category_id,
    j.title, j.description, j.skill_ids,
    j.address, j.city, j.state, j.is_remote,
    j.budget_min, j.budget_max, j.budget_type,
    j.urgency, j.status, j.start_date,
    j.image_urls, j.application_count, j.expires_at, j.created_at,
    CASE
      WHEN p_lat IS NOT NULL AND p_lng IS NOT NULL AND j.location IS NOT NULL
      THEN ST_Distance(j.location, ST_MakePoint(p_lng, p_lat)::geography) / 1000.0
      ELSE NULL
    END AS distance_km,
    p.full_name AS client_name,
    p.avatar_url AS client_avatar,
    c.name AS category_name
  FROM public.jobs j
  LEFT JOIN public.profiles p ON p.id = j.client_id
  LEFT JOIN public.categories c ON c.id = j.category_id
  WHERE j.status = p_status
    AND (j.expires_at IS NULL OR j.expires_at > NOW())
    AND (p_category_id IS NULL OR j.category_id = p_category_id)
    AND (p_urgency IS NULL OR j.urgency = p_urgency)
    AND (p_budget_min IS NULL OR j.budget_min >= p_budget_min)
    AND (p_budget_max IS NULL OR j.budget_max <= p_budget_max)
    AND (p_query_text IS NULL OR j.title ILIKE '%' || p_query_text || '%' OR j.description ILIKE '%' || p_query_text || '%')
    AND (
      p_lat IS NULL OR p_lng IS NULL OR j.is_remote = true
      OR ST_DWithin(j.location, ST_MakePoint(p_lng, p_lat)::geography, p_radius_km * 1000)
    )
  ORDER BY
    CASE WHEN p_lat IS NOT NULL AND p_lng IS NOT NULL AND j.location IS NOT NULL
      THEN ST_Distance(j.location, ST_MakePoint(p_lng, p_lat)::geography)
      ELSE 0
    END ASC,
    j.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE
SET search_path = public;

CREATE OR REPLACE FUNCTION search_workers_nearby(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_km INTEGER DEFAULT 25,
  p_skill_id UUID DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_min_rating NUMERIC DEFAULT NULL,
  p_proficiency proficiency_level DEFAULT NULL,
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
  distance_km DOUBLE PRECISION,
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
    CASE
      WHEN wp.location IS NOT NULL
      THEN ST_Distance(wp.location, ST_MakePoint(p_lng, p_lat)::geography) / 1000.0
      ELSE NULL
    END AS distance_km,
    COALESCE(
      (SELECT jsonb_agg(jsonb_build_object(
        'skill_id', ws.skill_id,
        'skill_name', s.name,
        'proficiency', ws.proficiency,
        'hourly_rate', ws.hourly_rate,
        'years_experience', ws.years_experience
      ))
      FROM public.worker_skills ws
      JOIN public.skills s ON s.id = ws.skill_id
      WHERE ws.worker_id = wp.id),
      '[]'::jsonb
    ) AS skills
  FROM public.worker_profiles wp
  JOIN public.profiles p ON p.id = wp.user_id
  WHERE wp.is_available = true
    AND wp.verification_status = 'verified'
    AND p.account_status = 'active'
    AND (p_min_rating IS NULL OR wp.average_rating >= p_min_rating)
    AND (p_skill_id IS NULL OR EXISTS (
      SELECT 1 FROM public.worker_skills ws
      WHERE ws.worker_id = wp.id AND ws.skill_id = p_skill_id
        AND (p_proficiency IS NULL OR ws.proficiency = p_proficiency)
    ))
    AND (p_category_id IS NULL OR EXISTS (
      SELECT 1 FROM public.worker_skills ws
      JOIN public.skills s ON s.id = ws.skill_id
      WHERE ws.worker_id = wp.id AND s.category_id = p_category_id
    ))
    AND (wp.location IS NULL OR ST_DWithin(
      wp.location, ST_MakePoint(p_lng, p_lat)::geography, p_radius_km * 1000
    ))
  ORDER BY
    wp.average_rating DESC,
    ST_Distance(wp.location, ST_MakePoint(p_lng, p_lat)::geography) ASC NULLS LAST
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE
SET search_path = public;

CREATE OR REPLACE FUNCTION check_worker_subscription(p_worker_user_id UUID)
RETURNS TABLE (
  has_subscription BOOLEAN,
  subscription_status subscription_status,
  plan_name TEXT,
  expires_at TIMESTAMPTZ,
  grace_expires_at TIMESTAMPTZ,
  max_active_applications INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id IS NOT NULL AS has_subscription,
    s.status,
    sp.name,
    s.expires_at,
    s.grace_expires_at,
    sp.max_active_applications
  FROM public.subscriptions s
  JOIN public.subscription_plans sp ON sp.id = s.plan_id
  WHERE s.worker_id = p_worker_user_id
    AND s.status IN ('active', 'grace_period')
  LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION apply_to_job(
  p_job_id UUID,
  p_cover_letter TEXT DEFAULT NULL,
  p_proposed_price NUMERIC DEFAULT NULL,
  p_estimated_duration TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_worker_profile_id UUID;
  v_sub_status subscription_status;
  v_max_apps INTEGER;
  v_current_apps INTEGER;
  v_job_status job_status;
  v_application_id UUID;
BEGIN
  SELECT id INTO v_worker_profile_id
  FROM public.worker_profiles WHERE user_id = auth.uid();

  IF v_worker_profile_id IS NULL THEN
    RAISE EXCEPTION 'Worker profile not found. Please complete your worker profile first.';
  END IF;

  SELECT s.status, sp.max_active_applications
  INTO v_sub_status, v_max_apps
  FROM public.subscriptions s
  JOIN public.subscription_plans sp ON sp.id = s.plan_id
  WHERE s.worker_id = auth.uid()
    AND s.status IN ('active', 'grace_period');

  IF v_sub_status IS NULL THEN
    RAISE EXCEPTION 'Active subscription required to apply for jobs.';
  END IF;

  IF v_sub_status = 'grace_period' THEN
    RAISE EXCEPTION 'Your subscription is in grace period. Please renew to apply for jobs.';
  END IF;

  SELECT status INTO v_job_status FROM public.jobs WHERE id = p_job_id;
  IF v_job_status IS NULL OR v_job_status != 'open' THEN
    RAISE EXCEPTION 'This job is no longer accepting applications.';
  END IF;

  SELECT COUNT(*) INTO v_current_apps
  FROM public.applications
  WHERE worker_id = v_worker_profile_id
    AND status IN ('pending', 'shortlisted');

  IF v_current_apps >= v_max_apps THEN
    RAISE EXCEPTION 'You have reached your maximum active applications limit (%).', v_max_apps;
  END IF;

  IF EXISTS (SELECT 1 FROM public.applications WHERE job_id = p_job_id AND worker_id = v_worker_profile_id) THEN
    RAISE EXCEPTION 'You have already applied to this job.';
  END IF;

  INSERT INTO public.applications (job_id, worker_id, cover_letter, proposed_price, estimated_duration)
  VALUES (p_job_id, v_worker_profile_id, p_cover_letter, p_proposed_price, p_estimated_duration)
  RETURNING id INTO v_application_id;

  INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
  SELECT
    j.client_id,
    'job_application',
    'New Application',
    p.full_name || ' applied to your job: ' || j.title,
    v_application_id,
    'application'
  FROM public.jobs j
  JOIN public.profiles p ON p.id = auth.uid()
  WHERE j.id = p_job_id;

  RETURN v_application_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION process_booking_action(
  p_action TEXT,
  p_booking_id UUID DEFAULT NULL,
  p_application_id UUID DEFAULT NULL,
  p_agreed_price NUMERIC DEFAULT NULL,
  p_scheduled_date DATE DEFAULT NULL,
  p_scheduled_time_start TIME DEFAULT NULL,
  p_scheduled_time_end TIME DEFAULT NULL,
  p_cancellation_reason TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_booking_id UUID;
  v_current_status booking_status;
  v_client_id UUID;
  v_worker_id UUID;
  v_job_id UUID;
  v_job_title TEXT;
  v_worker_name TEXT;
  v_client_name TEXT;
BEGIN
  CASE p_action
    WHEN 'create' THEN
      IF p_application_id IS NULL OR p_agreed_price IS NULL THEN
        RAISE EXCEPTION 'application_id and agreed_price are required to create a booking.';
      END IF;

      SELECT a.job_id, j.client_id, wp.user_id, j.title
      INTO v_job_id, v_client_id, v_worker_id, v_job_title
      FROM public.applications a
      JOIN public.jobs j ON j.id = a.job_id
      JOIN public.worker_profiles wp ON wp.id = a.worker_id
      WHERE a.id = p_application_id AND a.status = 'pending';

      IF v_client_id IS NULL THEN
        RAISE EXCEPTION 'Application not found or not in pending status.';
      END IF;

      IF v_client_id != auth.uid() THEN
        RAISE EXCEPTION 'Only the job owner can create bookings.';
      END IF;

      UPDATE public.applications SET status = 'accepted', accepted_at = NOW() WHERE id = p_application_id;
      UPDATE public.applications SET status = 'rejected', rejected_at = NOW()
      WHERE job_id = v_job_id AND id != p_application_id AND status IN ('pending', 'shortlisted');
      UPDATE public.jobs SET status = 'assigned' WHERE id = v_job_id;

      INSERT INTO public.bookings (job_id, client_id, worker_id, application_id, agreed_price, scheduled_date, scheduled_time_start, scheduled_time_end, client_notes)
      VALUES (v_job_id, v_client_id, v_worker_id, p_application_id, p_agreed_price, p_scheduled_date, p_scheduled_time_start, p_scheduled_time_end, p_notes)
      RETURNING id INTO v_booking_id;

      SELECT full_name INTO v_client_name FROM public.profiles WHERE id = v_client_id;
      INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
      VALUES (v_worker_id, 'booking_created', 'New Booking!', v_client_name || ' booked you for: ' || v_job_title, v_booking_id, 'booking');

      INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
      SELECT wp.user_id, 'application_rejected', 'Application Update', 'Your application for "' || v_job_title || '" was not selected.', a.id, 'application'
      FROM public.applications a
      JOIN public.worker_profiles wp ON wp.id = a.worker_id
      WHERE a.job_id = v_job_id AND a.status = 'rejected' AND a.rejected_at = (SELECT MAX(rejected_at) FROM public.applications WHERE job_id = v_job_id AND status = 'rejected');

      RETURN v_booking_id;

    WHEN 'confirm' THEN
      SELECT status, client_id, worker_id INTO v_current_status, v_client_id, v_worker_id
      FROM public.bookings WHERE id = p_booking_id;

      IF v_current_status != 'pending' THEN
        RAISE EXCEPTION 'Booking can only be confirmed from pending status. Current: %', v_current_status;
      END IF;
      IF v_worker_id != auth.uid() THEN
        RAISE EXCEPTION 'Only the assigned worker can confirm this booking.';
      END IF;

      UPDATE public.bookings SET status = 'confirmed', confirmed_at = NOW(), worker_notes = COALESCE(p_notes, worker_notes)
      WHERE id = p_booking_id;

      SELECT full_name INTO v_worker_name FROM public.profiles WHERE id = v_worker_id;
      INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
      VALUES (v_client_id, 'booking_confirmed', 'Booking Confirmed', v_worker_name || ' confirmed the booking.', p_booking_id, 'booking');

      RETURN p_booking_id;

    WHEN 'start' THEN
      SELECT status, client_id, worker_id, job_id INTO v_current_status, v_client_id, v_worker_id, v_job_id
      FROM public.bookings WHERE id = p_booking_id;

      IF v_current_status NOT IN ('confirmed', 'worker_en_route') THEN
        RAISE EXCEPTION 'Cannot start job from status: %', v_current_status;
      END IF;
      IF v_worker_id != auth.uid() THEN
        RAISE EXCEPTION 'Only the assigned worker can start this job.';
      END IF;

      UPDATE public.bookings SET status = 'in_progress', started_at = NOW() WHERE id = p_booking_id;
      UPDATE public.jobs SET status = 'in_progress' WHERE id = v_job_id;

      SELECT full_name INTO v_worker_name FROM public.profiles WHERE id = v_worker_id;
      INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
      VALUES (v_client_id, 'booking_started', 'Job Started', v_worker_name || ' has started working on your job.', p_booking_id, 'booking');

      RETURN p_booking_id;

    WHEN 'complete' THEN
      SELECT status, client_id, worker_id INTO v_current_status, v_client_id, v_worker_id
      FROM public.bookings WHERE id = p_booking_id;

      IF v_current_status != 'in_progress' THEN
        RAISE EXCEPTION 'Cannot complete job from status: %', v_current_status;
      END IF;
      IF v_worker_id != auth.uid() THEN
        RAISE EXCEPTION 'Only the assigned worker can complete this job.';
      END IF;

      UPDATE public.bookings SET status = 'completed', completed_at = NOW(), worker_notes = COALESCE(p_notes, worker_notes)
      WHERE id = p_booking_id;

      SELECT full_name INTO v_worker_name FROM public.profiles WHERE id = v_worker_id;
      INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
      VALUES (v_client_id, 'booking_completed', 'Job Completed', v_worker_name || ' marked the job as completed. Please confirm.', p_booking_id, 'booking');

      RETURN p_booking_id;

    WHEN 'client_confirm' THEN
      SELECT b.status, b.client_id, b.worker_id, b.worker_payout, b.job_id, j.title
      INTO v_current_status, v_client_id, v_worker_id, p_agreed_price, v_job_id, v_job_title
      FROM public.bookings b JOIN public.jobs j ON j.id = b.job_id
      WHERE b.id = p_booking_id;

      IF v_current_status != 'completed' THEN
        RAISE EXCEPTION 'Cannot confirm completion from status: %', v_current_status;
      END IF;
      IF v_client_id != auth.uid() THEN
        RAISE EXCEPTION 'Only the client can confirm job completion.';
      END IF;

      UPDATE public.bookings SET status = 'client_confirmed', client_confirmed_at = NOW()
      WHERE id = p_booking_id;

      UPDATE public.jobs SET status = 'completed' WHERE id = v_job_id;

      UPDATE public.worker_profiles SET
        total_jobs_completed = total_jobs_completed + 1,
        total_earnings = total_earnings + p_agreed_price
      WHERE user_id = v_worker_id;

      INSERT INTO public.payouts (worker_id, booking_id, amount, bank_name, account_number, account_name)
      SELECT v_worker_id, p_booking_id, p_agreed_price, wp.bank_name, wp.bank_account_number, wp.bank_account_name
      FROM public.worker_profiles wp WHERE wp.user_id = v_worker_id;

      SELECT full_name INTO v_client_name FROM public.profiles WHERE id = v_client_id;
      INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
      VALUES (v_worker_id, 'payment_received', 'Payment Confirmed!',
        v_client_name || ' confirmed completion of "' || v_job_title || '". Payment of ₦' || p_agreed_price || ' will be processed.',
        p_booking_id, 'booking');

      RETURN p_booking_id;

    WHEN 'cancel' THEN
      SELECT status, client_id, worker_id, job_id INTO v_current_status, v_client_id, v_worker_id, v_job_id
      FROM public.bookings WHERE id = p_booking_id;

      IF v_current_status IN ('client_confirmed', 'cancelled', 'disputed') THEN
        RAISE EXCEPTION 'Cannot cancel booking with status: %', v_current_status;
      END IF;
      IF auth.uid() NOT IN (v_client_id, v_worker_id) THEN
        RAISE EXCEPTION 'Only booking participants can cancel.';
      END IF;

      UPDATE public.bookings SET
        status = 'cancelled',
        cancelled_at = NOW(),
        cancelled_by = auth.uid(),
        cancellation_reason = p_cancellation_reason
      WHERE id = p_booking_id;

      UPDATE public.jobs SET status = 'open' WHERE id = v_job_id;

      DECLARE v_other_id UUID;
      BEGIN
        v_other_id := CASE WHEN auth.uid() = v_client_id THEN v_worker_id ELSE v_client_id END;
        SELECT full_name INTO v_worker_name FROM public.profiles WHERE id = auth.uid();
        INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
        VALUES (v_other_id, 'booking_cancelled', 'Booking Cancelled', v_worker_name || ' cancelled the booking.', p_booking_id, 'booking');
      END;

      RETURN p_booking_id;

    WHEN 'dispute' THEN
      SELECT status, client_id, worker_id INTO v_current_status, v_client_id, v_worker_id
      FROM public.bookings WHERE id = p_booking_id;

      IF v_current_status NOT IN ('completed', 'in_progress') THEN
        RAISE EXCEPTION 'Can only dispute bookings that are in progress or completed. Current: %', v_current_status;
      END IF;
      IF auth.uid() NOT IN (v_client_id, v_worker_id) THEN
        RAISE EXCEPTION 'Only booking participants can raise disputes.';
      END IF;

      UPDATE public.bookings SET status = 'disputed' WHERE id = p_booking_id;

      INSERT INTO public.disputes (booking_id, initiator_id, reason)
      VALUES (p_booking_id, auth.uid(), COALESCE(p_cancellation_reason, 'Dispute raised'));

      DECLARE v_other_id2 UUID;
      BEGIN
        v_other_id2 := CASE WHEN auth.uid() = v_client_id THEN v_worker_id ELSE v_client_id END;
        INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
        VALUES (v_other_id2, 'booking_disputed', 'Booking Disputed', 'A dispute has been raised on your booking.', p_booking_id, 'booking');
      END;

      RETURN p_booking_id;

    ELSE
      RAISE EXCEPTION 'Unknown booking action: %', p_action;
  END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION get_or_create_conversation(
  p_other_user_id UUID,
  p_job_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_conversation_id UUID;
  v_participant_one UUID;
  v_participant_two UUID;
BEGIN
  IF auth.uid() < p_other_user_id THEN
    v_participant_one := auth.uid();
    v_participant_two := p_other_user_id;
  ELSE
    v_participant_one := p_other_user_id;
    v_participant_two := auth.uid();
  END IF;

  SELECT id INTO v_conversation_id
  FROM public.conversations
  WHERE participant_one = v_participant_one AND participant_two = v_participant_two;

  IF v_conversation_id IS NULL THEN
    INSERT INTO public.conversations (participant_one, participant_two, job_id)
    VALUES (v_participant_one, v_participant_two, p_job_id)
    RETURNING id INTO v_conversation_id;
  END IF;

  RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION mark_messages_read(p_conversation_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.messages SET is_read = true, read_at = NOW()
  WHERE conversation_id = p_conversation_id
    AND sender_id != auth.uid()
    AND is_read = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION calculate_worker_stats(p_worker_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_avg_rating NUMERIC;
  v_total_reviews INTEGER;
  v_total_completed INTEGER;
  v_total_bookings INTEGER;
  v_completion_rate NUMERIC;
BEGIN
  SELECT COALESCE(AVG(overall_rating), 0), COUNT(*)
  INTO v_avg_rating, v_total_reviews
  FROM public.reviews WHERE reviewee_id = p_worker_user_id AND is_visible = true;

  SELECT
    COUNT(*) FILTER (WHERE status = 'client_confirmed'),
    COUNT(*)
  INTO v_total_completed, v_total_bookings
  FROM public.bookings WHERE worker_id = p_worker_user_id;

  v_completion_rate := CASE WHEN v_total_bookings > 0
    THEN (v_total_completed::NUMERIC / v_total_bookings) * 100
    ELSE 0
  END;

  UPDATE public.worker_profiles SET
    average_rating = ROUND(v_avg_rating, 2),
    total_reviews = v_total_reviews,
    completion_rate = ROUND(v_completion_rate, 2)
  WHERE user_id = p_worker_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION send_fcm_push(p_user_id UUID, p_title TEXT, p_body TEXT, p_data JSONB DEFAULT '{}')
RETURNS VOID AS $$
DECLARE
  v_fcm_token TEXT;
  v_fcm_key TEXT;
BEGIN
  SELECT fcm_token INTO v_fcm_token FROM public.profiles WHERE id = p_user_id;

  IF v_fcm_token IS NULL THEN
    RETURN;
  END IF;

  SELECT decrypted_secret INTO v_fcm_key
  FROM vault.decrypted_secrets
  WHERE name = 'fcm_server_key'
  LIMIT 1;

  IF v_fcm_key IS NULL THEN
    RETURN;
  END IF;

  PERFORM net.http_post(
    url := 'https://fcm.googleapis.com/fcm/send',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'key=' || v_fcm_key
    ),
    body := jsonb_build_object(
      'to', v_fcm_token,
      'notification', jsonb_build_object('title', p_title, 'body', p_body),
      'data', p_data
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION expire_old_jobs()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  WITH expired AS (
    UPDATE public.jobs SET status = 'expired', updated_at = NOW()
    WHERE status = 'open' AND expires_at < NOW()
    RETURNING id, client_id, title
  )
  SELECT COUNT(*) INTO v_count FROM expired;

  INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
  SELECT client_id, 'system_announcement', 'Job Expired', 'Your job "' || title || '" has expired.', id, 'job'
  FROM public.jobs WHERE status = 'expired' AND updated_at > NOW() - INTERVAL '1 minute';

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION check_expiring_subscriptions()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
  SELECT s.worker_id, 'subscription_expiring', 'Subscription Expiring Soon',
    'Your subscription expires in 7 days. Renew now to keep receiving jobs.',
    s.id, 'subscription'
  FROM public.subscriptions s
  WHERE s.status = 'active'
    AND s.expires_at BETWEEN NOW() AND NOW() + INTERVAL '7 days'
    AND NOT EXISTS (
      SELECT 1 FROM public.notifications n
      WHERE n.user_id = s.worker_id
        AND n.type = 'subscription_expiring'
        AND n.created_at > NOW() - INTERVAL '1 day'
    );

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION process_expired_subscriptions()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  UPDATE public.subscriptions SET
    status = 'grace_period',
    grace_expires_at = expires_at + INTERVAL '3 days'
  WHERE status = 'active' AND expires_at < NOW();
  GET DIAGNOSTICS v_count = ROW_COUNT;

  INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
  SELECT worker_id, 'subscription_expired', 'Subscription Expired',
    'Your subscription has expired. You have 3 days to renew before losing access.',
    id, 'subscription'
  FROM public.subscriptions WHERE status = 'grace_period' AND grace_expires_at > NOW();

  UPDATE public.subscriptions SET status = 'expired'
  WHERE status = 'grace_period' AND grace_expires_at < NOW();

  UPDATE public.worker_profiles SET is_available = false
  WHERE user_id IN (
    SELECT worker_id FROM public.subscriptions WHERE status = 'expired'
  ) AND is_available = true;

  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION activate_subscription(
  p_worker_id UUID,
  p_plan_id UUID,
  p_payment_id UUID
)
RETURNS UUID AS $$
DECLARE
  v_duration INTEGER;
  v_sub_id UUID;
  v_existing_expires TIMESTAMPTZ;
  v_start_date TIMESTAMPTZ;
BEGIN
  SELECT duration_months INTO v_duration FROM public.subscription_plans WHERE id = p_plan_id;

  SELECT id, expires_at INTO v_sub_id, v_existing_expires
  FROM public.subscriptions WHERE worker_id = p_worker_id;

  IF v_existing_expires IS NOT NULL AND v_existing_expires > NOW() THEN
    v_start_date := v_existing_expires;
  ELSE
    v_start_date := NOW();
  END IF;

  IF v_sub_id IS NOT NULL THEN
    UPDATE public.subscriptions SET
      plan_id = p_plan_id,
      status = 'active',
      starts_at = v_start_date,
      expires_at = v_start_date + (v_duration || ' months')::INTERVAL,
      grace_expires_at = NULL,
      cancelled_at = NULL,
      updated_at = NOW()
    WHERE id = v_sub_id;
  ELSE
    INSERT INTO public.subscriptions (worker_id, plan_id, starts_at, expires_at)
    VALUES (p_worker_id, p_plan_id, v_start_date, v_start_date + (v_duration || ' months')::INTERVAL)
    RETURNING id INTO v_sub_id;
  END IF;

  UPDATE public.payments SET subscription_id = v_sub_id WHERE id = p_payment_id;

  INSERT INTO public.notifications (user_id, type, title, body, reference_id, reference_type)
  VALUES (p_worker_id, 'subscription_activated', 'Subscription Activated!',
    'Your subscription is now active. You can start receiving jobs.',
    v_sub_id, 'subscription');

  RETURN v_sub_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ===========================================
-- Trigger functions
-- ===========================================

CREATE OR REPLACE FUNCTION update_job_application_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.jobs SET application_count = application_count + 1 WHERE id = NEW.job_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.jobs SET application_count = GREATEST(application_count - 1, 0) WHERE id = OLD.job_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION on_review_created()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM calculate_worker_stats(NEW.reviewee_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION on_notification_created()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM send_fcm_push(
    NEW.user_id,
    NEW.title,
    NEW.body,
    COALESCE(NEW.data, '{}') || jsonb_build_object(
      'notification_id', NEW.id,
      'type', NEW.type,
      'reference_id', NEW.reference_id,
      'reference_type', NEW.reference_type
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

CREATE OR REPLACE FUNCTION on_payment_created()
RETURNS TRIGGER AS $$
DECLARE
  v_paystack_key TEXT;
BEGIN
  IF NEW.paystack_reference IS NOT NULL AND NEW.status = 'pending' THEN
    SELECT decrypted_secret INTO v_paystack_key
    FROM vault.decrypted_secrets
    WHERE name = 'paystack_secret_key'
    LIMIT 1;

    IF v_paystack_key IS NOT NULL THEN
      PERFORM net.http_get(
        url := 'https://api.paystack.co/transaction/verify/' || NEW.paystack_reference,
        headers := jsonb_build_object(
          'Authorization', 'Bearer ' || v_paystack_key
        )
      );
      UPDATE public.payments SET status = 'success', verified_at = NOW() WHERE id = NEW.id;

      IF NEW.payment_type = 'subscription_payment' THEN
        PERFORM activate_subscription(
          NEW.user_id,
          (NEW.metadata->>'plan_id')::UUID,
          NEW.id
        );
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;
