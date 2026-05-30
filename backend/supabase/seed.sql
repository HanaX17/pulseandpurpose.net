-- =============================================================================
-- seed.sql — local dev seed data (runs on `supabase db reset`)
-- =============================================================================
-- These users only exist in the LOCAL auth schema for development. Passwords
-- are 'password123'. Do NOT use in production.
-- =============================================================================

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, aud, role)
values
  ('11111111-1111-1111-1111-111111111111', 'mom@example.com',
   crypt('password123', gen_salt('bf')), now(),
   '{"display_name":"Mom"}', 'authenticated', 'authenticated'),
  ('22222222-2222-2222-2222-222222222222', 'grandpa@example.com',
   crypt('password123', gen_salt('bf')), now(),
   '{"display_name":"Grandpa"}', 'authenticated', 'authenticated')
on conflict (id) do nothing;

-- handle_new_user() trigger creates profiles + subscriptions automatically.

-- A family created by Mom (trigger makes her the owner).
insert into public.families (id, name, baby_name, baby_birthday, created_by)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Baby Lily''s Circle',
        'Lily', '2025-09-01', '11111111-1111-1111-1111-111111111111')
on conflict (id) do nothing;

-- Grandpa joins.
insert into public.family_members (family_id, user_id, role, relation)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '22222222-2222-2222-2222-222222222222', 'member', 'grandpa')
on conflict do nothing;

-- A sample post.
insert into public.posts (id, family_id, author_id, content, recorded_at)
values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111',
        'First smile today! 😊', now())
on conflict (id) do nothing;

insert into public.growth_records (family_id, author_id, metric, value, unit, recorded_at)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'height', 52.0, 'cm', '2025-09-01'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'weight', 3.4, 'kg', '2025-09-01')
on conflict do nothing;
