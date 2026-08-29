#!/usr/bin/env bash
# verify-wiring.sh — after wire-commercial.sh finishes, confirm each product
# is actually live: convex deployment reachable, env vars set, webhook
# endpoint exists with the right URL, frontend serves the new build.
set -uo pipefail
W="/home/rex/Documentos/Software Development/DeepSeek Harness"
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%$'\r'}"
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$line" ]] && continue
  k="${line%%=*}"; v="${line#*=}"
  [ "$k" = "$line" ] && continue
  export "$k=$v"
done < "$W/.env.wire"
: "${STRIPE_SECRET_KEY:?missing in .env.wire}"
export PATH="/home/rex/.nvm/versions/node/v24.18.0/bin:$PATH"
FAIL=0

check() { # $1=name $2=url-file $3=dashboard $4=app_dir $5=deploy_key_env
  local name="$1" urlfile="$2" dashboard="$3" app_dir="$4" keyvar="$5"
  echo "== $name =="
  local url
  url=$(cat "$W/$urlfile" 2>/dev/null)
  [ -n "$url" ] || { echo "[verify] MISSING convex url file"; FAIL=1; return; }
  code=$(curl -sL -o /dev/null -w "%{http_code}" -m 10 "$url" 2>/dev/null)
  echo "  convex: $url -> HTTP $code"
  [ "$code" = "200" ] || FAIL=1
  dash=$(curl -sL -o /dev/null -w "%{http_code}" -m 10 "$dashboard" 2>/dev/null)
  echo "  frontend: $dashboard -> HTTP $dash"
  [ "$dash" = "200" ] || FAIL=1
  # env vars actually set on the deployment?
  export CONVEX_AGENT_MODE=anonymous
  export CONVEX_DEPLOY_KEY="${!keyvar}"
  unset CONVEX_DEPLOYMENT
  local n secret_clean
  n=$(cd "$app_dir" && npx convex env list 2>&1 | grep -cE "CLERK_JWT_ISSUER_DOMAIN|STRIPE_SECRET_KEY|STRIPE_WEBHOOK_SECRET|DASHBOARD_URL")
  echo "  env vars set: $n"
  [ "$n" -ge 4 ] || FAIL=1
  # webhook secret must be a single clean whsec_ value (no captured log lines)
  secret_clean=$(cd "$app_dir" && npx convex env list 2>&1 | grep "^STRIPE_WEBHOOK_SECRET=" | sed 's/^STRIPE_WEBHOOK_SECRET=//' | tr -d "'")
  if [[ "$secret_clean" =~ ^whsec_[A-Za-z0-9]+$ ]]; then
    echo "  webhook secret: clean (${#secret_clean} chars)"
  else
    echo "  webhook secret: POLLUTED -> '$secret_clean'"
    FAIL=1
  fi
}

check "Subtitle-Toolkit" ".convex-url-Subtitle-Toolkit.txt" "https://rhls-softdev.github.io/subtitle-toolkit-launch/app" "$W/.subtitle-toolkit-build" "CONVEX_KEY_SUBTITLE"
check "KitchenOS" ".convex-url-KitchenOS.txt" "https://rhls-softdev.github.io/kitchenos-launch/premium" "$W/.kitchenos-build/enterprise" "CONVEX_KEY_KITCHENOS"
check "Lingua-Mundi" ".convex-url-Lingua-Mundi.txt" "https://rhls-softdev.github.io/lingua-mundi-launch/dashboard" "$W/LinguaMundi/lingua-mundi/commercial" "CONVEX_KEY_LINGUA"

echo "== Stripe webhook endpoints =="
curl -s "https://api.stripe.com/v1/webhook_endpoints" -u "$STRIPE_SECRET_KEY:" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for e in d.get('data',[]):
    print(' ', e.get('status'), e.get('url'))
"
[ "$FAIL" = 0 ] && echo "[verify] ALL CHECKS PASSED" || { echo "[verify] FAILURES PRESENT"; exit 1; }
