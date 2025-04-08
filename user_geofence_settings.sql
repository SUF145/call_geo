-- Create user_geofence_settings table
CREATE TABLE IF NOT EXISTS user_geofence_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  admin_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Admin who set up the geofence
  enabled BOOLEAN DEFAULT false,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius DOUBLE PRECISION DEFAULT 500, -- Default radius in meters
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id) -- Each user can only have one geofence setting
);

-- Create RLS policies for user_geofence_settings
ALTER TABLE user_geofence_settings ENABLE ROW LEVEL SECURITY;

-- Users can view their own geofence settings
CREATE POLICY "Users can view their own geofence settings"
  ON user_geofence_settings FOR SELECT
  USING (auth.uid() = user_id);

-- Admins can view all geofence settings
CREATE POLICY "Admins can view all geofence settings"
  ON user_geofence_settings FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- Admins can insert geofence settings
CREATE POLICY "Admins can insert geofence settings"
  ON user_geofence_settings FOR INSERT
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- Admins can update geofence settings
CREATE POLICY "Admins can update geofence settings"
  ON user_geofence_settings FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- Admins can delete geofence settings
CREATE POLICY "Admins can delete geofence settings"
  ON user_geofence_settings FOR DELETE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
