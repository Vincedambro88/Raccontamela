create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  locale text not null default 'it' check (locale in ('it','en','fr','es','de')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.premium_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  product_id text not null,
  purchase_token_hash text,
  status text not null default 'active' check (status in ('active','revoked','pending','expired')),
  expires_at timestamptz,
  last_validated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.device_registrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id_hash text not null,
  platform text not null default 'android',
  device_name text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(user_id, device_id_hash)
);

create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  locale text not null default 'it' check (locale in ('it','en','fr','es','de')),
  title text,
  protagonist_name text not null,
  setting text not null,
  story_city text not null,
  friends jsonb not null default '[]'::jsonb,
  animal_friends jsonb not null default '[]'::jsonb,
  story_text text,
  duration_seconds integer,
  status text not null default 'draft' check (status in ('draft','generating','ready','failed')),
  is_premium_story boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.story_scenes (
  id uuid primary key default gen_random_uuid(),
  story_id uuid not null references public.stories(id) on delete cascade,
  scene_index integer not null,
  text text not null,
  color_image_path text,
  bw_image_path text,
  narration_path text,
  created_at timestamptz not null default now(),
  unique(story_id, scene_index)
);

create index if not exists idx_stories_user_created on public.stories(user_id, created_at desc);
create index if not exists idx_devices_user on public.device_registrations(user_id);

alter table public.profiles enable row level security;
alter table public.premium_entitlements enable row level security;
alter table public.device_registrations enable row level security;
alter table public.stories enable row level security;
alter table public.story_scenes enable row level security;

create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);
create policy "entitlements_select_own" on public.premium_entitlements for select using (auth.uid() = user_id);
create policy "devices_select_own" on public.device_registrations for select using (auth.uid() = user_id);
create policy "stories_select_own" on public.stories for select using (auth.uid() = user_id);
create policy "stories_insert_own" on public.stories for insert with check (auth.uid() = user_id);
create policy "stories_update_own" on public.stories for update using (auth.uid() = user_id);
create policy "stories_delete_own" on public.stories for delete using (auth.uid() = user_id);
create policy "scene_select_own_story" on public.story_scenes for select using (
  exists (select 1 from public.stories s where s.id = story_scenes.story_id and s.user_id = auth.uid())
);