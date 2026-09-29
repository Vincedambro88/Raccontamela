drop policy if exists "stories_select_own" on public.stories;
create policy "stories_select_own_active_premium" on public.stories
for select using (
  auth.uid() = user_id
  and exists (
    select 1
    from public.premium_entitlements e
    where e.user_id = auth.uid()
      and e.status = 'active'
      and (e.expires_at is null or e.expires_at > now())
  )
);

drop policy if exists "scene_select_own_story" on public.story_scenes;
create policy "scene_select_own_active_premium_story" on public.story_scenes
for select using (
  exists (
    select 1
    from public.stories s
    where s.id = story_scenes.story_id
      and s.user_id = auth.uid()
      and exists (
        select 1
        from public.premium_entitlements e
        where e.user_id = auth.uid()
          and e.status = 'active'
          and (e.expires_at is null or e.expires_at > now())
      )
  )
);