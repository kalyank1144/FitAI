-- Fix RLS policies for nutrition_entries table
-- Allow authenticated users to access their own nutrition entries

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own nutrition entries" ON nutrition_entries;
DROP POLICY IF EXISTS "Users can insert own nutrition entries" ON nutrition_entries;
DROP POLICY IF EXISTS "Users can update own nutrition entries" ON nutrition_entries;
DROP POLICY IF EXISTS "Users can delete own nutrition entries" ON nutrition_entries;

-- Create policies for nutrition_entries
CREATE POLICY "Users can view own nutrition entries" ON nutrition_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own nutrition entries" ON nutrition_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own nutrition entries" ON nutrition_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own nutrition entries" ON nutrition_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions to authenticated users
GRANT ALL PRIVILEGES ON nutrition_entries TO authenticated;
GRANT SELECT ON nutrition_entries TO anon;