-- Performance indexes

-- Spatial indexes (GIST)
CREATE INDEX idx_profiles_location ON profiles USING GIST (location);
CREATE INDEX idx_worker_profiles_location ON worker_profiles USING GIST (location);
CREATE INDEX idx_jobs_location ON jobs USING GIST (location);

-- Profiles
CREATE INDEX idx_profiles_role_status ON profiles (role, account_status);
CREATE INDEX idx_profiles_city_state ON profiles (city, state);
CREATE INDEX idx_profiles_phone ON profiles (phone);

-- Worker profiles
CREATE INDEX idx_worker_profiles_user_id ON worker_profiles (user_id);
CREATE INDEX idx_worker_profiles_available ON worker_profiles (is_available, verification_status) WHERE is_available = true;
CREATE INDEX idx_worker_profiles_rating ON worker_profiles (average_rating DESC);

-- Worker skills
CREATE INDEX idx_worker_skills_worker_id ON worker_skills (worker_id);
CREATE INDEX idx_worker_skills_skill_id ON worker_skills (skill_id);

-- Skills
CREATE INDEX idx_skills_category_id ON skills (category_id);

-- Jobs
CREATE INDEX idx_jobs_client_id ON jobs (client_id);
CREATE INDEX idx_jobs_status ON jobs (status);
CREATE INDEX idx_jobs_category_id ON jobs (category_id);
CREATE INDEX idx_jobs_status_urgency ON jobs (status, urgency);
CREATE INDEX idx_jobs_expires_at ON jobs (expires_at) WHERE status = 'open';
CREATE INDEX idx_jobs_city_state ON jobs (city, state);

-- Text search (trigram)
CREATE INDEX idx_jobs_title_trgm ON jobs USING GIN (title gin_trgm_ops);
CREATE INDEX idx_jobs_description_trgm ON jobs USING GIN (description gin_trgm_ops);

-- Applications
CREATE INDEX idx_applications_job_id ON applications (job_id);
CREATE INDEX idx_applications_worker_id ON applications (worker_id);
CREATE INDEX idx_applications_job_status ON applications (job_id, status);
CREATE INDEX idx_applications_worker_status ON applications (worker_id, status);

-- Bookings
CREATE INDEX idx_bookings_client_id ON bookings (client_id);
CREATE INDEX idx_bookings_worker_id ON bookings (worker_id);
CREATE INDEX idx_bookings_status ON bookings (status);
CREATE INDEX idx_bookings_job_id ON bookings (job_id);

-- Reviews
CREATE INDEX idx_reviews_reviewee_id ON reviews (reviewee_id);
CREATE INDEX idx_reviews_reviewer_id ON reviews (reviewer_id);
CREATE INDEX idx_reviews_booking_id ON reviews (booking_id);

-- Conversations & Messages
CREATE INDEX idx_conversations_participant_one ON conversations (participant_one);
CREATE INDEX idx_conversations_participant_two ON conversations (participant_two);
CREATE INDEX idx_conversations_last_message_at ON conversations (last_message_at DESC);
CREATE INDEX idx_messages_conversation_id ON messages (conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender_id ON messages (sender_id);

-- Notifications
CREATE INDEX idx_notifications_user_id_unread ON notifications (user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_user_id_created ON notifications (user_id, created_at DESC);

-- Payments
CREATE INDEX idx_payments_user_id ON payments (user_id);
CREATE INDEX idx_payments_booking_id ON payments (booking_id);
CREATE INDEX idx_payments_subscription_id ON payments (subscription_id);
CREATE INDEX idx_payments_reference ON payments (paystack_reference);
CREATE INDEX idx_payments_status_type ON payments (status, payment_type);

-- Payouts
CREATE INDEX idx_payouts_worker_id ON payouts (worker_id);
CREATE INDEX idx_payouts_status ON payouts (status);

-- Subscriptions
CREATE INDEX idx_subscriptions_worker_id ON subscriptions (worker_id);
CREATE INDEX idx_subscriptions_status ON subscriptions (status);
CREATE INDEX idx_subscriptions_expires_at ON subscriptions (expires_at);

-- Reports
CREATE INDEX idx_reports_status ON reports (status);
CREATE INDEX idx_reports_reporter_id ON reports (reporter_id);

-- Disputes
CREATE INDEX idx_disputes_status ON disputes (status);
CREATE INDEX idx_disputes_booking_id ON disputes (booking_id);

-- Saved workers
CREATE INDEX idx_saved_workers_client_id ON saved_workers (client_id);

-- Audit logs
CREATE INDEX idx_audit_logs_user_id ON audit_logs (user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs (entity, entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs (created_at DESC);
