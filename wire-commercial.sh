#!/usr/bin/env bash
# wire-commercial.sh — deterministic end-to-end commercial wiring (v3).
# Uses Convex deploy keys (CONVEX_DEPLOY_KEY) which work non-interactively,
# never touches `convex init` (no local binary download).
#
# Per product: ensure deployment -> deploy -> set env vars (incl. fixing the
# LM Clerk domain typo + live keys) -> create Stripe webhook endpoint and use
# ITS secret -> update .env.local -> redeploy frontend.
#
# Secrets + deploy keys come from .env.wire (excluded from all backups).
set -uo pipefail

W="/home/rex/Documentos/Software Development/DeepSeek Harness"
export PATH="/home/rex/.nvm/versions/node/v24.18.0/bin:$PATH"
export CONVEX_AGENT_MODE=anonymous

# load .env.wire without `source` (values contain `|` which bash would
# treat as a pipe operator)
load_env() { # $1 = file
  local file="$1" line k v
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%$'\r'}"
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue
    k="${line%%=*}"
    v="${line#*=}"
    [ "$k" = "$line" ] && continue
    export "$k=$v"
  done < "$file"
}
load_env "$W/.env.wire"
: "${STRIPE_SECRET_KEY:?missing}"
: "${GH_TOKEN:?missing}"
: "${CONVEX_KEY_SUBTITLE:?missing}"
: "${CONVEX_KEY_LINGUA:?missing}"
: "${CONVEX_KEY_KITCHENOS:?missing}"

CLERK_DOMAIN="https://loved-gobbler-9439.clerk.accounts.dev"
SUBTITLE_DASHBOARD="https://rhls-softdev.github.io/subtitle-toolkit-launch/app"
KITCHENOS_DASHBOARD="https://rhls-softdev.github.io/kitchenos-launch/premium"
LINGUA_DASHBOARD="https://rhls-softdev.github.io/lingua-mundi-launch/dashboard"
ST_EVENTS="checkout.session.completed"
KOS_EVENTS="checkout.session.completed,customer.subscription.updated,customer.subscription.deleted"

fail() { echo "[wire] ERROR: $*" >&2; exit 1; }
ok()   { echo "[wire] OK: $*"; }

create_webhook() { # $1=url $2=events -> echoes secret
  local url="$1" events="$2"
  local resp
  # deterministic: remove any existing endpoint with the same URL first
  local old_ids
  old_ids=$(curl -s "https://api.stripe.com/v1/webhook_endpoints" -u "$STRIPE_SECRET_KEY:" \
    | python3 -c "import json,sys; u='''$url'''; [print(e['id']) for e in json.load(sys.stdin).get('data',[]) if e.get('url')==u]")
  if [ -n "$old_ids" ]; then
    echo "$old_ids" | while read -r id; do
      curl -s -X DELETE "https://api.stripe.com/v1/webhook_endpoints/$id" -u "$STRIPE_SECRET_KEY:" >/dev/null
      echo "[wire] removed old webhook $id ($url)" >&2
    done
  fi
  resp=$(curl -s "https://api.stripe.com/v1/webhook_endpoints" -u "$STRIPE_SECRET_KEY:" \
    --data-urlencode "url=$url" \
    -d "enabled_events[]=checkout.session.completed" \
    -d "enabled_events[]=customer.subscription.updated" \
    -d "enabled_events[]=customer.subscription.deleted")
  # filter to only the requested events for this product
  local out
  out=$(python3 - "$resp" "$events" <<'PY'
import json,sys
resp, wanted = sys.argv[1], sys.argv[2]
d = json.loads(resp)
if 'error' in d:
    print('ERR:' + d['error'].get('message','')); sys.exit(0)
ev = [e for e in d.get('enabled_events',[]) if e in wanted.split(',')]
print(json.dumps({'id': d['id'], 'secret': d.get('secret',''), 'events': ev, 'url': d.get('url')}))
PY
)
  if [[ "$out" == ERR:* ]]; then echo "[wire] webhook create failed: ${out#ERR:}"; return 1; fi
  python3 -c "import json,sys; print(json.loads('''$out''')['secret'])"
}

