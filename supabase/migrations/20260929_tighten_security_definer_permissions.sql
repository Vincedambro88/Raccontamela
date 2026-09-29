create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public;
revoke all on function public.handle_new_user() from anon;
revoke all on function public.handle_new_user() from authenticated;

revoke all on function public.register_device(text, text, text) from public;
revoke all on function public.register_device(text, text, text) from anon;
revoke all on function public.register_device(text, text, text) from authenticated;
grant execute on function public.register_device(text, text, text) to authenticated;
