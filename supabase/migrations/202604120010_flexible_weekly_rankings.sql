-- Add explicit past-week weekly ranking RPCs without changing the
-- existing weekly RPC names used by the released app.
--
-- Do not overload get_weekly_leaderboard/get_my_weekly_rank/
-- get_my_weekly_best_score. PostgREST can fail to resolve overloaded RPCs
-- when the client omits optional parameters.

create or replace function public.get_weekly_leaderboard_by_week(
  p_game_id text,
  p_limit integer default 20,
  p_week_key text
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
  with target_week as (
    select p_week_key as week_key
  ),
  ranked as (
    select
      ws.user_id,
      ws.score,
      ws.updated_at,
      rank() over (order by ws.score desc) as rank
    from public.weekly_scores ws
    cross join target_week tw
    where ws.game_id = p_game_id
      and ws.week_key = tw.week_key
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
  limit greatest(coalesce(p_limit, 20), 1);
$$;

create or replace function public.get_my_weekly_rank_by_week(
  p_game_id text,
  p_week_key text
)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  with target_week as (
    select p_week_key as week_key
  ),
  ranked as (
    select
      ws.user_id,
      rank() over (order by ws.score desc) as rank
    from public.weekly_scores ws
    cross join target_week tw
    where ws.game_id = p_game_id
      and ws.week_key = tw.week_key
  )
  select ranked.rank::integer
  from ranked
  where ranked.user_id = auth.uid()
  limit 1;
$$;

create or replace function public.get_my_weekly_best_score_by_week(
  p_game_id text,
  p_week_key text
)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  with target_week as (
    select p_week_key as week_key
  )
  select ws.score
  from public.weekly_scores ws
  cross join target_week tw
  where ws.user_id = auth.uid()
    and ws.game_id = p_game_id
    and ws.week_key = tw.week_key
  limit 1;
$$;

revoke all on function public.get_weekly_leaderboard_by_week(text, integer, text) from public;
revoke all on function public.get_my_weekly_rank_by_week(text, text) from public;
revoke all on function public.get_my_weekly_best_score_by_week(text, text) from public;

grant execute on function public.get_weekly_leaderboard_by_week(text, integer, text) to anon;
grant execute on function public.get_weekly_leaderboard_by_week(text, integer, text) to authenticated;
grant execute on function public.get_my_weekly_rank_by_week(text, text) to authenticated;
grant execute on function public.get_my_weekly_best_score_by_week(text, text) to authenticated;

notify pgrst, 'reload schema';
