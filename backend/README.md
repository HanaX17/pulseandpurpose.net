# Backend — Supabase

Postgres + Auth + Storage + Edge Functions. Access control is enforced entirely
by **Row Level Security**: a row is visible only to members of its `family_id`
(see `is_family_member()` in `0001_init.sql`).

## Layout

```
supabase/
├── config.toml                 # local dev config
├── migrations/
│   ├── 0001_init.sql           # tables, RLS, helper fns, triggers
│   └── 0002_storage.sql        # private `media` bucket + storage policies
├── seed.sql                    # local dev data (mom@ / grandpa@, password123)
└── functions/
    ├── _shared/cors.ts
    ├── redeem-invite/          # join a family via invite code (service role)
    └── verify-purchase/        # STUB: App Store / Play receipt verification
```

## Run locally

```bash
# 1. Install the CLI: https://supabase.com/docs/guides/cli
supabase start                  # boots Postgres, Auth, Storage, Studio
supabase db reset               # applies migrations + seed.sql
supabase functions serve        # serves edge functions locally
```

`supabase start` prints the local **API URL** and **anon key** — copy them into
`app/.env` (see `app/.env.example`).

## Deploy

```bash
supabase link --project-ref <your-project-ref>
supabase db push                # apply migrations to the cloud project
supabase functions deploy redeem-invite verify-purchase
```

## Data model (summary)

| Table | Purpose |
|-------|---------|
| `profiles` | per-user display name / avatar (1-1 with `auth.users`) |
| `families` | one circle per baby |
| `family_members` | membership + role (`owner`/`admin`/`member`) + relation |
| `invitations` | shareable join codes |
| `posts` / `media` | timeline entries and their photos/videos |
| `comments` / `reactions` | 留言 + 点赞 |
| `growth_records` | height / weight / milestones |
| `subscriptions` | premium state (written only by `verify-purchase`) |

## Media storage & cost note

`0002_storage.sql` provisions a private Supabase Storage bucket. Authorization
reuses `is_family_member()` keyed on the first path segment (`{family_id}/...`).

For a view-heavy media app, **egress is the dominant variable cost** on Supabase
($0.09/GB uncached). For production scale, serving media from **Cloudflare R2**
(\$0 egress, ~\$0.015/GB storage) is materially cheaper. The Flutter app keeps
the storage layer behind a `MediaStorage` interface (`app/lib/core/storage/`) so
you can switch the backing store without touching feature code. Always compress
images and generate thumbnails on upload to cut both storage and egress.
