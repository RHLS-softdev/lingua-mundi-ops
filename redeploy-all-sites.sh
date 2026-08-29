#!/usr/bin/env bash
# redeploy-all-sites.sh — redeploys the three launch sites with the brand
# assets (logo/favicon/og-image), SEO tags, and honest copy. Self-alerting:
# prints DONE or FAILED as the final line. Long retry windows for flaky DNS.
set -uo pipefail
W="/home/rex/Documentos/Software Development/DeepSeek Harness"
export GH_TOKEN=$(grep '^GH_TOKEN=' "$W/.env.wire" | cut -d= -f2-)
export PATH="/home/rex/.nvm/versions/node/v24.18.0/bin:$PATH"

cd "$W" || exit 1
run() { # $1=script $2=label
  echo "[redeploy] == $2 =="
  if bash "$W/$1" > "$W/.redeploy-$2.log" 2>&1; then
    echo "[redeploy] OK $2"
  else
    echo "[redeploy] FAILED $2 (see .redeploy-$2.log)"
    tail -5 "$W/.redeploy-$2.log"
  fi
}
run deploy-subtitle-toolkit.sh subtitle
run deploy-kitchenos.sh kitchenos
run deploy-to-github-pages.sh lingua
echo "[redeploy] DONE — all sites redeployed with brand assets + SEO tags"
