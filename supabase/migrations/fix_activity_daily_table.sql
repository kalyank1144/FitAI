-- Add missing active_minutes column to activity_daily table
ALTER TABLE public.activity_daily 
ADD COLUMN IF NOT EXISTS active_minutes integer DEFAULT 0;

-- Insert sample activity data for today (for testing purposes)
-- This will only insert if no data exists for today
INSERT INTO public.activity_daily (user_id, date, steps, calories, avg_hr, active_minutes)
SELECT 
    auth.uid() as user_id,
    CURRENT_DATE as date,
    8547 as steps,
    320 as calories,
    72 as avg_hr,
    45 as active_minutes
WHERE auth.uid() IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.activity_daily 
    WHERE user_id = auth.uid() AND date = CURRENT_DATE
  );

-- Ensure proper permissions
GRANT ALL PRIVILEGES ON public.activity_daily TO authenticated;
GRANT SELECT ON public.activity_daily TO anon;