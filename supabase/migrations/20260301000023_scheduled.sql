-- Database scheduled jobs using pg_cron
-- These run SQL functions on a recurring schedule inside PostgreSQL

-- Expire old open jobs every hour
SELECT cron.schedule('expire-old-jobs', '0 * * * *', $$SELECT expire_old_jobs()$$);

-- Check expiring subscriptions every hour
SELECT cron.schedule('check-expiring-subs', '30 * * * *', $$SELECT check_expiring_subscriptions()$$);

-- Process expired subscriptions daily at midnight
SELECT cron.schedule('process-expired-subs', '0 0 * * *', $$SELECT process_expired_subscriptions()$$);

-- Clean up old read notifications weekly on Sunday at 3 AM
SELECT cron.schedule('cleanup-notifications', '0 3 * * 0', $$DELETE FROM notifications WHERE is_read = true AND created_at < NOW() - INTERVAL '90 days'$$);
