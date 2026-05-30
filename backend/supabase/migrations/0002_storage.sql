-- =============================================================================
-- 0002_storage.sql — Private media bucket + family-scoped access policies
-- =============================================================================
-- Object key convention:  {family_id}/{post_id}/{filename}
-- The first path segment is the family id, which we use to authorize access.
--
-- NOTE: If you serve media from Cloudflare R2 instead (recommended for cost —
-- R2 has $0 egress), this bucket goes unused and authorization is handled by
-- signing R2 URLs in an Edge Function. See backend/README.md.
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'media', 'media', false,
  104857600,  -- 100 MB per object
  array['image/jpeg','image/png','image/webp','image/heic','video/mp4','video/quicktime']
)
on conflict (id) do nothing;

-- Helper: the family id is the first segment of the object name.
create or replace function public.storage_family_id(object_name text)
returns uuid
language sql
immutable
as $$
  select nullif(split_part(object_name, '/', 1), '')::uuid;
$$;

create policy "media read for family members"
  on storage.objects for select
  using (
    bucket_id = 'media'
    and public.is_family_member(public.storage_family_id(name))
  );

create policy "media insert for family members"
  on storage.objects for insert
  with check (
    bucket_id = 'media'
    and public.is_family_member(public.storage_family_id(name))
  );

create policy "media delete for family members"
  on storage.objects for delete
  using (
    bucket_id = 'media'
    and public.is_family_member(public.storage_family_id(name))
  );
