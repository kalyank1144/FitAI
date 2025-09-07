-- Grant permissions for nutrition_entries table
GRANT SELECT ON nutrition_entries TO anon;
GRANT ALL PRIVILEGES ON nutrition_entries TO authenticated;

-- Also grant permissions for other tables that might have similar issues
GRANT SELECT ON activity_daily TO anon;
GRANT ALL PRIVILEGES ON activity_daily TO authenticated;

GRANT SELECT ON gps_sessions TO anon;
GRANT ALL PRIVILEGES ON gps_sessions TO authenticated;

GRANT SELECT ON profiles TO anon;
GRANT ALL PRIVILEGES ON profiles TO authenticated;

GRANT SELECT ON programs TO anon;
GRANT ALL PRIVILEGES ON programs TO authenticated;

GRANT SELECT ON exercises TO anon;
GRANT ALL PRIVILEGES ON exercises TO authenticated;

GRANT SELECT ON fcm_tokens TO anon;
GRANT ALL PRIVILEGES ON fcm_tokens TO authenticated;

GRANT SELECT ON reminders TO anon;
GRANT ALL PRIVILEGES ON reminders TO authenticated;

GRANT SELECT ON workout_sessions TO anon;
GRANT ALL PRIVILEGES ON workout_sessions TO authenticated;

GRANT SELECT ON workout_sets TO anon;
GRANT ALL PRIVILEGES ON workout_sets TO authenticated;

GRANT SELECT ON program_exercises TO anon;
GRANT ALL PRIVILEGES ON program_exercises TO authenticated;