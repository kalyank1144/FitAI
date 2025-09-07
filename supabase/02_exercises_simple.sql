-- Simple exercises table without storage bucket
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

-- RLS
alter table public.exercises enable row level security;

-- Policies
drop policy if exists "exercises_read_anon" on public.exercises;
create policy "exercises_read_anon" on public.exercises
for select to anon using (true);

drop policy if exists "exercises_write_auth" on public.exercises;
create policy "exercises_write_auth" on public.exercises
for all to authenticated using (true) with check (true);

-- Seed data
insert into public.exercises (name, primary_muscle, equipment, media_url)
values
  ('Barbell Back Squat','Quadriceps','Barbell','https://images.pexels.com/photos/314703/pexels-photo-314703.jpeg?auto=compress&cs=tinysrgb&w=640'),
  ('Push-up','Chest','Bodyweight','https://images.pexels.com/photos/4761792/pexels-photo-4761792.jpeg?auto=compress&cs=tinysrgb&w=640'),
  ('Dumbbell Row','Back','Dumbbells','https://images.pexels.com/photos/5327551/pexels-photo-5327551.jpeg?auto=compress&cs=tinysrgb&w=640')
ON CONFLICT DO NOTHING;