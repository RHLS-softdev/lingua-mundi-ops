#!/usr/bin/env bash
# repair-source-repos.sh — repairs the source-backup repos that the license
# re-push wiped (shikibu, subtitle-toolkit, kitchenos → 2 files each).
#
# Safety rules (learned the hard way — see DEPLOYMENT-STANDARDS rule 14/16):
#   1. NEVER push -f from a fresh `git init` with a silent-fail fetch.
#   2. ALWAYS verify the staged tree contains real source before pushing.
#   3. Every repo marked "source backup" must contain source (assert).
set -uo pipefail
W="/home/rex/Documentos/Software Development/DeepSeek Harness"
export GH_TOKEN=$(grep '^GH_TOKEN=' "$W/.env.wire" | cut -d= -f2-)
export PATH="/home/rex/.nvm/versions/node/v24.18.0/bin:$PATH"

fail() { echo "[repair] ERROR: $*" >&2; exit 1; }

# Stage the full source tree with the same excludes backup-to-github.sh uses.
stage_source() { # $1=local_dir $2=stage  (copies source, no git yet)
  local dir="$1" stage="$2"
  rm -rf "$stage"; mkdir -p "$stage"
  tar --exclude='*/node_modules' --exclude='*/dist' --exclude='*/target' \
      --exclude='*/build' --exclude='*/venv' --exclude='*/datasets' \
      --exclude='*/__pycache__' --exclude='*/instance' --exclude='*/models' \
      --exclude='*/binaries' --exclude='*/.git' --exclude='*/.env*' \
      --exclude='*/android-keys' \
      --exclude='*/public/lingua-mundi-jpn.sqlite' --exclude='*/public/sql-wasm.wasm' \
      --exclude='*/public/*.sqlite' --exclude='*/gui_assets/*' \
      --exclude='*/tsconfig.tsbuildinfo' --exclude='*/Pamphlet.odt' \
      --exclude='*/linguistic-core/dist' \
      -C "$dir" -cf - . | tar -C "$stage" -xf -
}

# Assert the staged tree actually contains source; refuse otherwise.
assert_source() { # $1=stage $2=repo $3=marker_file
  local stage="$1" repo="$2" marker="$3"
  [ -f "$stage/$marker" ] || fail "$repo: staged tree missing $marker — NOT pushing"
  local n
  n=$(find "$stage" -type f ! -path "*/.git/*" | wc -l)
  [ "$n" -ge 10 ] || fail "$repo: staged tree only has $n files — NOT pushing"
  echo "[repair] $repo: staged $n files incl. $marker — source confirmed"
}

push_stage() { # $1=repo $2=stage $3=msg
  local repo="$1" stage="$2" msg="$3"
  cd "$stage" || return 1
  git init -q -b main 2>/dev/null || true
  git config user.email "rhls.softdev@gmail.com"; git config user.name "RHLS-softdev"
  git config http.postBuffer 524288000
  git config http.lowSpeedLimit 1000
  git config http.lowSpeedTime 600
  # rule 17: clean URL in config; token only inline in the push command
  git remote add origin "https://github.com/RHLS-softdev/$repo.git" 2>/dev/null
  git add -A
  git -c user.email="rhls.softdev@gmail.com" -c user.name="RHLS-softdev" commit -qm "$msg" 2>&1 | head -1
  for attempt in $(seq 1 30); do
    if timeout 300 git push -q -f "https://x-access-token:$GH_TOKEN@github.com/RHLS-softdev/$repo.git" main 2>/dev/null; then
      echo "[repair] OK $repo (attempt $attempt)"
      sed -i 's|x-access-token:github_pat[^@]*@|x-access-token:<rotated>@|g' .git/config 2>/dev/null
      return 0
    fi
    echo "[repair] $repo push attempt $attempt failed - retry 15s"
    sleep 15
  done
  echo "[repair] FAILED $repo"
  return 1
}

# ---- shikibu (full source + ACK + LICENSE) ----
S="$W/.repair-shikibu"
stage_source "$W/Shikibu" "$S"
assert_source "$S" "shikibu" "package.json"
push_stage "shikibu" "$S" "restore: full source (was wiped by license re-push); MIT LICENSE + ACKNOWLEDGEMENTS + UD"

# ---- subtitle-toolkit (full source + LICENSE) ----
S="$W/.repair-subtitle-toolkit"
stage_source "$W/.subtitle-toolkit-build" "$S"
assert_source "$S" "subtitle-toolkit" "package.json"
push_stage "subtitle-toolkit" "$S" "restore: full source (was wiped by license re-push); MIT LICENSE + proprietary convex notice"

# ---- kitchenos (full source + LICENSE; package.json lives in enterprise/) ----
S="$W/.repair-kitchenos"
stage_source "$W/.kitchenos-build" "$S"
assert_source "$S" "kitchenos" "enterprise/package.json"
push_stage "kitchenos" "$S" "restore: full source (was wiped by license re-push); MIT LICENSE + proprietary convex notice"

echo "[repair] DONE — three source repos restored"
