create or replace function public.get_my_weekly_season_summary(p_game_id text)
returns table (
  week_key text,
  participant_count integer,
  rank integer,
  score integer,
  tier text
)
language sql
stable
security definer
set search_path = public
as $$
  with current_week as (
    select to_char(timezone('Asia/Seoul', now()), 'IYYY-IW') as week_key
  ),
  ranked as (
    select
      ws.user_id,
      ws.score,
      rank() over (order by ws.score desc) as rank,
      count(*) over () as participant_count
    from public.weekly_scores ws
    cross join current_week cw
    where ws.game_id = p_game_id
      and ws.week_key = cw.week_key
  )
  select
    cw.week_key,
    r.participant_count::integer,
    r.rank::integer,
    r.score,
    case
      when coalesce(r.score, 0) >= 50000 then 'diamond'
      when coalesce(r.score, 0) >= 30000 then 'platinum'
      when coalesce(r.score, 0) >= 20000 then 'gold'
      when coalesce(r.score, 0) >= 10000 then 'silver'
      else 'bronze'
    end as tier
  from current_week cw
  left join ranked r
    on r.user_id = auth.uid();
$$;
