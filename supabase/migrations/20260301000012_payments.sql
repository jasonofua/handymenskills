-- Payments and payouts

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  booking_id UUID REFERENCES bookings(id),
  subscription_id UUID, -- will reference subscriptions table after it's created

  payment_type payment_type NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'NGN',
  status payment_status NOT NULL DEFAULT 'pending',

  -- Paystack
  paystack_reference TEXT UNIQUE,
  paystack_access_code TEXT,
  payment_method payment_method,

  -- Verification
  verified_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id UUID NOT NULL REFERENCES profiles(id),
  booking_id UUID REFERENCES bookings(id),

  amount NUMERIC(12,2) NOT NULL,
  status payout_status NOT NULL DEFAULT 'pending',

  -- Bank details (snapshot at time of payout)
  bank_name TEXT,
  account_number TEXT,
  account_name TEXT,

  -- Paystack transfer
  paystack_transfer_code TEXT,
  paystack_recipient_code TEXT,

  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER payouts_updated_at
  BEFORE UPDATE ON payouts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
