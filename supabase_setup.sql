-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create RLS policies for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile" 
  ON profiles FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = id);

-- Create locations table
CREATE TABLE IF NOT EXISTS locations (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  accuracy DOUBLE PRECISION,
  altitude DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on user_id and timestamp for faster queries
CREATE INDEX IF NOT EXISTS locations_user_id_timestamp_idx ON locations (user_id, timestamp DESC);

-- Create RLS policies for locations
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own locations" 
  ON locations FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own locations" 
  ON locations FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own locations" 
  ON locations FOR DELETE 
  USING (auth.uid() = user_id);
