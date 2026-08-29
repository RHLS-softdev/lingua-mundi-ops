#!/usr/bin/env bash
# backup-to-github.sh — backs up everything to the RHLS-softdev GitHub
# account. Creates three public repos:
#   shikibu           - the Shikibu app source (excl. node_modules/dist/
#                       tsbuildinfo and the 246MB local DB which exceeds
#                       GitHub's 100MB file limit)
#   lingua-mundi      - the Lingua Mundi Python repo (excl. venv/datasets
#                       caches; datasets are >100MB per file and are
#                       re-downloadable)
#   lingua-mundi-ops  - operational scripts + resume checkpoint
# Secrets (tokens/keys/.env/.surge-cred) and caches are NEVER pushed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
: "${GH_TOKEN:?Set GH_TOKEN}"

USER=$(curl -s -H "Authorization: token $GH_TOKEN" https://api.github.com/user | python3 -c "import json,sys; print(json.load(sys.stdin)['login'])")
echo "backing up as $USER"

make_repo() { # $1 = name, $2 = description
  curl -s -X POST -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/json" \
    "https://api.github.com/user/repos" \
    -d "{\"name\":\"$1\",\"description\":\"$2\",\"private\":false}" >/dev/null 2>&1 || true
  echo "repo ready: $1"
}

push_dir() { # $1 = repo name, $2 = source dir, $3 = commit msg
  local repo="$1"
  local src="$2"
  local msg="$3"
  local stage="$ROOT/.backup-stage/$repo"
  rm -rf "$stage"; mkdir -p "$stage"
  # copy with exclusions via rsync-style tar filter
  tar --exclude='*/node_modules' --exclude=./dist --exclude=./tsconfig.tsbuildinfo \
      --exclude=./.npm-cache --exclude=./.pip-cache --exclude=./.chromium-tmp \
      --exclude=./.surge-cred --exclude=./.env.local --exclude=./.env \
      --exclude='./.env.*' --exclude=./.wire-* --exclude=./.convex-url-* \
      --exclude='./.env.wire' --exclude=./.wire-secrets.env \
      --exclude=./android-keys --exclude=./.convex \
      --exclude=./.deliverable-test --exclude=./.deliverable-final \
      --exclude=./.pages-stage --exclude=./.backup-stage \
      --exclude=./venv --exclude=./datasets --exclude=./__pycache__ \
      --exclude=./.pytest_cache --exclude=./.ruff_cache \
      --exclude=./*.egg-info --exclude=./.tmp-wn --exclude=./.aozora \
      --exclude=./.lc-build-test --exclude=./cloudflared \
      --exclude=./public/lingua-mundi-jpn.sqlite \
      --exclude=./.git -C "$src" -cf - . | tar -C "$stage" -xf -
  cd "$stage"
  git init -q -b main 2>/dev/null || true
  git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
  git config http.postBuffer 524288000
  git add -A
  if git diff --cached --quiet; then echo "  (nothing new in $repo)"; cd "$ROOT"; return; fi
  git commit -qm "$msg"
  # rule 17: clean URL in config; token only inline in the push command
  git remote add origin "https://github.com/$USER/$repo.git" 2>/dev/null || \
    git remote set-url origin "https://github.com/$USER/$repo.git"
  for attempt in $(seq 1 10); do
    if git push -q -f "https://x-access-token:$GH_TOKEN@github.com/$USER/$repo.git" main 2>/dev/null; then
      echo "  pushed $repo (attempt $attempt)"
      sed -i 's|x-access-token:github_pat[^@]*@|x-access-token:<rotated>@|g' .git/config 2>/dev/null
      cd "$ROOT"
      return
    fi
    echo "  push attempt $attempt failed (network) - retrying in 15s"
    sleep 15
  done
  echo "  FAILED to push $repo" >&2
  cd "$ROOT"
  return 1
}

make_repo "shikibu" "Shikibu 1.0.0 - Japanese EPUB editor (source backup)"
push_dir "shikibu" "$ROOT/Shikibu" "backup: Shikibu 1.0.0 source"

make_repo "lingua-mundi" "Lingua Mundi 1.0.0 - Japanese module (source backup; datasets/venv excluded - >100MB, re-downloadable)"
push_dir "lingua-mundi" "$ROOT/LinguaMundi/lingua-mundi" "backup: Lingua Mundi source"

make_repo "subtitle-toolkit" "Subtitle Toolkit - SRT tools + Pro (source backup)"
push_dir "subtitle-toolkit" "$ROOT/.subtitle-toolkit-build" "backup: Subtitle Toolkit source"

make_repo "lingua-mundi-ops" "Lingua Mundi operational scripts + release state"
push_dir "lingua-mundi-ops" "$ROOT" "backup: ops scripts + state"

echo
echo "== backup URLs =="
echo "  https://github.com/$USER/shikibu"
echo "  https://github.com/$USER/lingua-mundi"
echo "  https://github.com/$USER/lingua-mundi-ops"
