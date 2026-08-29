#!/usr/bin/env bash
# audit-repo-visibility.sh — verifies public/private separation across the
# RHLS-softdev repos:
#  1. every repo + its visibility
#  2. code-search across all repos for secret patterns (token can see private)
#  3. public-repo tree scan for sensitive filenames (.env, keystore, cred, token)
set -uo pipefail
TOKEN="${GH_TOKEN:?Set GH_TOKEN}"
USER="RHLS-softdev"
OUT="$(cd "$(dirname "$0")" && pwd)/repo-audit.out"
: > "$OUT"

echo "===== 1. REPOS + VISIBILITY =====" >> "$OUT"
curl -s -H "Authorization: token $TOKEN" "https://api.github.com/user/repos?per_page=100&sort=updated" \
  | python3 -c "
import json,sys
for r in json.load(sys.stdin):
    vis = 'PRIVATE' if r['private'] else 'public'
    print(f\"{vis:8} {r['name']}\")" >> "$OUT"

echo "" >> "$OUT"
echo "===== 2. CODE-SEARCH: secret patterns (all repos incl. private) =====" >> "$OUT"
search() { # $1 = pattern
  curl -s -m 40 -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/search/code?q=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1")+user:$USER&per_page=20" \
    | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except: print('  (search api error)'); sys.exit()
items=d.get('items',[])
if d.get('message'): print('  api:', d['message'][:70])
for it in items: print(f\"  {it['repository']['name']} -> {it['path']}\")
if not items and not d.get('message'): print('  (no matches)')"
}
for pat in "github_pat_" "ghp_" "sk_live" "sk_test" "sk-or-v1" "gsk_" "AKIA" "whsec_" "BEGIN PRIVATE KEY" "kitos-android" "surge-cred" "Lm1787717939Surge"; do
  echo "-- pattern: $pat" >> "$OUT"
  search "$pat" >> "$OUT"
done

echo "" >> "$OUT"
echo "===== 3. PUBLIC-REPO TREES: sensitive filenames =====" >> "$OUT"
for repo in $(curl -s -H "Authorization: token $TOKEN" "https://api.github.com/user/repos?per_page=100" | python3 -c "
import json,sys
print(' '.join(r['name'] for r in json.load(sys.stdin) if not r['private']))"); do
  curl -s -m 90 -H "Authorization: token $TOKEN" "https://api.github.com/repos/$USER/$repo/git/trees/main?recursive=1" -o "/tmp/tree-$repo.json" 2>/dev/null
  hits=$(grep -oE '"path":"[^"]*(\.env[^/"]*|keystore|\.cred|\.key|secret|token|password)[^"]*"' "/tmp/tree-$repo.json" 2>/dev/null | head -8)
  if [ -n "$hits" ]; then echo "-- $repo:" >> "$OUT"; echo "$hits" | sed 's/^/   /' >> "$OUT"; else echo "-- $repo: clean" >> "$OUT"; fi
done
echo "" >> "$OUT"
echo "audit complete -> $OUT"
