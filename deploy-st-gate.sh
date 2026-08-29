#!/usr/bin/env bash
# deploy-st-gate.sh — deploys the Subtitle Toolkit landing+app and then
# verifies the live page is the FIXED single-document version. Prints a
# loud DONE/FAILED alert as the last line. Real exit code preserved.
set -uo pipefail
W="/home/rex/Documentos/Software Development/DeepSeek Harness"
export GH_TOKEN=$(grep '^GH_TOKEN=' "$W/.env.wire" | cut -d= -f2-)

echo "[st-gate] running deploy-subtitle-toolkit.sh"
if ! bash "$W/deploy-subtitle-toolkit.sh" > "$W/.st-deploy.log" 2>&1; then
  echo "[st-gate] FAILED — deploy script exited non-zero. Last log lines:"
  tail -8 "$W/.st-deploy.log"
  exit 1
fi
echo "[st-gate] deploy script exited 0"

echo "[st-gate] waiting 60s for GitHub Pages rebuild..."
sleep 60

LIVE=$(curl -s "https://rhls-softdev.github.io/subtitle-toolkit-launch/")
BYTES=$(printf '%s' "$LIVE" | wc -c)
HTMLS=$(printf '%s' "$LIVE" | grep -c "</html>" || true)
APKS=$(printf '%s' "$LIVE" | grep -c 'id="apk-download"' || true)
echo "[st-gate] live: bytes=$BYTES </html>=$HTMLS apk-download=$APKS"
# structural checks only — byte count varies as legit meta tags are added
if [ "$HTMLS" = "1" ] && [ "$APKS" = "1" ]; then
  echo "[st-gate] DONE — live page is the fixed single-document version"
  exit 0
else
  echo "[st-gate] FAILED — live page still corrupted or not rebuilt"
  exit 1
fi
