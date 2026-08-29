#!/usr/bin/env bash
# finish-ops-backup.sh — pushes the lingua-mundi-ops backup repo to GitHub,
# retrying on transient network failures until it succeeds (up to 20 tries,
# 20s apart). Prints a clear DONE marker on success.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
: "${GH_TOKEN:?Set GH_TOKEN}"
USER="RHLS-softdev"
REPO="lingua-mundi-ops"
OPS="$ROOT/.ops-final"

echo "[ops-backup] staging files"
rm -rf "$OPS" "$ROOT/.ops-stage" "$ROOT/.ops-stage2"
mkdir -p "$OPS"
cp "$ROOT/finish-release.sh" "$ROOT/deploy-to-github-pages.sh" \
   "$ROOT/backup-to-github.sh" "$ROOT/build-wn-tab.py" \
   "$ROOT/build-merosu-epub.py" "$ROOT/progress.sh" \
   "$ROOT/RESUME-STATE.md" "$OPS/"
cp -r "$ROOT/launch-site" "$OPS/"

for attempt in $(seq 1 20); do
  echo "[ops-backup] attempt $attempt/20"
  code=$(curl -s -H "Authorization: token $GH_TOKEN" -o /dev/null -w "%{http_code}" \
    "https://api.github.com/repos/$USER/$REPO")
  if [ "$code" = "404" ]; then
    echo "[ops-backup] creating repo"
    curl -s -X POST -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/json" \
      "https://api.github.com/user/repos" \
      -d '{"name":"lingua-mundi-ops","description":"Lingua Mundi operational scripts + release state + launch site","private":false}' >/dev/null
    sleep 3
  fi
  cd "$OPS" || exit 1
  git init -q -b main 2>/dev/null || true
  git config user.email "rhls.softdev@gmail.com" >/dev/null 2>&1
  git config user.name "RHLS-softdev" >/dev/null 2>&1
  git add -A >/dev/null 2>&1
  git -c user.email="rhls.softdev@gmail.com" -c user.name="RHLS-softdev" \
    commit -qm "backup: ops scripts + launch site" >/dev/null 2>&1 || true
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$REPO.git"
  if git push -q -f origin main 2>/dev/null; then
    rm -rf "$OPS"
    echo "[ops-backup] SUCCESS on attempt $attempt"
    echo "[ops-backup] DONE - backed up at https://github.com/$USER/$REPO"
    exit 0
  fi
  echo "[ops-backup] push failed (transient network) - retrying in 20s"
  cd "$ROOT" || exit 1
  sleep 20
done
echo "[ops-backup] FAILED after 20 attempts"
exit 1
