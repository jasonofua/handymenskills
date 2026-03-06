-- All application enums

CREATE TYPE user_role AS ENUM ('client', 'worker', 'admin');
CREATE TYPE account_status AS ENUM ('active', 'suspended', 'banned', 'deactivated');
CREATE TYPE verification_status AS ENUM ('unverified', 'pending', 'verified', 'rejected');

CREATE TYPE job_status AS ENUM ('draft', 'open', 'assigned', 'in_progress', 'completed', 'cancelled', 'expired');
CREATE TYPE urgency_level AS ENUM ('low', 'medium', 'high', 'emergency');
CREATE TYPE budget_type AS ENUM ('fixed', 'hourly', 'negotiable');

CREATE TYPE application_status AS ENUM ('pending', 'shortlisted', 'accepted', 'rejected', 'withdrawn');

CREATE TYPE booking_status AS ENUM (
  'pending',
  'confirmed',
  'worker_en_route',
  'in_progress',
  'completed',
  'client_confirmed',
  'cancelled',
  'disputed'
);

CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'success', 'failed', 'refunded');
CREATE TYPE payment_type AS ENUM ('subscription_payment', 'booking_payment', 'booking_deposit');
CREATE TYPE payment_method AS ENUM ('card', 'bank_transfer', 'ussd', 'mobile_money');

CREATE TYPE payout_status AS ENUM ('pending', 'processing', 'success', 'failed');

CREATE TYPE subscription_status AS ENUM ('active', 'expired', 'grace_period', 'cancelled');

CREATE TYPE notification_type AS ENUM (
  'job_application',
  'application_accepted',
  'application_rejected',
  'booking_created',
  'booking_confirmed',
  'booking_started',
  'booking_completed',
  'booking_cancelled',
  'booking_disputed',
  'payment_received',
  'payment_sent',
  'payout_processed',
  'new_message',
  'new_review',
  'subscription_expiring',
  'subscription_expired',
  'subscription_activated',
  'worker_verified',
  'worker_rejected',
  'account_suspended',
  'system_announcement'
);

CREATE TYPE report_reason AS ENUM (
  'spam',
  'inappropriate_content',
  'fraud',
  'harassment',
  'fake_profile',
  'poor_service',
  'no_show',
  'other'
);
CREATE TYPE report_status AS ENUM ('pending', 'reviewing', 'resolved', 'dismissed');

CREATE TYPE dispute_status AS ENUM (
  'open',
  'under_review',
  'resolved_client_favor',
  'resolved_worker_favor',
  'resolved_mutual',
  'closed'
);

CREATE TYPE message_type AS ENUM ('text', 'image', 'file', 'location', 'system');

CREATE TYPE proficiency_level AS ENUM ('beginner', 'intermediate', 'professional');
