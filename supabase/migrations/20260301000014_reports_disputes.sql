-- Reports and disputes

CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id),
  reported_id UUID NOT NULL REFERENCES profiles(id),

  reason report_reason NOT NULL,
  description TEXT,
  evidence_urls TEXT[] DEFAULT '{}',

  status report_status NOT NULL DEFAULT 'pending',
  resolved_by UUID REFERENCES profiles(id),
  resolution_notes TEXT,
  resolved_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL UNIQUE REFERENCES bookings(id),
  initiator_id UUID NOT NULL REFERENCES profiles(id),

  reason TEXT NOT NULL,
  evidence TEXT[] DEFAULT '{}',

  status dispute_status NOT NULL DEFAULT 'open',
  resolution TEXT,
  resolved_by UUID REFERENCES profiles(id),
  resolved_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER reports_updated_at
  BEFORE UPDATE ON reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER disputes_updated_at
  BEFORE UPDATE ON disputes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
