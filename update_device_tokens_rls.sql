-- Update RLS policies for device_tokens table

-- First, drop existing policies
DROP POLICY IF EXISTS "Users can insert their own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can update their own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can delete their own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can view their own device tokens" ON device_tokens;
DROP POLICY IF EXISTS "Admins can view all device tokens" ON device_tokens;

-- Create new policies
-- Allow users to insert their own device tokens
CREATE POLICY "Users can insert their own device tokens"
  ON device_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own device tokens
CREATE POLICY "Users can update their own device tokens"
  ON device_tokens FOR UPDATE
  USING (auth.uid() = user_id);

-- Allow users to delete their own device tokens
CREATE POLICY "Users can delete their own device tokens"
  ON device_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- Allow users to view their own device tokens
CREATE POLICY "Users can view their own device tokens"
  ON device_tokens FOR SELECT
  USING (auth.uid() = user_id);

-- Allow admins to view all device tokens
CREATE POLICY "Admins can view all device tokens"
  ON device_tokens FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Allow admins to update all device tokens
CREATE POLICY "Admins can update all device tokens"
  ON device_tokens FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Allow admins to delete all device tokens
CREATE POLICY "Admins can delete all device tokens"
  ON device_tokens FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
