insert into storage.buckets (id, name, public)
values ('story-assets', 'story-assets', false)
on conflict (id) do update set public = false;

create table if not exists public.story_media_jobs (
  id uuid primary key default gen_random_uuid(),
  story_id uuid not null references public.stories(id) on delete cascade,
  scene_id uuid references public.story_scenes(id) on delete cascade,
  kind text not null check (kind in ('color_image','bw_image','narration')),
  status text not null default 'queued' check (status in ('queued','processing','ready','failed')),
  provider text,
  voice_id text,
  storage_path text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(story_id, scene_id, kind)
);

create index if not exists idx_story_media_jobs_story on public.story_media_jobs(story_id);

alter table public.story_media_jobs enable row level security;

create policy "media_jobs_select_own_active_premium" on public.story_media_jobs
for select using (
  exists (
    select 1 from public.stories s
    join public.premium_entitlements e on e.user_id = s.user_id
    where s.id = story_media_jobs.story_id
      and s.user_id = auth.uid()
      and e.status = 'active'
      and (e.expires_at is null or e.expires_at > now())
  )
);

create policy "story_assets_select_own_active_premium" on storage.objects
for select using (
  bucket_id = 'story-assets'
  and exists (
    select 1
    from public.story_scenes sc
    join public.stories s on s.id = sc.story_id
    join public.premium_entitlements e on e.user_id = s.user_id
    where s.user_id = auth.uid()
      and e.status = 'active'
      and (e.expires_at is null or e.expires_at > now())
      and (
        name = sc.color_image_path
        or name = sc.bw_image_path
        or name = sc.narration_path
      )
  )
);