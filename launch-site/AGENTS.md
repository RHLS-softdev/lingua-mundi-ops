# Agent instructions — lingua-mundi-launch

Static GitHub Pages site for **Lingua Mundi / Shikibu** (live at
https://rhls-softdev.github.io/lingua-mundi-launch/).

## What lives here

- `index.html` / `styles.css` — the landing page (repo root)
- `dashboard/` — the **built** commercial dashboard (served at
  `/dashboard/`), built with the subpath base
  `/lingua-mundi-launch/dashboard/`
- `README.md` — human + agent entry point
- Releases carry the Shikibu ZIP and the Android APK

## Rules for agents

- Build output + landing content only — never hand-edit `dashboard/`.
  Dashboard source: `RHLS-softdev/lingua-mundi` (`commercial/`); landing
  source: `launch-site/` in `lingua-mundi-ops`.
- Update via `deploy-to-github-pages.sh` from `lingua-mundi-ops`.
- The dashboard registers its origin in Clerk when `CLERK_SECRET_KEY` is
  set; do not bypass that.

## Related

`lingua-mundi` + `shikibu` (sources) · `lingua-mundi-ops` (deploy scripts).
