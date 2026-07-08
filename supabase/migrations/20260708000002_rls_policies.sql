-- Profiles policies
create policy "Allow public read access to profiles"
  on public.profiles for select
  using (true);

create policy "Allow users to update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- User preferences policies
create policy "Allow users to view their own preferences"
  on public.user_preferences for select
  using (auth.uid() = user_id);

create policy "Allow users to upsert their own preferences"
  on public.user_preferences for insert
  with check (auth.uid() = user_id);

create policy "Allow users to update their own preferences"
  on public.user_preferences for update
  using (auth.uid() = user_id);

-- Chats policies
create policy "Allow chat members to view their chats"
  on public.chats for select
  using (
    exists (
      select 1 from public.chat_members
      where chat_id = id and user_id = auth.uid()
    )
  );

-- Chat members policies
create policy "Allow users to view chat memberships"
  on public.chat_members for select
  using (user_id = auth.uid());

create policy "Allow users to join chats"
  on public.chat_members for insert
  with check (user_id = auth.uid());

-- Messages policies
create policy "Allow chat members to view messages"
  on public.messages for select
  using (
    exists (
      select 1 from public.chat_members
      where chat_id = messages.chat_id and user_id = auth.uid()
    )
  );

create policy "Allow chat members to send messages"
  on public.messages for insert
  with check (
    sender_id = auth.uid() and
    exists (
      select 1 from public.chat_members
      where chat_id = messages.chat_id and user_id = auth.uid()
    )
  );

-- Subscriptions policies
create policy "Users can view their own subscription"
  on public.subscriptions for select
  using (auth.uid() = user_id);

create policy "Users can insert their own subscription"
  on public.subscriptions for insert
  with check (auth.uid() = user_id);


-- Admin policies for subscriptions
create policy "Allow admins to view all subscriptions"
  on public.subscriptions for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "Allow admins to update subscriptions"
  on public.subscriptions for update
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "Allow admins to delete subscriptions"
  on public.subscriptions for delete
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- Admin policies for profiles
create policy "Allow admins to view all profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "Allow admins to update all profiles"
  on public.profiles for update
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );