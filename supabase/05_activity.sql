-- Daily activity and GPS sessions
create table if not exists public.activity_daily (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  steps int,
  resting_hr int,
  avg_hr int,
  calories int,
  sleep_min int,
  created_at timestamptz not null default now(),
  unique(user_id, date)
);

create table if not exists public.gps_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  distance_m numeric,
  duration_s int,
  path_geojson jsonb
);

alter table public.activity_daily enable row level security;
alter table public.gps_sessions enable row level security;

DROP POLICY IF EXISTS ad_read_own ON public.activity_daily;
CREATE POLICY ad_read_own ON public.activity_daily FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS ad_write_own ON public.activity_daily;
CREATE POLICY ad_write_own ON public.activity_daily FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS gps_read_own ON public.gps_sessions;
CREATE POLICY gps_read_own ON public.gps_sessions FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS gps_write_own ON public.gps_sessions;
CREATE POLICY gps_write_own ON public.gps_sessions FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
