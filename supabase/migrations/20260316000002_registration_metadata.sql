-- Update handle_new_user() to extract additional fields from user metadata
-- This allows the registration form to pass phone, address, city, state, lga
-- via metadata, which gets populated into the profile on signup.

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone, email, role, address, city, state)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', NEW.phone),
    NEW.email,
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'client'),
    NEW.raw_user_meta_data->>'address',
    NEW.raw_user_meta_data->>'city',
    NEW.raw_user_meta_data->>'state'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;
