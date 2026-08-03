# Pulse and Purpose

The marketing site for Pulse and Purpose — a technology company building cutting-edge AI-powered solutions and meticulously crafted physical products that elevate the enjoyment of every moment. Live the moment. Shape the future.

## Local Preview

Open `index.html` directly in a browser, or serve the folder with any static file server (for example: `python3 -m http.server`).

## NeatRoll routes

- `/neatroll/` is the primary branded landing page and owns the canonical Privacy,
  Terms, Support, and `version.json` URLs.
- `/phototogo/` remains a compatibility copy for older app builds and previously
  published App Store links. Keep it available; its canonical tags point to the
  matching `/neatroll/` pages.
- The NeatRoll landing page intentionally reuses the existing screenshots under
  `/phototogo/img/`. When product or legal copy changes, update both route copies.

## Deploy

This is a fully static site (HTML + CSS only). It is ready for GitHub Pages, Cloudflare Pages, Netlify, Vercel, or any static host. Point your DNS at the host to serve it from `pulseandpurpose.net`.
