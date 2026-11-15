-- Fotos de platillos en Supabase Storage (bucket público, máx. 2 MB).
-- Requiere la función public.es_administrador_activo() de Employee_profiles.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('dish-photos', 'dish-photos', true, 2097152,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists dish_photos_upload on storage.objects;
create policy dish_photos_upload on storage.objects for insert to authenticated
with check (bucket_id = 'dish-photos' and public.es_administrador_activo());

drop policy if exists dish_photos_update on storage.objects;
create policy dish_photos_update on storage.objects for update to authenticated
using (bucket_id = 'dish-photos' and public.es_administrador_activo())
with check (bucket_id = 'dish-photos' and public.es_administrador_activo());

drop policy if exists dish_photos_delete on storage.objects;
create policy dish_photos_delete on storage.objects for delete to authenticated
using (bucket_id = 'dish-photos' and public.es_administrador_activo());

drop policy if exists dish_photos_read on storage.objects;
create policy dish_photos_read on storage.objects for select to authenticated
using (bucket_id = 'dish-photos');
