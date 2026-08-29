# lingua-mundi-ops

Operational scripts + release state for the RHLS software collection
(Lingua Mundi, Shikibu, Subtitle Toolkit, KitchenOS).

- **Deploy**: `deploy-*.sh` (landing + app/dashboard to GitHub Pages),
  `deploy-android.sh` (APK release assets), `deploy-st-gate.sh`
  (validated Subtitle Toolkit deploy).
- **Backup**: `backup-to-github.sh` (source repos, secrets excluded),
  `backup-subtitle-toolkit.sh`, `backup-kitchenos.sh`.
- **Audit**: `audit-links.sh`, `audit-repo-visibility.sh`.
- **Wiring**: `wire-commercial.sh` (Convex/Clerk/Stripe), `create-prices.sh`,
  `verify-wiring.sh` — see `WIRING-GUIDE.md` (technical) and
  `WIRING-GUIDE-SIMPLE.md` (plain English).
- **Repair**: `repair-source-repos.sh`, `repair-ops-repo.sh`.
- **Docs**: `DEPLOYMENT-STANDARDS.md` (golden rules incl. 16-17),
  `AUDIT-STATUS-REPORT.md`, `STRIPE-TASKS.md`.
- **Landing source**: `launch-site/` (Lingua Mundi / Shikibu landing).

See `AGENTS.md` for agent instructions.
