-- Create a function to get device tokens by user ID (bypassing RLS)
CREATE OR REPLACE FUNCTION get_device_token_by_user_id(user_id_param UUID)
RETURNS SETOF device_tokens
LANGUAGE sql
SECURITY DEFINER -- This makes the function run with the privileges of the function creator
AS $$
  SELECT * FROM device_tokens WHERE user_id = user_id_param;
$$;
