-- Programs and mapping to exercises
create table if not exists public.programs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  difficulty text,
  cover_url text,
  is_featured boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.program_exercises (
  program_id uuid references public.programs(id) on delete cascade,
  exercise_id uuid references public.exercises(id) on delete restrict,
  position int not null,
  sets int,
  reps int,
  primary key(program_id, exercise_id)
);

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_programs') THEN
    CREATE TRIGGER trg_set_updated_at_programs BEFORE UPDATE ON public.programs
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

alter table public.programs enable row level security;
alter table public.program_exercises enable row level security;

-- RLS: read for anon (public showcase), write for authenticated
DROP POLICY IF EXISTS programs_read_anon ON public.programs;
CREATE POLICY programs_read_anon ON public.programs FOR SELECT TO anon USING (true);
DROP POLICY IF EXISTS programs_write_auth ON public.programs;
CREATE POLICY programs_write_auth ON public.programs FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS program_ex_read_anon ON public.program_exercises;
CREATE POLICY program_ex_read_anon ON public.program_exercises FOR SELECT TO anon USING (true);
DROP POLICY IF EXISTS program_ex_write_auth ON public.program_exercises;
CREATE POLICY program_ex_write_auth ON public.program_exercises FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Seed examples (optional)
insert into public.programs (name, description, difficulty, cover_url, is_featured)
values
  ('Hypertrophy Base','4-week base building','Intermediate','https://images.pexels.com/photos/4162450/pexels-photo-4162450.jpeg?auto=compress&cs=tinysrgb&w=640', true),
  ('Strength 5x5','Classic linear progression','Beginner','https://images.pexels.com/photos/841130/pexels-photo-841130.jpeg?auto=compress&cs=tinysrgb&w=640', true)
ON CONFLICT DO NOTHING;