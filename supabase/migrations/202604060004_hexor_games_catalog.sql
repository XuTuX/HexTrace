create table if not exists public.games (
  id text primary key,
  name text not null,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.games
  add column if not exists name text,
  add column if not exists created_at timestamptz default timezone('utc', now());

update public.games
set
  name = coalesce(nullif(btrim(name), ''), initcap(replace(id, '_', ' '))),
  created_at = coalesce(created_at, timezone('utc', now()))
where name is null
   or btrim(name) = ''
   or created_at is null;

alter table public.games
  alter column name set not null,
  alter column created_at set default timezone('utc', now()),
  alter column created_at set not null;

insert into public.games (id, name)
values
  ('fillyourarea', 'Fill Your Area'),
  ('link_your_area_ranked_rating', 'Link Your Area (Ranked)'),
  ('overlap', 'Overlap'),
  ('hexor', 'Hexor')
on conflict (id) do update
set name = excluded.name;

insert into public.games (id, name)
select distinct
  s.game_id,
  initcap(replace(s.game_id, '_', ' '))
from public.scores s
left join public.games g
  on g.id = s.game_id
where g.id is null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'scores_game_id_fkey'
      and conrelid = 'public.scores'::regclass
  ) then
    alter table public.scores
      add constraint scores_game_id_fkey
      foreign key (game_id)
      references public.games (id);
  end if;
end;
$$;

alter table public.games enable row level security;

drop policy if exists games_select_all on public.games;
create policy games_select_all
on public.games
for select
to anon, authenticated
using (true);

grant select on public.games to anon, authenticated;
