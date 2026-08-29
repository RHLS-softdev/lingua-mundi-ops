> 🌐 **Localized:** [English](https://rhls-softdev.github.io/lingua-mundi-launch/?lang=en) · [Español](https://rhls-softdev.github.io/lingua-mundi-launch/?lang=es) · [日本語](https://rhls-softdev.github.io/lingua-mundi-launch/?lang=ja) · [简体中文](https://rhls-softdev.github.io/lingua-mundi-launch/?lang=zh-Hans) · [繁體中文](https://rhls-softdev.github.io/lingua-mundi-launch/?lang=zh-Hant) · [粵語](https://rhls-softdev.github.io/lingua-mundi-launch/?lang=yue) · [हिन्दी](https://rhls-softdev.github.io/lingua-mundi-launch/?lang=hi) · [العربية](https://rhls-softdev.github.io/lingua-mundi-launch/?lang=ar) · [한국어](https://rhls-softdev.github.io/lingua-mundi-launch/?lang=ko)
>
> **Product:** [https://rhls-softdev.github.io/lingua-mundi-launch/](https://rhls-softdev.github.io/lingua-mundi-launch/) — docs, downloads, and Pro/subscription links below.

---

# lingua-mundi-launch — Lingua Mundi launch site + dashboard

GitHub Pages home for the **Lingua Mundi / Shikibu** product family:

- **Shikibu** — Japanese EPUB editor (reading, furigana, annotations;
  Pro = bundled offline dictionary).
- **Lingua Mundi API** — dictionary & linguistic data service backed by
  JMdict, KANJIDIC2, WordNet, J-UniMorph, Wikidata (Phase 0 surface
  frozen — see the Phase 0 freeze doc in the ops repo).

## Contents

- `index.html` / `styles.css` — landing page at the repo root
- `dashboard/` — the commercial dashboard (Clerk + Convex + Stripe:
  plans, API keys, upgrade flow)

## URLs

- Landing: https://rhls-softdev.github.io/lingua-mundi-launch/
- Dashboard: https://rhls-softdev.github.io/lingua-mundi-launch/dashboard/
- Source repos: https://github.com/RHLS-softdev/lingua-mundi · https://github.com/RHLS-softdev/shikibu

## Releases

Each release tag carries the downloadable artifacts:

- `Shikibu-<version>-LinguaMundi-<version>-Japanese.zip` — self-contained
  Shikibu + Lingua Mundi Japanese module (source + prebuilt dist + local DB)
- `Shikibu-<version>-android.apk` — **Android companion app** (EPUB
  reader/annotator; sideload)

## Updating

1. Rebuild the dashboard with the subpath base (`vite build --base=/lingua-mundi-launch/dashboard/`).
2. Run `deploy-to-github-pages.sh` from the ops repo (lingua-mundi-ops).
3. Android APK: `build-android-all.sh` then `deploy-android.sh`.

## Commercial layer

Clerk (accounts) + Convex (accounts/plans/API keys; Stripe webhook is the
only grant path). Live wiring steps in the lingua-mundi repo's
commercial/README.md.
