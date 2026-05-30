# Pulse & Purpose — Monorepo

This repository contains the Pulse & Purpose marketing site **and** the
**Pulse Family** app — a private family circle for sharing a baby's photos,
videos and growth records (think 亲宝宝, for a worldwide audience).

## Layout

| Path | What |
|------|------|
| [`website/`](website/) | Static marketing site for `pulseandpurpose.net` (HTML + CSS). |
| [`app/`](app/) | Flutter mobile app (Android + iOS). |
| [`backend/`](backend/) | Supabase backend — Postgres schema, RLS, Edge Functions. |
| [`docs/`](docs/) | Architecture & cost notes. |

## Quick start

```bash
# Backend (Postgres + Auth + Storage)
cd backend && supabase start && supabase db reset

# App
cd app && flutter create --org io.pulseandpurpose --project-name pulse_family .
cp .env.example .env            # paste the URL + anon key from `supabase start`
flutter run --dart-define-from-file=.env
```

See [`app/README.md`](app/README.md), [`backend/README.md`](backend/README.md),
and [`docs/architecture.md`](docs/architecture.md) for details.

## Product

A **family circle** owns all content about one baby. Only invited family
members can view or post — enforced by Postgres Row Level Security, not just
the UI. Monetized via in-feed ads (free tier) and a Premium subscription
(ad-free, original quality, growth reports).

## Website hosting

`website/` is served to `pulseandpurpose.net` via GitHub Pages
(`.github/workflows/pages.yml`); `CNAME` lives in `website/`.
