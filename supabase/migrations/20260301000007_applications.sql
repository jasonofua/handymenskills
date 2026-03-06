-- Job applications from workers

CREATE TABLE applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  worker_id UUID NOT NULL REFERENCES worker_profiles(id) ON DELETE CASCADE,

  status application_status NOT NULL DEFAULT 'pending',
  cover_letter TEXT CHECK (char_length(cover_letter) <= 500),
  proposed_price NUMERIC(10,2),
  estimated_duration TEXT,

  -- Status timestamps
  shortlisted_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  withdrawn_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(job_id, worker_id)
);

CREATE TRIGGER applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
