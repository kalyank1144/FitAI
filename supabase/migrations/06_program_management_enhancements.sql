-- Add created_by column to programs table for user-created programs (nullable for system programs)
ALTER TABLE programs ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Leave existing programs with NULL created_by (system programs)
-- User-created programs will have a valid user ID

-- Create index for better performance on user programs queries
CREATE INDEX IF NOT EXISTS idx_programs_created_by ON programs(created_by);
CREATE INDEX IF NOT EXISTS idx_programs_difficulty ON programs(difficulty);
CREATE INDEX IF NOT EXISTS idx_programs_featured ON programs(is_featured);

-- Update RLS policies for programs table
DROP POLICY IF EXISTS "Programs are viewable by everyone" ON programs;
DROP POLICY IF EXISTS "Users can insert their own programs" ON programs;
DROP POLICY IF EXISTS "Users can update their own programs" ON programs;
DROP POLICY IF EXISTS "Users can delete their own programs" ON programs;

-- New RLS policies
CREATE POLICY "Programs are viewable by everyone" ON programs
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own programs" ON programs
    FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their own programs" ON programs
    FOR UPDATE USING (auth.uid() = created_by OR created_by IS NULL)
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can delete their own programs" ON programs
    FOR DELETE USING (auth.uid() = created_by);

-- Create program templates table for pre-built program templates
CREATE TABLE IF NOT EXISTS program_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    difficulty TEXT NOT NULL CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    cover_url TEXT,
    category TEXT NOT NULL DEFAULT 'general',
    duration_weeks INTEGER DEFAULT 4,
    sessions_per_week INTEGER DEFAULT 3,
    equipment_needed TEXT[] DEFAULT '{}',
    target_goals TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on program_templates
ALTER TABLE program_templates ENABLE ROW LEVEL SECURITY;

-- RLS policies for program_templates (read-only for all users)
CREATE POLICY "Program templates are viewable by everyone" ON program_templates
    FOR SELECT USING (true);

-- Create program_template_exercises junction table
CREATE TABLE IF NOT EXISTS program_template_exercises (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    template_id UUID NOT NULL REFERENCES program_templates(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL DEFAULT 1,
    order_index INTEGER NOT NULL DEFAULT 0,
    sets INTEGER DEFAULT 3,
    reps_min INTEGER DEFAULT 8,
    reps_max INTEGER DEFAULT 12,
    rest_seconds INTEGER DEFAULT 60,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(template_id, exercise_id, day_number)
);

-- Enable RLS on program_template_exercises
ALTER TABLE program_template_exercises ENABLE ROW LEVEL SECURITY;

-- RLS policies for program_template_exercises
CREATE POLICY "Program template exercises are viewable by everyone" ON program_template_exercises
    FOR SELECT USING (true);

-- Create indexes for program templates
CREATE INDEX IF NOT EXISTS idx_program_templates_category ON program_templates(category);
CREATE INDEX IF NOT EXISTS idx_program_templates_difficulty ON program_templates(difficulty);
CREATE INDEX IF NOT EXISTS idx_program_template_exercises_template ON program_template_exercises(template_id);
CREATE INDEX IF NOT EXISTS idx_program_template_exercises_day ON program_template_exercises(template_id, day_number);

-- Create updated_at trigger for program_templates
CREATE OR REPLACE FUNCTION update_program_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_program_templates_updated_at
    BEFORE UPDATE ON program_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_program_templates_updated_at();

-- Insert sample program templates
INSERT INTO program_templates (name, description, difficulty, category, duration_weeks, sessions_per_week, equipment_needed, target_goals) VALUES
('Beginner Full Body', 'A comprehensive full-body workout program perfect for beginners starting their fitness journey.', 'beginner', 'strength', 4, 3, '{"dumbbells", "bench"}', '{"strength", "muscle_building"}'),
('Push Pull Legs', 'Classic 6-day split focusing on push movements, pull movements, and leg exercises.', 'intermediate', 'strength', 6, 6, '{"barbell", "dumbbells", "pull_up_bar"}', '{"strength", "muscle_building", "power"}'),
('HIIT Cardio Blast', 'High-intensity interval training program for maximum calorie burn and cardiovascular fitness.', 'intermediate', 'cardio', 4, 4, '{"none"}', '{"weight_loss", "endurance", "conditioning"}'),
('Powerlifting Basics', 'Focus on the big three: squat, bench press, and deadlift with accessory work.', 'advanced', 'powerlifting', 8, 4, '{"barbell", "squat_rack", "bench"}', '{"strength", "power", "competition"}');

-- Grant permissions to authenticated users
GRANT SELECT ON program_templates TO authenticated;
GRANT SELECT ON program_template_exercises TO authenticated;
GRANT ALL ON programs TO authenticated;
GRANT ALL ON program_exercises TO authenticated;

-- Grant permissions to anon users for read access
GRANT SELECT ON program_templates TO anon;
GRANT SELECT ON program_template_exercises TO anon;
GRANT SELECT ON programs TO anon;
GRANT SELECT ON program_exercises TO anon;