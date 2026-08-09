# Pulse and Purpose

The marketing site for Pulse and Purpose — a technology company building cutting-edge AI-powered solutions and meticulously crafted physical products that elevate the enjoyment of every moment. Live the moment. Shape the future.

## Local Preview

Open `index.html` directly in a browser, or serve the folder with any static file server (for example: `python3 -m http.server`).

## App routes

The iOS app is **TidyTidy**. It shipped as **PhotoToGo** through version 2.1; an
intermediate **NeatRoll** rename was abandoned and never shipped in any build.

- `/tidytidy/` is the canonical branded landing page and owns the Privacy, Terms,
  Support and `version.json` URLs used by the app from version 2.2 onward. It is
  self-contained (its own `img/`).
- `/phototogo/` **must stay online and must stay PhotoToGo-branded**: the live 2.1
  build hardcodes these URLs, so anyone who has not updated still reads them. Its
  canonical tags point at the matching `/tidytidy/` pages.
- `/neatroll/` is redirect-only (meta refresh + canonical + `noindex`) to
  `/tidytidy/`. No build ever pointed at it; the stubs exist purely because the
  pages were briefly published and may have been indexed or linked.
- `version.json` is **not** an App Store Connect field — it is fetched at launch by
  `UpdateNudgeManager` in the app and must return HTTP 200, because the check is
  fail-open and a 404 silently disables the in-app update prompt forever.

When product or legal copy changes, update `/tidytidy/` and `/phototogo/` together.

## Deploy

This is a fully static site (HTML + CSS only). It is ready for GitHub Pages, Cloudflare Pages, Netlify, Vercel, or any static host. Point your DNS at the host to serve it from `pulseandpurpose.net`.
