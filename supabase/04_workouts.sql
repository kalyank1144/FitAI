-- Workout sessions and sets
create table if not exists public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  program_id uuid references public.programs(id),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  status text default 'in_progress',
  created_at timestamptz not null default now()
);

create table if not exists public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete restrict,
  position int not null,
  reps int,
  weight_kg numeric,
  rpe numeric,
  notes text
);

alter table public.workout_sessions enable row level security;
alter table public.workout_sets enable row level security;

-- RLS: user owns their sessions/sets
DROP POLICY IF EXISTS ws_read_own ON public.workout_sessions;
CREATE POLICY ws_read_own ON public.workout_sessions FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS ws_write_own ON public.workout_sessions;
CREATE POLICY ws_write_own ON public.workout_sessions FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS wsets_read_own ON public.workout_sets;
CREATE POLICY wsets_read_own ON public.workout_sets FOR SELECT TO authenticated USING (
  exists(select 1 from public.workout_sessions s where s.id = workout_sets.session_id and s.user_id = auth.uid())
);
DROP POLICY IF EXISTS wsets_write_own ON public.workout_sets;
CREATE POLICY wsets_write_own ON public.workout_sets FOR ALL TO authenticated USING (
  exists(select 1 from public.workout_sessions s where s.id = workout_sets.session_id and s.user_id = auth.uid())
) WITH CHECK (
  exists(select 1 from public.workout_sessions s where s.id = workout_sets.session_id and s.user_id = auth.uid())
);
