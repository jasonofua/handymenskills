-- Enable Supabase Realtime for specific tables

-- Messages: Real-time chat
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Notifications: Real-time notification delivery
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- Bookings: Live status updates
ALTER PUBLICATION supabase_realtime ADD TABLE bookings;

-- Conversations: Conversation list updates (new message, last_message_at change)
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;

-- Worker profiles: Availability status changes
ALTER PUBLICATION supabase_realtime ADD TABLE worker_profiles;
