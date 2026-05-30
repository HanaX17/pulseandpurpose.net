# App — Pulse Family (Flutter)

Android + iOS client for the private family photo / growth-sharing app.

## First-time setup

This repo contains the Dart source (`lib/`) and config, but **not** the
generated platform folders (`android/`, `ios/`, etc.). Generate them once:

```bash
cd app
flutter create --org io.pulseandpurpose --project-name pulse_family .
flutter pub get
```

`flutter create .` adds the native scaffolding without touching `lib/`,
`pubspec.yaml`, or `l10n.yaml`.

## Configure & run

```bash
cp .env.example .env          # fill from `supabase start` output
flutter gen-l10n              # generate L10n from lib/l10n/*.arb
flutter run --dart-define-from-file=.env
```

## Project structure (feature-first)

```
lib/
├── main.dart                 # bootstrap + Supabase.initialize
├── app.dart                  # MaterialApp.router + i18n
├── core/
│   ├── env.dart              # --dart-define config
│   ├── supabase.dart         # client + auth providers
│   ├── router.dart           # go_router + auth redirect
│   ├── theme.dart
│   ├── premium/subscription.dart   # entitlement + FeatureGate + IAP stub
│   └── storage/media_storage.dart  # pluggable object store (Supabase / R2)
├── data/
│   ├── models.dart           # data classes
│   └── repository.dart       # all reads/writes + Riverpod providers
├── features/
│   ├── auth/                 # login / signup
│   ├── onboarding/           # create or join a family
│   ├── shell/                # RootGate + bottom-nav MainShell
│   ├── feed/                 # timeline, create post, post detail
│   ├── growth/               # height/weight/milestones
│   ├── family/               # roster + invites
│   ├── premium/              # paywall + ad placeholder
│   └── settings/
└── l10n/                     # app_en.arb / app_zh.arb
```

## Tech
- **Riverpod** for state, **go_router** for navigation.
- **supabase_flutter** for auth/data/storage; RLS scopes data to your family.
- **image_picker** + **cached_network_image** for media.

## Stubs to finish before launch
- **Ads**: `features/premium/ad_banner.dart` is a placeholder — wire `google_mobile_ads`.
- **Purchases**: `paywall_screen.dart` + `verify-purchase` Edge Function are
  stubbed — wire `in_app_purchase`/RevenueCat and real receipt verification.
- **Media cost**: compress + thumbnail on upload; consider Cloudflare R2 for egress.
- **i18n**: `.arb` files exist; swap hard-coded strings for `L10n.of(context)`.
- **Video playback**: `network_media.dart` shows a play badge; add `video_player`.
