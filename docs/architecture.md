# Architecture

## Overview

```
┌────────────────────┐        ┌──────────────────────────────────────┐
│  Flutter app        │        │  Supabase                            │
│  (Android / iOS)    │        │                                      │
│                     │  HTTPS │  ┌────────┐  ┌──────────┐            │
│  Riverpod + go_router├───────►  │  Auth   │  │ Postgres │  RLS       │
│  supabase_flutter   │        │  └────────┘  │ + RLS     │            │
│                     │        │  ┌────────┐  └──────────┘            │
│  MediaStorage iface ├───────►  │ Storage │  ┌──────────────────┐    │
│   (Supabase / R2)   │        │  └────────┘  │ Edge Functions   │    │
│                     │        │              │ redeem-invite    │    │
│                     ├───────►              │ verify-purchase  │    │
└────────────────────┘        │              └──────────────────┘    │
                              └──────────────────────────────────────┘
```

## Access model — "only family can access"

Every content row carries a `family_id`. A SQL helper
`is_family_member(family_id)` (SECURITY DEFINER, so it doesn't recurse through
RLS) is the predicate for nearly every policy. A user sees a post/comment/photo
**iff** they have a row in `family_members` for that family. There is no
app-level filtering that could leak data if a query is written wrong — the
database refuses to return other families' rows.

Joining is the one privileged path: a non-member can't read `invitations`
(RLS blocks it), so `redeem-invite` runs with the service role to validate a
code and insert the membership.

## Data model

See [`backend/README.md`](../backend/README.md). Key tables: `families`,
`family_members`, `posts`, `media`, `comments`, `reactions`, `growth_records`,
`invitations`, `subscriptions`.

## Cost model (media-heavy)

Assuming **20 MB/user/day** uploads:

| | per user |
|---|---|
| Storage growth | 0.6 GB/mo, **7.3 GB/yr** (cumulative) |
| Egress (≈4 family viewers) | ~2.4 GB/mo |

On Supabase Pro ($25/mo; 100 GB storage + 250 GB egress included; overages
$0.021/GB storage, $0.09/GB egress) the marginal cost is **~$0.35–0.5 / paying
user / month**, but storage compounds year over year.

**Egress is the dominant variable cost.** Mitigations, in order of impact:
1. Serve media from **Cloudflare R2** ($0 egress). The app keeps storage behind
   the `MediaStorage` interface so this is a swap, not a rewrite.
2. **Compress + thumbnail** on upload; load thumbnails in the feed, originals
   on demand.
3. Lean on the Storage CDN (cached egress is ~3× cheaper than uncached).

Use the **Pro** plan with the spend cap disabled; Team ($599) only adds
compliance, not cheaper usage.

## Stubs / follow-ups
- AdMob, In-App Purchase + real receipt verification, push notifications,
  growth charts, video transcoding, additional locales.
