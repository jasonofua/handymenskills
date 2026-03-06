-- Storage buckets and policies

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('portfolio', 'portfolio', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('job-images', 'job-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('id-documents', 'id-documents', false, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
  ('chat-attachments', 'chat-attachments', false, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('completion-photos', 'completion-photos', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']);

-- ===========================================
-- AVATARS (public read, owner write)
-- ===========================================
CREATE POLICY "Anyone can view avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ===========================================
-- PORTFOLIO (public read, owner write)
-- ===========================================
CREATE POLICY "Anyone can view portfolio"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'portfolio');

CREATE POLICY "Users can upload portfolio"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'portfolio'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete portfolio"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'portfolio'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ===========================================
-- JOB IMAGES (public read, job owner write)
-- ===========================================
CREATE POLICY "Anyone can view job images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'job-images');

CREATE POLICY "Users can upload job images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'job-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete job images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'job-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ===========================================
-- ID DOCUMENTS (private, owner write, admin read)
-- ===========================================
CREATE POLICY "Owners and admins can view ID documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'id-documents'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR is_admin()
    )
  );

CREATE POLICY "Users can upload ID documents"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'id-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ===========================================
-- CHAT ATTACHMENTS (conversation participants only)
-- ===========================================
CREATE POLICY "Conversation participants can view attachments"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'chat-attachments'
    AND EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id::text = (storage.foldername(name))[1]
        AND (c.participant_one = auth.uid() OR c.participant_two = auth.uid())
    )
  );

CREATE POLICY "Users can upload chat attachments"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'chat-attachments'
    AND EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id::text = (storage.foldername(name))[1]
        AND (c.participant_one = auth.uid() OR c.participant_two = auth.uid())
    )
  );

-- ===========================================
-- COMPLETION PHOTOS (public read, booking worker write)
-- ===========================================
CREATE POLICY "Anyone can view completion photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'completion-photos');

CREATE POLICY "Users can upload completion photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'completion-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
