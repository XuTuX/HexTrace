-- 다른 게임은 그대로 두고, hexor만 92079c09a33041de0ce04b7199c719998fe76a17 시점과 호환되게 복구
-- 핵심:
-- 1) 모호한 오버로드를 제거해 구버전 앱 RPC 호출을 다시 살림
-- 2) hexor만 예전 "전체 최고 점수" 방식으로 동작
-- 3) 다른 게임은 현재 주간 리셋 로직 유지

alter table public.scores
  add column if not exists week_key text;

drop function if exists public.get_leaderboard(text, integer);
drop function if exists public.get_my_rank(text);
drop function if exists public.get_my_best_score(text);

create or replace function public.submit_score(p_game_id text, p_score integer)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_row_id bigint;
  v_best_score integer;
  v_next_score integer := greatest(coalesce(p_score, 0), 0);
  v_current_week text := to_char(timezone('utc', now()), 'IYYY-IW');
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_game_id is null or btrim(p_game_id) = '' then
    raise exception 'game_id is required';
  end if;

  if p_game_id = 'hexor' then
    select s.id, s.score
    into v_row_id, v_best_score
    from public.scores s
    where s.user_id = v_user_id
      and s.game_id = p_game_id
    order by s.score desc, s.updated_at desc, s.id desc
    limit 1
    for update;

    if v_row_id is null then
      insert into public.scores (user_id, game_id, score, week_key)
      values (v_user_id, p_game_id, v_next_score, coalesce(v_current_week, 'legacy'))
      returning id, score into v_row_id, v_best_score;
    else
      update public.scores
      set score = greatest(score, v_next_score)
      where id = v_row_id
      returning score into v_best_score;

      delete from public.scores
      where user_id = v_user_id
        and game_id = p_game_id
        and id <> v_row_id;
    end if;

    return v_best_score;
  end if;

  select s.id, s.score
  into v_row_id, v_best_score
  from public.scores s
  where s.user_id = v_user_id
    and s.game_id = p_game_id
    and s.week_key = v_current_week
  order by s.score desc, s.updated_at desc, s.id desc
  limit 1
  for update;

  if v_row_id is null then
    insert into public.scores (user_id, game_id, score, week_key)
    values (v_user_id, p_game_id, v_next_score, v_current_week)
    returning id, score into v_row_id, v_best_score;
  else
    update public.scores
    set
      score = greatest(score, v_next_score),
      updated_at = timezone('utc', now())
    where id = v_row_id
    returning score into v_best_score;

    delete from public.scores
    where user_id = v_user_id
      and game_id = p_game_id
      and week_key = v_current_week
      and id <> v_row_id;
  end if;

  return v_best_score;
end;
$$;

create or replace function public.get_leaderboard(
  p_game_id text,
  p_limit integer default 50,
  p_period text default 'all'
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
      and (
        p_game_id = 'hexor'
        or p_period = 'all'
        or s.week_key = to_char(timezone('utc', now()), 'IYYY-IW')
      )
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

create or replace function public.get_my_rank(
  p_game_id text,
  p_period text default 'all'
)
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
      and (
        p_game_id = 'hexor'
        or p_period = 'all'
        or s.week_key = to_char(timezone('utc', now()), 'IYYY-IW')
      )
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

create or replace function public.get_my_best_score(
  p_game_id text,
  p_period text default 'all'
)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select max(s.score)
  from public.scores s
  where s.user_id = auth.uid()
    and s.game_id = p_game_id
    and (
      p_game_id = 'hexor'
      or p_period = 'all'
      or s.week_key = to_char(timezone('utc', now()), 'IYYY-IW')
    );
$$;

revoke all on function public.get_my_best_score(text, text) from public;
revoke all on function public.get_my_rank(text, text) from public;
revoke all on function public.get_leaderboard(text, integer, text) from public;

grant execute on function public.submit_score(text, integer) to authenticated;
grant execute on function public.get_my_best_score(text, text) to authenticated;
grant execute on function public.get_my_rank(text, text) to authenticated;
grant execute on function public.get_leaderboard(text, integer, text) to anon;
grant execute on function public.get_leaderboard(text, integer, text) to authenticated;
