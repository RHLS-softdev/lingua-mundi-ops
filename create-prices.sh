#!/usr/bin/env bash
# create-prices.sh — creates the live Stripe prices (if not already set) and
# sets STRIPE_*_PRICE_ID on each Convex deployment. Idempotent: re-running
# keeps existing price IDs. Self-alerting DONE/FAILED.
set -uo pipefail
W="/home/rex/Documentos/Software Development/DeepSeek Harness"
export PATH="/home/rex/.nvm/versions/node/v24.18.0/bin:$PATH"
export CONVEX_AGENT_MODE=anonymous

# load .env.wire without `source` (values contain `|`)
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%$'\r'}"
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$line" ]] && continue
  k="${line%%=*}"; v="${line#*=}"
  [ "$k" = "$line" ] && continue
  export "$k=$v"
done < "$W/.env.wire"
source "$W/.stripe-products.env"

make_price() { # $1=product $2=amount_cents $3=interval(empty=one-time)
  local product="$1" amount="$2" interval="$3"
  local args=(-d "product=$product" -d "unit_amount=$amount" -d "currency=usd")
  [ -n "$interval" ] && args+=(-d "recurring[interval]=$interval")
  curl -s "https://api.stripe.com/v1/prices" -u "$STRIPE_SECRET_KEY:" "${args[@]}" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('id') if 'id' in d else ('ERR: ' + d['error'].get('message','')))"
}

get_env() { # $1=deploy_key $2=var $3=dir -> echoes value (or empty)
  (cd "$3" && export CONVEX_DEPLOY_KEY="$1" && unset CONVEX_DEPLOYMENT && npx convex env list 2>/dev/null | grep "^$2=" | head -1 | cut -d= -f2-)
}
set_env() { # $1=deploy_key $2=var $3=value $4=dir
  (cd "$4" && export CONVEX_DEPLOY_KEY="$1" && unset CONVEX_DEPLOYMENT && npx convex env set "$2" "$3" 2>&1 | tail -1)
}

# create any missing price, else reuse the deployment's existing one
P_ST=$(get_env "$CONVEX_KEY_SUBTITLE" "STRIPE_PRO_PRICE_ID" "$W/.subtitle-toolkit-build")
[ -n "$P_ST" ] || P_ST=$(make_price "$STRIPE_PRODUCT_ST" 900 "")
P_KOS=$(get_env "$CONVEX_KEY_KITCHENOS" "STRIPE_PREMIUM_PRICE_ID" "$W/.kitchenos-build/enterprise")
[ -n "$P_KOS" ] || P_KOS=$(make_price "$STRIPE_PRODUCT_KOS" 5000 "month")
P_LM=$(get_env "$CONVEX_KEY_LINGUA" "STRIPE_PRO_PRICE_ID" "$W/LinguaMundi/lingua-mundi/commercial")
[ -n "$P_LM" ] || P_LM=$(make_price "$STRIPE_PRODUCT_LM" 900 "month")

echo "ST price:  $P_ST"
echo "KOS price: $P_KOS"
echo "LM price:  $P_LM"
[[ "$P_ST" == price_* && "$P_KOS" == price_* && "$P_LM" == price_* ]] || { echo "[prices] FAILED — check plan_write or sk_live_"; exit 1; }

echo "== setting price IDs on deployments =="
set_env "$CONVEX_KEY_SUBTITLE" "STRIPE_PRO_PRICE_ID" "$P_ST" "$W/.subtitle-toolkit-build"
set_env "$CONVEX_KEY_KITCHENOS" "STRIPE_PREMIUM_PRICE_ID" "$P_KOS" "$W/.kitchenos-build/enterprise"
set_env "$CONVEX_KEY_LINGUA" "STRIPE_PRO_PRICE_ID" "$P_LM" "$W/LinguaMundi/lingua-mundi/commercial"
echo "[prices] DONE"
