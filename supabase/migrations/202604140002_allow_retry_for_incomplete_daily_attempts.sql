create or replace function public.claim_daily_challenge_entry(p_game_id text)
returns table (
  date_key text,
  seed integer,
  has_used_entry boolean,
  my_score integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_date_key text := to_char(timezone('Asia/Seoul', now()), 'YYYY-MM-DD');
  v_seed integer := public.get_daily_challenge_seed(p_game_id, v_date_key);
  v_existing_score integer;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_game_id is null or btrim(p_game_id) = '' then
    raise exception 'game_id is required';
  end if;

  select ds.score
  into v_existing_score
  from public.daily_scores ds
  where ds.user_id = v_user_id
    and ds.game_id = p_game_id
    and ds.date_key = v_date_key
  limit 1;

  if v_existing_score is not null then
    raise exception 'Daily challenge already used';
  end if;

  insert into public.daily_attempts (user_id, game_id, date_key, seed)
  values (v_user_id, p_game_id, v_date_key, v_seed)
  on conflict (user_id, game_id, date_key) do nothing;

  return query
  select
    v_date_key,
    v_seed,
    true,
    null::integer;
end;
$$;

revoke all on function public.claim_daily_challenge_entry(text) from public;

grant execute on function public.claim_daily_challenge_entry(text) to authenticated;

notify pgrst, 'reload schema';
