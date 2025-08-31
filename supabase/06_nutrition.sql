-- Nutrition entries and daily totals view
create table if not exists public.nutrition_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  time timestamptz not null default now(),
  calories int,
  protein_g int,
  carbs_g int,
  fat_g int,
  source text,
  note text,
  barcode text,
  photo_url text
);

alter table public.nutrition_entries enable row level security;
DROP POLICY IF EXISTS ne_read_own ON public.nutrition_entries;
CREATE POLICY ne_read_own ON public.nutrition_entries FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS ne_write_own ON public.nutrition_entries;
CREATE POLICY ne_write_own ON public.nutrition_entries FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

create or replace view public.nutrition_daily_totals as
select user_id,
       (time at time zone 'UTC')::date as date,
       coalesce(sum(calories),0) as calories,
       coalesce(sum(protein_g),0) as protein_g,
       coalesce(sum(carbs_g),0) as carbs_g,
       coalesce(sum(fat_g),0) as fat_g
from public.nutrition_entries
group by 1,2;

grant select on public.nutrition_daily_totals to anon, authenticated;