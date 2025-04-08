-- Create the user_geofence_settings table
CREATE TABLE IF NOT EXISTS public.user_geofence_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    enabled BOOLEAN NOT NULL DEFAULT false,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius DOUBLE PRECISION NOT NULL DEFAULT 500,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_geofence_settings_user_id ON public.user_geofence_settings(user_id);

-- Add RLS (Row Level Security) policies
ALTER TABLE public.user_geofence_settings ENABLE ROW LEVEL SECURITY;

-- Policy for admins to manage all geofence settings
CREATE POLICY admin_manage_geofence_settings ON public.user_geofence_settings
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- Policy for users to read their own geofence settings
CREATE POLICY user_read_own_geofence_settings ON public.user_geofence_settings
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Grant permissions
GRANT ALL ON public.user_geofence_settings TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.user_geofence_settings_id_seq TO authenticated;
