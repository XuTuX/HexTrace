-- Restore the original ranking RPC names expected by the Hexor app.
-- PostgREST resolves RPCs by function name + named parameters, so extra
-- overloads like get_leaderboard(text, integer, integer) make the older
-- get_leaderboard(p_game_id, p_limit) call ambiguous.

do $$
begin
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'get_leaderboard'
      and oidvectortypes(p.proargtypes) = 'text, integer, integer'
  ) then
    if exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'get_leaderboard_by_days'
        and oidvectortypes(p.proargtypes) = 'text, integer, integer'
    ) then
      drop function public.get_leaderboard(text, integer, integer);
    else
      alter function public.get_leaderboard(text, integer, integer)
        rename to get_leaderboard_by_days;
    end if;
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'get_leaderboard'
      and oidvectortypes(p.proargtypes) = 'text, integer, text'
  ) then
    if exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'get_leaderboard_by_period'
        and oidvectortypes(p.proargtypes) = 'text, integer, text'
    ) then
      drop function public.get_leaderboard(text, integer, text);
    else
      alter function public.get_leaderboard(text, integer, text)
        rename to get_leaderboard_by_period;
    end if;
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'get_my_rank'
      and oidvectortypes(p.proargtypes) = 'text, integer'
  ) then
    if exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'get_my_rank_by_days'
        and oidvectortypes(p.proargtypes) = 'text, integer'
    ) then
      drop function public.get_my_rank(text, integer);
    else
      alter function public.get_my_rank(text, integer)
        rename to get_my_rank_by_days;
    end if;
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'get_my_rank'
      and oidvectortypes(p.proargtypes) = 'text, text'
  ) then
    if exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'get_my_rank_by_period'
        and oidvectortypes(p.proargtypes) = 'text, text'
    ) then
      drop function public.get_my_rank(text, text);
    else
      alter function public.get_my_rank(text, text)
        rename to get_my_rank_by_period;
    end if;
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'get_my_best_score'
      and oidvectortypes(p.proargtypes) = 'text, integer'
  ) then
    if exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'get_my_best_score_by_days'
        and oidvectortypes(p.proargtypes) = 'text, integer'
    ) then
      drop function public.get_my_best_score(text, integer);
    else
      alter function public.get_my_best_score(text, integer)
        rename to get_my_best_score_by_days;
    end if;
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'get_my_best_score'
      and oidvectortypes(p.proargtypes) = 'text, text'
  ) then
    if exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'get_my_best_score_by_period'
        and oidvectortypes(p.proargtypes) = 'text, text'
    ) then
      drop function public.get_my_best_score(text, text);
    else
      alter function public.get_my_best_score(text, text)
        rename to get_my_best_score_by_period;
    end if;
  end if;
end;
$$;

create or replace function public.get_my_best_score(p_game_id text)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  with best_scores as (
    select distinct on (s.user_id)
      s.user_id,
      s.score,
      s.updated_at
    from public.scores s
    where s.game_id = p_game_id
    order by s.user_id, s.score desc, s.updated_at asc, s.id asc
  )
  select bs.score
  from best_scores bs
  where bs.user_id = auth.uid()
  limit 1;
$$;

create or replace function public.get_my_rank(p_game_id text)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  with best_scores as (
    select distinct on (s.user_id)
      s.user_id,
      s.score,
      s.updated_at
    from public.scores s
    where s.game_id = p_game_id
    order by s.user_id, s.score desc, s.updated_at asc, s.id asc
  ),
  ranked as (
    select
      bs.user_id,
      rank() over (order by bs.score desc) as rank
    from best_scores bs
  )
  select ranked.rank::integer
  from ranked
  where ranked.user_id = auth.uid()
  limit 1;
$$;

create or replace function public.get_leaderboard(
  p_game_id text,
  p_limit integer default 50
)
returns table (
  user_id uuid,
  score integer,
  nickname text,
  avatar_url text,
  rank bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with best_scores as (
    select distinct on (s.user_id)
      s.user_id,
      s.score,
      s.updated_at
    from public.scores s
    where s.game_id = p_game_id
    order by s.user_id, s.score desc, s.updated_at asc, s.id asc
  ),
  ranked as (
    select
      bs.user_id,
      bs.score,
      bs.updated_at,
      rank() over (order by bs.score desc) as rank
    from best_scores bs
  )
  select
    r.user_id,
    r.score,
    coalesce(
      nullif(btrim(p.nickname), ''),
      'Player ' || upper(substr(r.user_id::text, 1, 6))
    ) as nickname,
    p.avatar_url,
    r.rank
  from ranked r
  left join public.profiles p
    on p.id = r.user_id
  order by r.rank asc, r.updated_at asc, r.user_id asc
  limit greatest(coalesce(p_limit, 50), 1);
$$;

revoke all on function public.get_my_best_score(text) from public;
revoke all on function public.get_my_rank(text) from public;
revoke all on function public.get_leaderboard(text, integer) from public;

grant execute on function public.get_my_best_score(text) to authenticated;
grant execute on function public.get_my_rank(text) to authenticated;
grant execute on function public.get_leaderboard(text, integer) to anon;
grant execute on function public.get_leaderboard(text, integer) to authenticated;

notify pgrst, 'reload schema';
