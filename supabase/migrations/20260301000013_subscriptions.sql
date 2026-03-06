-- Subscription plans and worker subscriptions

CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  duration_months INTEGER NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  features JSONB DEFAULT '[]',
  max_active_applications INTEGER NOT NULL DEFAULT 10,
  priority_listing BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id UUID NOT NULL UNIQUE REFERENCES profiles(id),
  plan_id UUID NOT NULL REFERENCES subscription_plans(id),

  status subscription_status NOT NULL DEFAULT 'active',

  starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  grace_expires_at TIMESTAMPTZ, -- expires_at + 3 days

  auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
  cancelled_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add foreign key from payments to subscriptions now that the table exists
ALTER TABLE payments
  ADD CONSTRAINT payments_subscription_id_fkey
  FOREIGN KEY (subscription_id) REFERENCES subscriptions(id);

CREATE TRIGGER subscription_plans_updated_at
  BEFORE UPDATE ON subscription_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
