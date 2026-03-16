-- Migration: Switch from phone OTP to email/password auth

-- 1. Make phone nullable (drop NOT NULL if it exists), keep UNIQUE
ALTER TABLE profiles ALTER COLUMN phone DROP NOT NULL;

-- 2. Add UNIQUE constraint on email
ALTER TABLE profiles ADD CONSTRAINT profiles_email_unique UNIQUE (email);

-- 3. Update handle_new_user() to work with email-based signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.phone,
    NEW.email,
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'client')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;
