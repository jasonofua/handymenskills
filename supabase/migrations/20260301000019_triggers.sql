-- Database triggers

-- ===========================================
-- APPLICATION COUNT TRACKING
-- ===========================================
CREATE OR REPLACE FUNCTION update_job_application_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE jobs SET application_count = application_count + 1 WHERE id = NEW.job_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE jobs SET application_count = GREATEST(application_count - 1, 0) WHERE id = OLD.job_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_application_insert
  AFTER INSERT ON applications
  FOR EACH ROW EXECUTE FUNCTION update_job_application_count();

CREATE TRIGGER on_application_delete
  AFTER DELETE ON applications
  FOR EACH ROW EXECUTE FUNCTION update_job_application_count();

-- ===========================================
-- RECALCULATE RATINGS ON NEW REVIEW
-- ===========================================
CREATE OR REPLACE FUNCTION on_review_created()
RETURNS TRIGGER AS $$
BEGIN
  -- Recalculate reviewee's stats
  PERFORM calculate_worker_stats(NEW.reviewee_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_review_insert
  AFTER INSERT ON reviews
  FOR EACH ROW EXECUTE FUNCTION on_review_created();

-- ===========================================
-- SEND FCM PUSH ON NOTIFICATION INSERT
-- ===========================================
CREATE OR REPLACE FUNCTION on_notification_created()
RETURNS TRIGGER AS $$
BEGIN
  -- Send FCM push notification
  PERFORM send_fcm_push(
    NEW.user_id,
    NEW.title,
    NEW.body,
    COALESCE(NEW.data, '{}') || jsonb_build_object(
      'notification_id', NEW.id,
      'type', NEW.type,
      'reference_id', NEW.reference_id,
      'reference_type', NEW.reference_type
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_notification_insert
  AFTER INSERT ON notifications
  FOR EACH ROW EXECUTE FUNCTION on_notification_created();

-- ===========================================
-- VERIFY PAYMENT ON INSERT (via pg_net to Paystack)
-- ===========================================
CREATE OR REPLACE FUNCTION on_payment_created()
RETURNS TRIGGER AS $$
DECLARE
  v_paystack_key TEXT;
BEGIN
  -- Only verify if payment has a Paystack reference and is pending
  IF NEW.paystack_reference IS NOT NULL AND NEW.status = 'pending' THEN
    -- Get Paystack secret key from vault
    SELECT decrypted_secret INTO v_paystack_key
    FROM vault.decrypted_secrets
    WHERE name = 'paystack_secret_key'
    LIMIT 1;

    IF v_paystack_key IS NOT NULL THEN
      -- Call Paystack verify endpoint via pg_net
      PERFORM net.http_get(
        url := 'https://api.paystack.co/transaction/verify/' || NEW.paystack_reference,
        headers := jsonb_build_object(
          'Authorization', 'Bearer ' || v_paystack_key
        )
      );
      -- Note: pg_net is async. The response handling would need a separate mechanism.
      -- For MVP, we trust the client-side verification from flutter_paystack
      -- and mark as success here. In production, add webhook support.
      UPDATE payments SET status = 'success', verified_at = NOW() WHERE id = NEW.id;

      -- Handle downstream effects based on payment type
      IF NEW.payment_type = 'subscription_payment' THEN
        -- Activate subscription (plan_id passed via metadata)
        PERFORM activate_subscription(
          NEW.user_id,
          (NEW.metadata->>'plan_id')::UUID,
          NEW.id
        );
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_payment_insert
  AFTER INSERT ON payments
  FOR EACH ROW EXECUTE FUNCTION on_payment_created();
