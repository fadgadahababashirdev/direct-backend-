-- Auto create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, email, age, gender, role, is_verified)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', 'user_' || substr(new.id::text, 1, 8)),
    new.email,
    coalesce((new.raw_user_meta_data->>'age')::integer, 25),
    coalesce(new.raw_user_meta_data->>'gender', 'others'),
    'user',
    false
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Auto flip is_verified on email confirmation
create or replace function public.handle_email_confirmed()
returns trigger as $$
begin
  if new.email_confirmed_at is not null and old.email_confirmed_at is null then
    update public.profiles
    set is_verified = true
    where id = new.id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_email_confirmed
  after update on auth.users
  for each row execute function public.handle_email_confirmed();

-- Trial period check (15 days)
create or replace function public.check_trial_status()
returns trigger as $$
begin
  if not new.is_verified and new.created_at < now() - interval '15 days' then
    raise exception 'Trial expired. Account verification required.';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_check_trial_on_update
  before update on public.profiles
  for each row execute function public.check_trial_status();

-- Notify recipient on new message
create or replace function public.notify_recipient_on_message()
returns trigger as $$
declare
  recipient_id uuid;
begin
  select user_id into recipient_id
  from public.chat_members
  where chat_id = new.chat_id and user_id != new.sender_id
  limit 1;

  perform net.http_post(
    url := 'https://bmhwdocyicmocwtafnms.supabase.co/functions/v1/send-interest-push'::text,
    body := jsonb_build_object(
      'recipient_id', recipient_id,
      'sender_id', new.sender_id,
      'message', 'Someone is interested! Start to chat'
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json'
    )
  );

  return new;
end;
$$ language plpgsql security definer;

create trigger trigger_on_new_message
  after insert on public.messages
  for each row execute function public.notify_recipient_on_message();