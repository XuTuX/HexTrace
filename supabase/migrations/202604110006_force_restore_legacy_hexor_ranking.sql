-- 랭킹 함수가 꼬인 상태를 강제로 정리하고
-- 92079c09a33041de0ce04b7199c719998fe76a17 시점의 단일 랭킹 구조로 복구

do $$
declare
  v_signature text;
begin
  for v_signature in
    select p.oid::regprocedure::text
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'submit_score',
        'get_leaderboard',
        'get_my_rank',
        'get_my_best_score'
      )
  loop
    execute format('drop function if exists %s cascade', v_signature);
  end loop;
end;
$$;

with ranked_scores as (
  select
    s.id,
    row_number() over (
      partition by s.user_id, s.game_id
      order by s.score desc, s.updated_at asc, s.id asc
    ) as rn
  from public.scores s
)
delete from public.scores s
using ranked_scores rs
where s.id = rs.id
  and rs.rn > 1;

alter table public.scores
  drop constraint if exists scores_user_game_week_unique;

alter table public.scores
  drop constraint if exists scores_user_game_key;

alter table public.scores
  add constraint scores_user_game_key
  unique (user_id, game_id);

drop index if exists public.scores_game_week_score_idx;

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
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_game_id is null or btrim(p_game_id) = '' then
    raise exception 'game_id is required';
  end if;

  select s.id, s.score
  into v_row_id, v_best_score
  from public.scores s
  where s.user_id = v_user_id
    and s.game_id = p_game_id
  order by s.score desc, s.updated_at desc, s.id desc
  limit 1
  for update;

  if v_row_id is null then
    insert into public.scores (user_id, game_id, score)
    values (v_user_id, p_game_id, v_next_score)
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

revoke all on function public.submit_score(text, integer) from public;
revoke all on function public.get_my_best_score(text) from public;
revoke all on function public.get_my_rank(text) from public;
revoke all on function public.get_leaderboard(text, integer) from public;

grant execute on function public.submit_score(text, integer) to authenticated;
grant execute on function public.get_my_best_score(text) to authenticated;
grant execute on function public.get_my_rank(text) to authenticated;
grant execute on function public.get_leaderboard(text, integer) to anon;
grant execute on function public.get_leaderboard(text, integer) to authenticated;
