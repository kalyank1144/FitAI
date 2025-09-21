-- Add missing food_name column to nutrition_entries table
ALTER TABLE public.nutrition_entries 
ADD COLUMN IF NOT EXISTS food_name text;

-- Update the nutrition_daily_totals view to be more robust
CREATE OR REPLACE VIEW public.nutrition_daily_totals AS
SELECT user_id,
       (time AT TIME ZONE 'UTC')::date AS date,
       COALESCE(SUM(calories), 0) AS calories,
       COALESCE(SUM(protein_g), 0) AS protein_g,
       COALESCE(SUM(carbs_g), 0) AS carbs_g,
       COALESCE(SUM(fat_g), 0) AS fat_g
FROM public.nutrition_entries
GROUP BY 1, 2;

-- Ensure proper permissions
GRANT SELECT ON public.nutrition_daily_totals TO anon, authenticated;
GRANT ALL PRIVILEGES ON public.nutrition_entries TO authenticated;
GRANT SELECT ON public.nutrition_entries TO anon;