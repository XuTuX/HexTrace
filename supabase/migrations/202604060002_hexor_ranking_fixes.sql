alter table public.profiles enable row level security;
alter table public.scores enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists scores_select_own on public.scores;
create policy scores_select_own
on public.scores
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists scores_insert_own on public.scores;
create policy scores_insert_own
on public.scores
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists scores_update_own on public.scores;
create policy scores_update_own
on public.scores
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists scores_delete_own on public.scores;
create policy scores_delete_own
on public.scores
for delete
to authenticated
using (auth.uid() = user_id);

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

grant execute on function public.get_my_best_score(text) to authenticated;
grant execute on function public.get_my_rank(text) to authenticated;
grant execute on function public.get_leaderboard(text, integer) to authenticated;
