-- PIXORA Supabase schema
-- Jalankan seluruh file ini di Supabase Dashboard > SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text not null check (char_length(display_name) between 1 and 30),
  bio text not null default '',
  avatar_url text,
  banner_url text,
  is_private boolean not null default false,
  hide_likes boolean not null default false,
  is_verified boolean not null default false,
  is_holo boolean not null default false,
  is_exclusive boolean not null default false,
  is_owner boolean not null default false,
  is_banned boolean not null default false,
  ban_reason text,
  created_at timestamptz not null default now()
);

create table if not exists public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now(),
  constraint no_self_dm check (sender_id <> receiver_id)
);
create index if not exists direct_messages_sender_created_idx on public.direct_messages(sender_id, created_at desc);
create index if not exists direct_messages_receiver_created_idx on public.direct_messages(receiver_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.direct_messages enable row level security;

grant select on public.profiles to authenticated;
grant insert (id, username, display_name, bio) on public.profiles to authenticated;
grant update (username, display_name, bio, avatar_url, banner_url, is_private, hide_likes) on public.profiles to authenticated;
grant select, insert on public.direct_messages to authenticated;

 drop policy if exists "Profiles are visible to signed-in users" on public.profiles;
create policy "Profiles are visible to signed-in users" on public.profiles
for select to authenticated using (true);

drop policy if exists "Users create their own profile" on public.profiles;
create policy "Users create their own profile" on public.profiles
for insert to authenticated with check (auth.uid() = id);

drop policy if exists "Users update their own profile" on public.profiles;
create policy "Users update their own profile" on public.profiles
for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "Users read only their conversations" on public.direct_messages;
create policy "Users read only their conversations" on public.direct_messages
for select to authenticated using (auth.uid() = sender_id or auth.uid() = receiver_id);

drop policy if exists "Users send messages as themselves" on public.direct_messages;
create policy "Users send messages as themselves" on public.direct_messages
for insert to authenticated with check (auth.uid() = sender_id and sender_id <> receiver_id);

-- Realtime untuk pesan masuk (aman dijalankan ulang).
do $$ begin
  alter publication supabase_realtime add table public.direct_messages;
exception when duplicate_object then null;
end $$;

-- Pembuatan profil otomatis saat user mendaftar melalui Supabase Auth.
create or replace function public.handle_new_pixora_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    lower(coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1))),
    coalesce(new.raw_user_meta_data->>'display_name', 'Pengguna PIXORA')
  ) on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_pixora on auth.users;
create trigger on_auth_user_created_pixora
after insert on auth.users for each row execute procedure public.handle_new_pixora_user();
