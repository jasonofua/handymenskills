-- Row Level Security policies for all tables

-- Helper function to check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Helper function to get current user's role
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS user_role AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ===========================================
-- PROFILES
-- ===========================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read profiles"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ===========================================
-- CATEGORIES & SKILLS (public read)
-- ===========================================
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE skills ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read active categories"
  ON categories FOR SELECT
  USING (is_active = true);

CREATE POLICY "Anyone can read active skills"
  ON skills FOR SELECT
  USING (is_active = true);

-- ===========================================
-- WORKER PROFILES
-- ===========================================
ALTER TABLE worker_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read worker profiles"
  ON worker_profiles FOR SELECT
  USING (true);

CREATE POLICY "Workers can insert own profile"
  ON worker_profiles FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Workers can update own profile"
  ON worker_profiles FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Worker skills
ALTER TABLE worker_skills ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read worker skills"
  ON worker_skills FOR SELECT
  USING (true);

CREATE POLICY "Workers can manage own skills"
  ON worker_skills FOR INSERT
  WITH CHECK (
    worker_id IN (SELECT id FROM worker_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "Workers can update own skills"
  ON worker_skills FOR UPDATE
  USING (
    worker_id IN (SELECT id FROM worker_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "Workers can delete own skills"
  ON worker_skills FOR DELETE
  USING (
    worker_id IN (SELECT id FROM worker_profiles WHERE user_id = auth.uid())
  );

-- Worker schedule
ALTER TABLE worker_schedule ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read worker schedule"
  ON worker_schedule FOR SELECT
  USING (true);

CREATE POLICY "Workers can manage own schedule"
  ON worker_schedule FOR ALL
  USING (
    worker_id IN (SELECT id FROM worker_profiles WHERE user_id = auth.uid())
  );

-- ===========================================
-- JOBS
-- ===========================================
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read open jobs"
  ON jobs FOR SELECT
  USING (
    status = 'open'
    OR client_id = auth.uid()
    OR is_admin()
  );

CREATE POLICY "Clients can create jobs"
  ON jobs FOR INSERT
  WITH CHECK (client_id = auth.uid());

CREATE POLICY "Clients can update own jobs"
  ON jobs FOR UPDATE
  USING (client_id = auth.uid())
  WITH CHECK (client_id = auth.uid());

CREATE POLICY "Clients can delete own draft jobs"
  ON jobs FOR DELETE
  USING (client_id = auth.uid() AND status = 'draft');

-- ===========================================
-- APPLICATIONS
-- ===========================================
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Workers can read own applications"
  ON applications FOR SELECT
  USING (
    worker_id IN (SELECT id FROM worker_profiles WHERE user_id = auth.uid())
    OR job_id IN (SELECT id FROM jobs WHERE client_id = auth.uid())
    OR is_admin()
  );

CREATE POLICY "Workers can insert applications"
  ON applications FOR INSERT
  WITH CHECK (
    worker_id IN (SELECT id FROM worker_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "Workers can update own applications"
  ON applications FOR UPDATE
  USING (
    worker_id IN (SELECT id FROM worker_profiles WHERE user_id = auth.uid())
    OR job_id IN (SELECT id FROM jobs WHERE client_id = auth.uid())
  );

-- ===========================================
-- BOOKINGS
-- ===========================================
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can read own bookings"
  ON bookings FOR SELECT
  USING (
    client_id = auth.uid()
    OR worker_id = auth.uid()
    OR is_admin()
  );

CREATE POLICY "Clients can create bookings"
  ON bookings FOR INSERT
  WITH CHECK (client_id = auth.uid());

CREATE POLICY "Participants can update bookings"
  ON bookings FOR UPDATE
  USING (
    client_id = auth.uid()
    OR worker_id = auth.uid()
  );

-- ===========================================
-- REVIEWS
-- ===========================================
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read visible reviews"
  ON reviews FOR SELECT
  USING (is_visible = true OR reviewer_id = auth.uid() OR is_admin());

CREATE POLICY "Booking participants can create reviews"
  ON reviews FOR INSERT
  WITH CHECK (
    reviewer_id = auth.uid()
    AND booking_id IN (
      SELECT id FROM bookings
      WHERE (client_id = auth.uid() OR worker_id = auth.uid())
        AND status = 'client_confirmed'
        AND client_confirmed_at > NOW() - INTERVAL '7 days'
    )
  );

CREATE POLICY "Reviewees can add response"
  ON reviews FOR UPDATE
  USING (reviewee_id = auth.uid())
  WITH CHECK (reviewee_id = auth.uid());

-- ===========================================
-- CONVERSATIONS & MESSAGES
-- ===========================================
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can read own conversations"
  ON conversations FOR SELECT
  USING (
    participant_one = auth.uid()
    OR participant_two = auth.uid()
  );

CREATE POLICY "Authenticated users can create conversations"
  ON conversations FOR INSERT
  WITH CHECK (
    participant_one = auth.uid() OR participant_two = auth.uid()
  );

CREATE POLICY "Participants can update conversations"
  ON conversations FOR UPDATE
  USING (
    participant_one = auth.uid()
    OR participant_two = auth.uid()
  );

CREATE POLICY "Participants can read messages"
  ON messages FOR SELECT
  USING (
    conversation_id IN (
      SELECT id FROM conversations
      WHERE participant_one = auth.uid() OR participant_two = auth.uid()
    )
  );

CREATE POLICY "Participants can send messages"
  ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND conversation_id IN (
      SELECT id FROM conversations
      WHERE participant_one = auth.uid() OR participant_two = auth.uid()
    )
  );

CREATE POLICY "Senders can update own messages"
  ON messages FOR UPDATE
  USING (
    sender_id = auth.uid()
    OR conversation_id IN (
      SELECT id FROM conversations
      WHERE participant_one = auth.uid() OR participant_two = auth.uid()
    )
  );

-- ===========================================
-- NOTIFICATIONS
-- ===========================================
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid());

-- System inserts notifications (via triggers/functions using SECURITY DEFINER)
CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

-- ===========================================
-- PAYMENTS
-- ===========================================
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own payments"
  ON payments FOR SELECT
  USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "Users can insert own payments"
  ON payments FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ===========================================
-- PAYOUTS
-- ===========================================
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Workers can read own payouts"
  ON payouts FOR SELECT
  USING (worker_id = auth.uid() OR is_admin());

-- ===========================================
-- SUBSCRIPTIONS
-- ===========================================
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read active plans"
  ON subscription_plans FOR SELECT
  USING (is_active = true);

CREATE POLICY "Workers can read own subscription"
  ON subscriptions FOR SELECT
  USING (worker_id = auth.uid() OR is_admin());

CREATE POLICY "Workers can insert subscription"
  ON subscriptions FOR INSERT
  WITH CHECK (worker_id = auth.uid());

CREATE POLICY "Workers can update own subscription"
  ON subscriptions FOR UPDATE
  USING (worker_id = auth.uid());

-- ===========================================
-- REPORTS & DISPUTES
-- ===========================================
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own reports"
  ON reports FOR SELECT
  USING (reporter_id = auth.uid() OR reported_id = auth.uid() OR is_admin());

CREATE POLICY "Users can create reports"
  ON reports FOR INSERT
  WITH CHECK (reporter_id = auth.uid());

CREATE POLICY "Participants can read own disputes"
  ON disputes FOR SELECT
  USING (
    initiator_id = auth.uid()
    OR booking_id IN (
      SELECT id FROM bookings WHERE client_id = auth.uid() OR worker_id = auth.uid()
    )
    OR is_admin()
  );

CREATE POLICY "Booking participants can create disputes"
  ON disputes FOR INSERT
  WITH CHECK (
    initiator_id = auth.uid()
    AND booking_id IN (
      SELECT id FROM bookings WHERE client_id = auth.uid() OR worker_id = auth.uid()
    )
  );

-- ===========================================
-- SAVED WORKERS
-- ===========================================
ALTER TABLE saved_workers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own saved workers"
  ON saved_workers FOR SELECT
  USING (client_id = auth.uid());

CREATE POLICY "Users can save workers"
  ON saved_workers FOR INSERT
  WITH CHECK (client_id = auth.uid());

CREATE POLICY "Users can unsave workers"
  ON saved_workers FOR DELETE
  USING (client_id = auth.uid());

-- ===========================================
-- SYSTEM SETTINGS & AUDIT LOGS
-- ===========================================
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read system settings"
  ON system_settings FOR SELECT
  USING (true);

CREATE POLICY "Admins can read audit logs"
  ON audit_logs FOR SELECT
  USING (is_admin());
