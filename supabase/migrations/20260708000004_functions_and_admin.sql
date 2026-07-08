-- Discovery matching function
create or replace function public.get_nearby_matches(
  target_user_id uuid,
  user_coords geography(Point, 4326),
  radius_km float
)
returns table (
  profile_id uuid,
  username text,
  age integer,
  gender text,
  avatar_url text,
  distance_km float
) 
language plpgsql
security definer
as $$
declare
  pref_gender text;
begin
  select gender_interest into pref_gender 
  from public.user_preferences 
  where user_id = target_user_id;

  return query
  select 
    p.id as profile_id,
    p.username,
    p.age,
    p.gender,
    p.avatar_url,
    (ST_Distance(up.coords, user_coords) / 1000.0)::float as distance_km
  from public.profiles p
  join public.user_preferences up on p.id = up.user_id
  where p.id != target_user_id
    and (pref_gender = 'others' or p.gender = pref_gender)
    and ST_DWithin(up.coords, user_coords, radius_km * 1000.0)
  order by distance_km asc;
end;
$$;

-- Admin user growth view
create or replace view public.admin_user_growth as
select 
  created_at::date as signup_date,
  count(*) as user_count
from public.profiles
group by signup_date
order by signup_date desc;

-- Admin stats overview view
create or replace view public.admin_stats_overview as
select 
  count(*) as total_users,
  sum(case when is_verified then 1 else 0 end) as verified_users,
  sum(case when not is_verified then 1 else 0 end) as unverified_users,
  sum(case when not is_verified and created_at >= now() - interval '15 days' then 1 else 0 end) as active_trial_users
from public.profiles;

-- Secured admin growth stats function
create or replace function public.get_admin_growth_stats()
returns table (signup_date date, user_count bigint) 
language plpgsql
security definer
as $$
begin
  if not exists (
    select 1 from public.profiles 
    where id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Unauthorized access. Admins only.';
  end if;

  return query select * from public.admin_user_growth;
end;
$$;

-- Secured admin overview stats function
create or replace function public.get_admin_overview_stats()
returns table (
  total_users bigint,
  verified_users bigint,
  unverified_users bigint,
  active_trial_users bigint
) 
language plpgsql
security definer
as $$
begin
  if not exists (
    select 1 from public.profiles 
    where id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Unauthorized access. Admins only.';
  end if;

  return query select * from public.admin_stats_overview;
end;
$$;