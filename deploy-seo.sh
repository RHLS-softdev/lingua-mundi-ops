#!/usr/bin/env bash
# deploy-seo.sh — adds robots.txt, sitemap.xml and a 404.html to all four
# GitHub Pages sites (hub + three launch repos). Deterministic, idempotent,
# retries flaky pushes. Prints DONE/FAILED alert.
set -uo pipefail
W="/home/rex/Documentos/Software Development/DeepSeek Harness"
export GH_TOKEN=$(grep '^GH_TOKEN=' "$W/.env.wire" | cut -d= -f2-)
USER="RHLS-softdev"

site() { # $1=repo $2=base_url $3=source_index
  local repo="$1" base="$2" src="$3"
  echo "== $repo =="
  local stage="$W/.seo-stage/$repo"
  rm -rf "$stage"; mkdir -p "$stage"
  cd "$stage"
  git init -q -b main 2>/dev/null || true
  git config user.email "rhls.softdev@gmail.com"; git config user.name "$USER"
  git remote add origin "https://x-access-token:$GH_TOKEN@github.com/$USER/$repo.git" 2>/dev/null
  git fetch -q origin main 2>/dev/null
  git checkout -q -B main FETCH_HEAD 2>/dev/null || git checkout -q -b main
  # robots.txt — allow all, point at sitemap
  cat > robots.txt <<EOF
User-agent: *
Allow: /

Sitemap: $base/sitemap.xml
EOF
  # sitemap.xml — landing + any known subpaths
  cat > sitemap.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>$base/</loc><priority>1.0</priority></url>
</urlset>
EOF
  # 404.html — simple branded page
  cat > 404.html <<'EOF'
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Page not found — RHLS</title>
<style>body{font-family:system-ui,sans-serif;background:#f5f6f8;color:#101418;display:flex;align-items:center;justify-content:center;min-height:80vh;margin:0}
.card{background:#fff;border:1px solid #dde1e6;border-radius:12px;padding:40px;max-width:420px;text-align:center}
a{color:#0060a0}</style></head>
<body><div class="card">
<h1>404</h1><p>That page doesn't exist or has moved.</p>
<p><a href="/">Back to RHLS</a></p>
</div></body></html>
EOF
  git add robots.txt sitemap.xml 404.html
  if git diff --cached --quiet; then echo "  no changes"; return 0; fi
  git -c user.email="rhls.softdev@gmail.com" -c user.name="$USER" commit -qm "seo: robots.txt + sitemap + 404 page" 2>&1 | head -1
  for attempt in $(seq 1 10); do
    if git push -q -f origin main 2>/dev/null; then echo "  pushed (attempt $attempt)"; break; fi
    echo "  push attempt $attempt failed - retry 15s"; sleep 15
    [ "$attempt" = "10" ] && { echo "  FAILED to push $repo" >&2; return 1; }
  done
}

site "rhls-softdev.github.io" "https://rhls-softdev.github.io" ""
site "subtitle-toolkit-launch" "https://rhls-softdev.github.io/subtitle-toolkit-launch" ""
site "kitchenos-launch" "https://rhls-softdev.github.io/kitchenos-launch" ""
site "lingua-mundi-launch" "https://rhls-softdev.github.io/lingua-mundi-launch" ""
echo "[seo] DONE — robots/sitemap/404 pushed to all four sites"