wire_by_key() { # $1=app_dir $2=name $3=dashboard $4=events $5=deploy_key $6=extra_env
  local app_dir="$1" name="$2" dashboard="$3" events="$4" deploy_key="$5" extra="$6"
  echo "== [$name] =="
  cd "$app_dir" || fail "no dir $app_dir"
  export CONVEX_DEPLOY_KEY="$deploy_key"
  unset CONVEX_DEPLOYMENT

  # 0. set env vars BEFORE deploy (fresh deployments refuse to deploy
  #    without CLERK_JWT_ISSUER_DOMAIN; idempotent for existing ones)
  npx convex env set CLERK_JWT_ISSUER_DOMAIN "$CLERK_DOMAIN" || fail "$name env CLERK"
  npx convex env set STRIPE_SECRET_KEY "$STRIPE_SECRET_KEY" || fail "$name env STRIPE"
  npx convex env set DASHBOARD_URL "$dashboard" || fail "$name env DASHBOARD"
  if [ -n "$extra" ] && [ -f "$extra" ]; then
    while IFS='=' read -r k v; do
      [ -n "$k" ] && [ -n "$v" ] && npx convex env set "$k" "$v" || true
    done < "$extra"
  fi

  # 1. deploy (fails loudly if anything missing)
  timeout 300 npx convex deploy 2>&1 | tail -4 || fail "$name deploy"

  # 2. webhook secret = the NEW endpoint's own secret (replaces any stale value)
  local url whsec
  # deployment name is encoded in the deploy key: <type>:<name>|<token>;
  # webhook host = the deployment host with .cloud -> .site
  local dep_name
  dep_name=$(cut -d'|' -f1 <<<"$deploy_key" | cut -d: -f2)
  url="https://$dep_name.convex.cloud"
  [ -n "$url" ] || fail "$name: cannot determine convex URL"
  whsec=$(create_webhook "https://$dep_name.convex.site/stripe/webhook" "$events") || fail "$name webhook"
  npx convex env set STRIPE_WEBHOOK_SECRET "$whsec" || fail "$name env WH"
  ok "$name env vars set (webhook secret from new endpoint)"

  # 3. .env.local for the frontend build
  local env_file="$app_dir/.env.local"
  if [ -f "$env_file" ]; then
    sed -i "s|^VITE_CONVEX_URL=.*|VITE_CONVEX_URL=$url|" "$env_file"
  else
    echo "VITE_CONVEX_URL=$url" > "$env_file"
  fi
  echo "$url" > "$W/.convex-url-$name.txt"
  ok "$name .env.local updated -> $url"
}

# ---- Subtitle Toolkit (deployment exists: youthful-ibis-152) ----
wire_by_key "$W/.subtitle-toolkit-build" "Subtitle-Toolkit" "$SUBTITLE_DASHBOARD" "$ST_EVENTS" "$CONVEX_KEY_SUBTITLE" ""

# ---- Lingua Mundi (existing: dusty-turtle-795; fix stale env) ----
wire_by_key "$W/LinguaMundi/lingua-mundi/commercial" "Lingua-Mundi" "$LINGUA_DASHBOARD" "$KOS_EVENTS" "$CONVEX_KEY_LINGUA" "$W/.env.lingua"

# ---- KitchenOS (deployment exists: giddy-condor-179) ----
wire_by_key "$W/.kitchenos-build/enterprise" "KitchenOS" "$KITCHENOS_DASHBOARD" "$KOS_EVENTS" "$CONVEX_KEY_KITCHENOS" ""

echo "== deploying frontends to GitHub Pages =="
cd "$W" || fail "no workspace"
bash deploy-subtitle-toolkit.sh 2>&1 | tail -3
bash deploy-kitchenos.sh 2>&1 | tail -3
bash deploy-to-github-pages.sh 2>&1 | tail -3

echo "[wire] DONE — all three products wired (live keys)."
