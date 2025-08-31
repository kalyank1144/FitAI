-- User reminders and FCM tokens
create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null default 'workout',
  time_local time not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.reminders enable row level security;
DROP POLICY IF EXISTS reminders_read_own ON public.reminders;
CREATE POLICY reminders_read_own ON public.reminders FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS reminders_write_own ON public.reminders;
CREATE POLICY reminders_write_own ON public.reminders FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

create table if not exists public.fcm_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text,
  created_at timestamptz not null default now()
);

alter table public.fcm_tokens enable row level security;
DROP POLICY IF EXISTS fcm_read_own ON public.fcm_tokens;
CREATE POLICY fcm_read_own ON public.fcm_tokens FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS fcm_write_own ON public.fcm_tokens;
CREATE POLICY fcm_write_own ON public.fcm_tokens FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
