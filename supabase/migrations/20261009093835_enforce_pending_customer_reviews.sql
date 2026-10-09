-- Applied to the hosted project on 2026-10-09; exported from its migration history.
alter policy "Customers create own reviews" on public.denz_reviews
with check ((select auth.uid()) = user_id and status = 'pending');
alter policy "Customers update pending own reviews" on public.denz_reviews
with check ((((select auth.uid()) = user_id) and status = 'pending') or private.is_denz_admin());
drop trigger denz_reviews_verify on public.denz_reviews;
create trigger denz_reviews_verify before insert or update on public.denz_reviews
for each row execute function public.denz_set_verified_review();
