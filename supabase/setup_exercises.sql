-- FitAI: exercises table + RLS + storage bucket (run in Supabase SQL editor)
-- SAFE: requires elevated privileges; DO NOT expose service role key in the app.

-- UUID support
create extension if not exists "pgcrypto";

-- Table
create table if not exists public.exercises (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  primary_muscle text,
  equipment text,
  media_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- updated_at trigger
create or replace function public.set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_exercises'
  ) THEN
    CREATE TRIGGER trg_set_updated_at_exercises
    BEFORE UPDATE ON public.exercises
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- Realtime (Supabase Realtime reads primary key automatically)
alter table public.exercises enable row level security;

-- Policies
drop policy if exists "exercises_read_anon" on public.exercises;
create policy "exercises_read_anon" on public.exercises
for select to anon using (true);

drop policy if exists "exercises_write_auth" on public.exercises;
create policy "exercises_write_auth" on public.exercises
for all to authenticated using (true) with check (true);

-- Public storage bucket for exercise images
-- If the bucket already exists, this will no-op.
select storage.create_bucket('exercise-media', public := true);

-- Storage RLS (applies to storage.objects)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE polname = 'exercise_media_public_read'
  ) THEN
    CREATE POLICY exercise_media_public_read
    ON storage.objects
    FOR SELECT
    TO anon
    USING (bucket_id = 'exercise-media');
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE polname = 'exercise_media_auth_crud'
  ) THEN
    CREATE POLICY exercise_media_auth_crud
    ON storage.objects
    FOR ALL
    TO authenticated
    USING (bucket_id = 'exercise-media')
    WITH CHECK (bucket_id = 'exercise-media');
  END IF;
END $$;

-- Optional: seed a few rows (replace media_url with your own)
insert into public.exercises (name, primary_muscle, equipment, media_url)
values
  ('Barbell Back Squat','Quadriceps','Barbell','https://images.pexels.com/photos/314703/pexels-photo-314703.jpeg?auto=compress&cs=tinysrgb&w=640'),
  ('Push-up','Chest','Bodyweight','https://images.pexels.com/photos/4761792/pexels-photo-4761792.jpeg?auto=compress&cs=tinysrgb&w=640'),
  ('Dumbbell Row','Back','Dumbbells','https://images.pexels.com/photos/5327551/pexels-photo-5327551.jpeg?auto=compress&cs=tinysrgb&w=640')
ON CONFLICT DO NOTHING;