-- Enhanced training features migration

-- Add created_by column to exercises table for custom exercises
ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id);

-- Create exercise favorites table
CREATE TABLE IF NOT EXISTS public.exercise_favorites (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id uuid NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, exercise_id)
);

-- Enable RLS on exercise_favorites
ALTER TABLE public.exercise_favorites ENABLE ROW LEVEL SECURITY;

-- RLS policies for exercise_favorites
DROP POLICY IF EXISTS "exercise_favorites_read_own" ON public.exercise_favorites;
CREATE POLICY "exercise_favorites_read_own" ON public.exercise_favorites
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "exercise_favorites_write_own" ON public.exercise_favorites;
CREATE POLICY "exercise_favorites_write_own" ON public.exercise_favorites
  FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Update workout_sessions table with additional columns
ALTER TABLE public.workout_sessions ADD COLUMN IF NOT EXISTS notes text;
ALTER TABLE public.workout_sessions ADD COLUMN IF NOT EXISTS total_duration integer;
ALTER TABLE public.workout_sessions ADD COLUMN IF NOT EXISTS total_volume numeric;

-- Update workout_sets table with additional columns
ALTER TABLE public.workout_sets ADD COLUMN IF NOT EXISTS rest_time integer;
ALTER TABLE public.workout_sets ADD COLUMN IF NOT EXISTS is_completed boolean DEFAULT false;
ALTER TABLE public.workout_sets ADD COLUMN IF NOT EXISTS target_reps integer;
ALTER TABLE public.workout_sets ADD COLUMN IF NOT EXISTS target_weight numeric;
ALTER TABLE public.workout_sets ADD COLUMN IF NOT EXISTS completed_at timestamptz;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_exercise_favorites_user_id ON public.exercise_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_favorites_exercise_id ON public.exercise_favorites(exercise_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_id ON public.workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_status ON public.workout_sessions(status);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_started_at ON public.workout_sessions(started_at);
CREATE INDEX IF NOT EXISTS idx_workout_sets_session_id ON public.workout_sets(session_id);
CREATE INDEX IF NOT EXISTS idx_workout_sets_exercise_id ON public.workout_sets(exercise_id);
CREATE INDEX IF NOT EXISTS idx_workout_sets_completed_at ON public.workout_sets(completed_at);
CREATE INDEX IF NOT EXISTS idx_exercises_name ON public.exercises(name);
CREATE INDEX IF NOT EXISTS idx_exercises_primary_muscle ON public.exercises(primary_muscle);
CREATE INDEX IF NOT EXISTS idx_exercises_equipment ON public.exercises(equipment);
CREATE INDEX IF NOT EXISTS idx_exercises_created_by ON public.exercises(created_by);

-- Create function to calculate workout session totals
CREATE OR REPLACE FUNCTION calculate_workout_totals(session_id uuid)
RETURNS TABLE(total_volume numeric, total_duration integer) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM((weight_kg * reps)), 0) as total_volume,
    EXTRACT(EPOCH FROM (MAX(completed_at) - MIN(ws.started_at)))::integer as total_duration
  FROM public.workout_sets wset
  JOIN public.workout_sessions ws ON ws.id = wset.session_id
  WHERE wset.session_id = calculate_workout_totals.session_id
    AND wset.is_completed = true;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update workout session totals when sets are completed
CREATE OR REPLACE FUNCTION update_workout_session_totals()
RETURNS TRIGGER AS $$
DECLARE
  session_totals RECORD;
BEGIN
  -- Only update if the set was just completed
  IF NEW.is_completed = true AND (OLD.is_completed IS NULL OR OLD.is_completed = false) THEN
    SELECT * INTO session_totals FROM calculate_workout_totals(NEW.session_id);
    
    UPDATE public.workout_sessions
    SET 
      total_volume = session_totals.total_volume,
      total_duration = session_totals.total_duration
    WHERE id = NEW.session_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trg_update_workout_totals ON public.workout_sets;
CREATE TRIGGER trg_update_workout_totals
  AFTER UPDATE ON public.workout_sets
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_session_totals();

-- Grant permissions
GRANT SELECT ON public.exercise_favorites TO anon, authenticated;
GRANT ALL PRIVILEGES ON public.exercise_favorites TO authenticated;
GRANT SELECT ON public.workout_sessions TO anon;
GRANT ALL PRIVILEGES ON public.workout_sessions TO authenticated;
GRANT SELECT ON public.workout_sets TO anon;
GRANT ALL PRIVILEGES ON public.workout_sets TO authenticated;
GRANT ALL PRIVILEGES ON public.exercises TO authenticated;