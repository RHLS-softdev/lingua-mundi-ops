# Agent instructions — lingua-mundi-ops

Operational scripts + release state for the RHLS collection.

## Golden rules (full: DEPLOYMENT-STANDARDS.md)

16. Never silent-fetch + force-push a staged tree. Assert the staged tree
    contains real content before pushing (`assert_source` in
    repair-*-repo.sh); a fetch failure is fatal.
17. Never persist the PAT into `.git/config`. Push with the token inline;
    scrub `x-access-token:github_pat…` from configs after any push.

## Deploying from here

- Launch sites: run `deploy-<product>.sh` (rebuilds with subpath base).
- Android: `build-android-all.sh` then `deploy-android.sh`.
- Commercial wiring: `wire-commercial.sh` (reads `.env.wire`, excluded
  from backups).
