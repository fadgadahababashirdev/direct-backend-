-- Enable extensions
create extension if not exists postgis;
create extension if not exists pg_net;

-- Profiles table
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  email text unique not null,
  age integer check (age >= 18),
  gender text check (gender in ('male', 'female', 'others')) not null,
  role text check (role in ('user', 'admin')) default 'user' not null,
  avatar_url text,
  is_verified boolean default false not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.profiles enable row level security;

-- User preferences table
create table public.user_preferences (
  user_id uuid references public.profiles(id) on delete cascade primary key,
  gender_interest text check (gender_interest in ('male', 'female', 'others')) not null,
  location_type text check (location_type in ('current', 'preferred')) not null,
  preferred_location_name text,
  coords geography(Point, 4326),
  search_radius_km float check (search_radius_km in (1.0, 2.0, 3.0)) not null
);

alter table public.user_preferences enable row level security;

-- Chats table
create table public.chats (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Chat members table
create table public.chat_members (
  chat_id uuid references public.chats(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  primary key (chat_id, user_id)
);

-- Messages table
create table public.messages (
  id uuid default gen_random_uuid() primary key,
  chat_id uuid references public.chats(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  content_encrypted text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.chats enable row level security;
alter table public.chat_members enable row level security;
alter table public.messages enable row level security;

-- Subscriptions table
create table public.subscriptions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  plan text check (plan in ('free', 'premium', 'premium_plus', 'verified_trust')) default 'free' not null,
  status text check (status in ('active', 'expired', 'cancelled')) default 'active' not null,
  amount integer not null default 0,
  currency text default 'RWF' not null,
  payment_method text check (payment_method in ('mtn', 'airtel', 'card')),
  transaction_id text unique,
  starts_at timestamp with time zone default timezone('utc'::text, now()) not null,
  expires_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.subscriptions enable row level security;