-- Public buckets for media used in the app
select storage.create_bucket('exercise-media', public := true);
select storage.create_bucket('meal-photos', public := true);

-- Public read for both buckets
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE polname = 'exercise_media_public_read') THEN
    CREATE POLICY exercise_media_public_read ON storage.objects FOR SELECT TO anon USING (bucket_id = 'exercise-media');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE polname = 'meal_photos_public_read') THEN
    CREATE POLICY meal_photos_public_read ON storage.objects FOR SELECT TO anon USING (bucket_id = 'meal-photos');
  END IF;
END $$;

-- Authenticated users can manage their uploads in both buckets
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE polname = 'exercise_media_auth_crud') THEN
    CREATE POLICY exercise_media_auth_crud ON storage.objects FOR ALL TO authenticated USING (bucket_id = 'exercise-media') WITH CHECK (bucket_id = 'exercise-media');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE polname = 'meal_photos_auth_crud') THEN
    CREATE POLICY meal_photos_auth_crud ON storage.objects FOR ALL TO authenticated USING (bucket_id = 'meal-photos') WITH CHECK (bucket_id = 'meal-photos');
  END IF;
END $$;