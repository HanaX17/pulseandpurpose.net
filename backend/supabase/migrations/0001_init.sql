-- =============================================================================
-- 0001_init.sql — Core schema for the family photo / growth-sharing app
-- =============================================================================
-- Design goals:
--   * A "family circle" (families) owns all content about one baby.
--   * Only members of a family (family_members) may read/write its content.
--   * Row Level Security (RLS) is the single source of truth for access.
-- =============================================================================

create extension if not exists "pgcrypto";

-- -----------------------------------------------------------------------------
-- profiles : 1-1 with auth.users, holds public-ish user data
-- -----------------------------------------------------------------------------
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- families : one "circle" per baby
-- -----------------------------------------------------------------------------
create table public.families (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  baby_name       text,
  baby_birthday   date,
  baby_avatar_url text,
  created_by      uuid not null references auth.users (id) on delete restrict,
  created_at      timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- family_members : membership + role + relation (爸爸/妈妈/爷爷…)
-- -----------------------------------------------------------------------------
create type public.member_role as enum ('owner', 'admin', 'member');

-- NOTE: user_id / author_id columns that we embed via PostgREST point at
-- public.profiles(id) (which is itself 1-1 with auth.users) so that
-- `select(..., profiles(*))` resource embedding resolves the relationship.
create table public.family_members (
  family_id  uuid not null references public.families (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  role       public.member_role not null default 'member',
  relation   text,                          -- free text: 'mom', 'grandpa', '妈妈'…
  joined_at  timestamptz not null default now(),
  primary key (family_id, user_id)
);
create index family_members_user_idx on public.family_members (user_id);

-- -----------------------------------------------------------------------------
-- Access helpers — SECURITY DEFINER so RLS policies can call them WITHOUT
-- re-triggering RLS on family_members (avoids infinite recursion).
-- -----------------------------------------------------------------------------
create or replace function public.is_family_member(p_family_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.family_members
    where family_id = p_family_id and user_id = auth.uid()
  );
$$;

create or replace function public.is_family_admin(p_family_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.family_members
    where family_id = p_family_id
      and user_id = auth.uid()
      and role in ('owner', 'admin')
  );
$$;

-- -----------------------------------------------------------------------------
-- invitations : shareable codes to join a family
-- -----------------------------------------------------------------------------
create table public.invitations (
  id          uuid primary key default gen_random_uuid(),
  family_id   uuid not null references public.families (id) on delete cascade,
  code        text not null unique,
  created_by  uuid not null references auth.users (id) on delete cascade,
  relation    text,                         -- suggested relation for the invitee
  expires_at  timestamptz,
  max_uses    int not null default 20,
  used_count  int not null default 0,
  created_at  timestamptz not null default now()
);
create index invitations_family_idx on public.invitations (family_id);

-- -----------------------------------------------------------------------------
-- posts : a timeline entry (moment) or growth milestone note
-- -----------------------------------------------------------------------------
create type public.record_type as enum ('moment', 'milestone');

create table public.posts (
  id           uuid primary key default gen_random_uuid(),
  family_id    uuid not null references public.families (id) on delete cascade,
  author_id    uuid not null references public.profiles (id) on delete cascade,
  content      text,
  record_type  public.record_type not null default 'moment',
  recorded_at  timestamptz not null default now(),  -- when the memory happened
  created_at   timestamptz not null default now()
);
create index posts_family_recorded_idx on public.posts (family_id, recorded_at desc);

-- -----------------------------------------------------------------------------
-- media : files attached to a post. storage_path points at the object store
-- (Supabase Storage bucket, or an external bucket like Cloudflare R2).
-- -----------------------------------------------------------------------------
create type public.media_type as enum ('image', 'video');

create table public.media (
  id           uuid primary key default gen_random_uuid(),
  post_id      uuid not null references public.posts (id) on delete cascade,
  family_id    uuid not null references public.families (id) on delete cascade, -- denormalized for RLS/storage
  storage_path text not null,                 -- e.g. media/{family_id}/{post_id}/{file}
  type         public.media_type not null default 'image',
  width        int,
  height       int,
  duration_ms  int,                            -- for video
  byte_size    bigint,
  position     int not null default 0,         -- ordering within the post
  created_at   timestamptz not null default now()
);
create index media_post_idx on public.media (post_id, position);

-- -----------------------------------------------------------------------------
-- comments : 留言
-- -----------------------------------------------------------------------------
create table public.comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts (id) on delete cascade,
  family_id  uuid not null references public.families (id) on delete cascade,
  author_id  uuid not null references public.profiles (id) on delete cascade,
  content    text not null,
  created_at timestamptz not null default now()
);
create index comments_post_idx on public.comments (post_id, created_at);

-- -----------------------------------------------------------------------------
-- reactions : 点赞 / emoji
-- -----------------------------------------------------------------------------
create table public.reactions (
  post_id    uuid not null references public.posts (id) on delete cascade,
  family_id  uuid not null references public.families (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  emoji      text not null default '❤️',
  created_at timestamptz not null default now(),
  primary key (post_id, user_id, emoji)
);

-- -----------------------------------------------------------------------------
-- growth_records : height / weight / milestone data points
-- -----------------------------------------------------------------------------
create type public.growth_metric as enum ('height', 'weight', 'head', 'milestone');

create table public.growth_records (
  id           uuid primary key default gen_random_uuid(),
  family_id    uuid not null references public.families (id) on delete cascade,
  author_id    uuid not null references auth.users (id) on delete cascade,
  metric       public.growth_metric not null,
  value        numeric,                        -- null for textual milestones
  unit         text,                           -- 'cm' | 'kg' | null
  note         text,
  recorded_at  date not null default current_date,
  created_at   timestamptz not null default now()
);
create index growth_family_idx on public.growth_records (family_id, recorded_at);

-- -----------------------------------------------------------------------------
-- subscriptions : premium state (stubbed; verified by an Edge Function)
-- -----------------------------------------------------------------------------
create type public.sub_tier   as enum ('free', 'premium');
create type public.sub_status as enum ('active', 'expired', 'canceled', 'in_trial');

create table public.subscriptions (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  tier        public.sub_tier   not null default 'free',
  status      public.sub_status not null default 'active',
  store       text,                            -- 'apple' | 'google' | null
  product_id  text,
  expires_at  timestamptz,
  updated_at  timestamptz not null default now()
);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-create a profile + a free subscription row when a user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;

  insert into public.subscriptions (user_id) values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- When a family is created, make the creator the owner.
create or replace function public.handle_new_family()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.family_members (family_id, user_id, role, relation)
  values (new.id, new.created_by, 'owner', null)
  on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_family_created on public.families;
create trigger on_family_created
  after insert on public.families
  for each row execute function public.handle_new_family();

-- =============================================================================
-- Row Level Security
-- =============================================================================
alter table public.profiles       enable row level security;
alter table public.families        enable row level security;
alter table public.family_members  enable row level security;
alter table public.invitations     enable row level security;
alter table public.posts           enable row level security;
alter table public.media           enable row level security;
alter table public.comments        enable row level security;
alter table public.reactions       enable row level security;
alter table public.growth_records  enable row level security;
alter table public.subscriptions   enable row level security;

-- profiles: a user reads/edits their own; members can read each other's basic profile.
create policy "profiles self read"   on public.profiles for select using (auth.uid() = id);
create policy "profiles self upsert" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles self update" on public.profiles for update using (auth.uid() = id);

-- families: members read; only the creator can insert; admins update; owner deletes.
create policy "families member read" on public.families
  for select using (public.is_family_member(id));
create policy "families create" on public.families
  for insert with check (auth.uid() = created_by);
create policy "families admin update" on public.families
  for update using (public.is_family_admin(id));
create policy "families owner delete" on public.families
  for delete using (
    exists (select 1 from public.family_members
            where family_id = id and user_id = auth.uid() and role = 'owner')
  );

-- family_members: members can see the roster; admins manage; users can remove themselves.
create policy "members read" on public.family_members
  for select using (public.is_family_member(family_id));
create policy "members admin insert" on public.family_members
  for insert with check (public.is_family_admin(family_id));
create policy "members admin update" on public.family_members
  for update using (public.is_family_admin(family_id));
create policy "members admin or self delete" on public.family_members
  for delete using (public.is_family_admin(family_id) or user_id = auth.uid());

-- invitations: members can see; admins create/revoke. (Redemption uses a SECURITY
-- DEFINER Edge Function, so non-members never need direct SELECT here.)
create policy "invites member read" on public.invitations
  for select using (public.is_family_member(family_id));
create policy "invites admin insert" on public.invitations
  for insert with check (public.is_family_admin(family_id) and auth.uid() = created_by);
create policy "invites admin delete" on public.invitations
  for delete using (public.is_family_admin(family_id));

-- Generic "member of this family" CRUD for content tables.
create policy "posts member read"   on public.posts   for select using (public.is_family_member(family_id));
create policy "posts member insert" on public.posts   for insert with check (public.is_family_member(family_id) and auth.uid() = author_id);
create policy "posts author update" on public.posts   for update using (auth.uid() = author_id or public.is_family_admin(family_id));
create policy "posts author delete" on public.posts   for delete using (auth.uid() = author_id or public.is_family_admin(family_id));

create policy "media member read"   on public.media   for select using (public.is_family_member(family_id));
create policy "media member insert" on public.media   for insert with check (public.is_family_member(family_id));
create policy "media member delete" on public.media   for delete using (public.is_family_member(family_id));

create policy "comments member read"   on public.comments for select using (public.is_family_member(family_id));
create policy "comments member insert" on public.comments for insert with check (public.is_family_member(family_id) and auth.uid() = author_id);
create policy "comments author delete" on public.comments for delete using (auth.uid() = author_id or public.is_family_admin(family_id));

create policy "reactions member read"   on public.reactions for select using (public.is_family_member(family_id));
create policy "reactions member insert" on public.reactions for insert with check (public.is_family_member(family_id) and auth.uid() = user_id);
create policy "reactions self delete"   on public.reactions for delete using (auth.uid() = user_id);

create policy "growth member read"   on public.growth_records for select using (public.is_family_member(family_id));
create policy "growth member insert" on public.growth_records for insert with check (public.is_family_member(family_id) and auth.uid() = author_id);
create policy "growth author update" on public.growth_records for update using (auth.uid() = author_id or public.is_family_admin(family_id));
create policy "growth author delete" on public.growth_records for delete using (auth.uid() = author_id or public.is_family_admin(family_id));

-- subscriptions: a user only ever reads their own. Writes happen via the
-- verify-purchase Edge Function (service role), never from the client.
create policy "subs self read" on public.subscriptions for select using (auth.uid() = user_id);
