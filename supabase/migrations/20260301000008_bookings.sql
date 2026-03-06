-- Bookings with full lifecycle tracking

CREATE SEQUENCE booking_number_seq START 1000;

CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_number INTEGER NOT NULL DEFAULT nextval('booking_number_seq') UNIQUE,
  job_id UUID NOT NULL REFERENCES jobs(id),
  client_id UUID NOT NULL REFERENCES profiles(id),
  worker_id UUID NOT NULL REFERENCES profiles(id),
  application_id UUID REFERENCES applications(id),

  -- Status
  status booking_status NOT NULL DEFAULT 'pending',

  -- Financial
  agreed_price NUMERIC(10,2) NOT NULL,
  platform_commission NUMERIC(10,2) NOT NULL GENERATED ALWAYS AS (agreed_price * 0.15) STORED,
  worker_payout NUMERIC(10,2) NOT NULL GENERATED ALWAYS AS (agreed_price * 0.85) STORED,

  -- Scheduling
  scheduled_date DATE,
  scheduled_time_start TIME,
  scheduled_time_end TIME,

  -- Lifecycle timestamps
  confirmed_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  client_confirmed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,

  -- Cancellation
  cancellation_reason TEXT,
  cancelled_by UUID REFERENCES profiles(id),

  -- Notes
  client_notes TEXT,
  worker_notes TEXT,
  completion_photos TEXT[] DEFAULT '{}',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER bookings_updated_at
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
