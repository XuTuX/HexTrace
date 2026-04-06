revoke all on function public.submit_score(text, integer) from public;
revoke all on function public.get_my_best_score(text) from public;
revoke all on function public.get_my_rank(text) from public;
revoke all on function public.get_leaderboard(text, integer) from public;
revoke all on function public.is_nickname_available(text) from public;
revoke all on function public.delete_my_account_data() from public;

grant execute on function public.submit_score(text, integer) to authenticated;
grant execute on function public.get_my_best_score(text) to authenticated;
grant execute on function public.get_my_rank(text) to authenticated;
grant execute on function public.get_leaderboard(text, integer) to anon;
grant execute on function public.get_leaderboard(text, integer) to authenticated;
grant execute on function public.is_nickname_available(text) to authenticated;
grant execute on function public.delete_my_account_data() to authenticated;
