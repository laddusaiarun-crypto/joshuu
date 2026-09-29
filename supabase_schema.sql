-- FUEL GO Database Schema & RLS Policies for Supabase PostgreSQL
create extension if not exists "uuid-ossp";

-- 1. Profiles Table
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text not null,
  vehicle_type text,
  preferred_fuel_type text,
  role text default 'driver', -- 'driver', 'operator', 'admin'
  tank_capacity numeric default 45,
  avg_mileage numeric default 15,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Stations Table
create table if not exists stations (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  address text not null,
  city text,
  latitude numeric not null,
  longitude numeric not null,
  has_petrol boolean default true,
  has_diesel boolean default true,
  has_cng boolean default false,
  has_ev_charging boolean default false,
  has_lpg boolean default false,
  is_open_24_7 boolean default true,
  price_petrol numeric,
  price_diesel numeric,
  price_cng numeric,
  price_ev_kwh numeric,
  phone text,
  amenities text[] default array['Restrooms', 'Air Pump', 'Convenience Store'],
  status_petrol text default 'in_stock', -- 'in_stock', 'low_stock', 'empty'
  status_diesel text default 'in_stock',
  status_cng text default 'in_stock',
  status_ev text default 'available',
  rating numeric default 4.5,
  operator_id uuid references auth.users(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Advisories Table
create table if not exists advisories (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references profiles(id) on delete cascade not null,
  query_text text not null,
  ai_response jsonb not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. Enable Row Level Security (RLS)
alter table profiles enable row level security;
alter table stations enable row level security;
alter table advisories enable row level security;

-- 5. Profiles Policies
drop policy if exists "Users can view own profile" on profiles;
create policy "Users can view own profile" on profiles for select using (auth.uid() = id);

drop policy if exists "Users can update own profile" on profiles;
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on profiles;
create policy "Users can insert own profile" on profiles for insert with check (auth.uid() = id);

-- 6. Stations Policies
drop policy if exists "Everyone can view stations" on stations;
create policy "Everyone can view stations" on stations for select using (true);

drop policy if exists "Authenticated users can update stations" on stations;
create policy "Authenticated users can update stations" on stations for update using (auth.role() = 'authenticated');

drop policy if exists "Authenticated users can insert stations" on stations;
create policy "Authenticated users can insert stations" on stations for insert with check (auth.role() = 'authenticated');

-- 7. Advisories Policies
drop policy if exists "Users can view own advisories" on advisories;
create policy "Users can view own advisories" on advisories for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own advisories" on advisories;
create policy "Users can insert own advisories" on advisories for insert with check (auth.uid() = user_id);

-- Optional: Performance Indexes
create index if not exists idx_stations_geo on stations(latitude, longitude);
create index if not exists idx_advisories_user on advisories(user_id, created_at desc);
