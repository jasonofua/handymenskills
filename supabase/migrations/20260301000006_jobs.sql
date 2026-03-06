-- Jobs posted by clients

CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id),

  -- Details
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 10 AND 100),
  description TEXT NOT NULL CHECK (char_length(description) BETWEEN 50 AND 2000),
  skill_ids UUID[] DEFAULT '{}',

  -- Location
  location GEOGRAPHY(Point, 4326),
  address TEXT,
  city TEXT,
  state TEXT,
  is_remote BOOLEAN NOT NULL DEFAULT FALSE,

  -- Budget
  budget_min NUMERIC(10,2) CHECK (budget_min >= 500),
  budget_max NUMERIC(10,2),
  budget_type budget_type NOT NULL DEFAULT 'fixed',

  -- Scheduling
  urgency urgency_level NOT NULL DEFAULT 'medium',
  status job_status NOT NULL DEFAULT 'draft',
  start_date DATE,
  end_date DATE,
  preferred_time TEXT,

  -- Media
  image_urls TEXT[] DEFAULT '{}',

  -- Counters (denormalized)
  application_count INTEGER NOT NULL DEFAULT 0,
  view_count INTEGER NOT NULL DEFAULT 0,

  -- Expiry
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT budget_range_check CHECK (budget_max IS NULL OR budget_max >= budget_min)
);

CREATE TRIGGER jobs_updated_at
  BEFORE UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
