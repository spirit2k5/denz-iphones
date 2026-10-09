-- Applied to the hosted project on 2026-10-09; exported from its migration history.
-- Guests must not call the owner-only private.is_denz_admin function.
alter policy "Public read approved reviews" on public.denz_reviews to authenticated;
create policy "Guests read approved reviews" on public.denz_reviews
for select to anon using (status = 'approved');
