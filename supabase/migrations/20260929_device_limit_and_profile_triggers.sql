create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists entitlements_set_updated_at on public.premium_entitlements;
create trigger entitlements_set_updated_at
before update on public.premium_entitlements
for each row execute function public.set_updated_at();

drop trigger if exists stories_set_updated_at on public.stories;
create trigger stories_set_updated_at
before update on public.stories
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.register_device(
  p_device_id_hash text,
  p_platform text default 'android',
  p_device_name text default null
)
returns public.device_registrations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_device public.device_registrations;
  v_count integer;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if p_device_id_hash is null or length(trim(p_device_id_hash)) < 16 then
    raise exception 'INVALID_DEVICE_ID';
  end if;

  select *
  into v_device
  from public.device_registrations
  where user_id = v_user_id
    and device_id_hash = p_device_id_hash
  for update;

  if v_device.id is not null then
    update public.device_registrations
    set platform = coalesce(nullif(trim(p_platform), ''), platform),
        device_name = coalesce(nullif(trim(p_device_name), ''), device_name),
        last_seen_at = now()
    where id = v_device.id
    returning * into v_device;
    return v_device;
  end if;

  select count(*) into v_count
  from public.device_registrations
  where user_id = v_user_id;

  if v_count >= 2 then
    raise exception 'DEVICE_LIMIT_REACHED';
  end if;

  insert into public.device_registrations (
    user_id, device_id_hash, platform, device_name
  )
  values (
    v_user_id,
    trim(p_device_id_hash),
    coalesce(nullif(trim(p_platform), ''), 'android'),
    nullif(trim(p_device_name), '')
  )
  returning * into v_device;

  return v_device;
end;
$$;

revoke all on function public.register_device(text, text, text) from public;
grant execute on function public.register_device(text, text, text) to authenticated;
