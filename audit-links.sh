#!/usr/bin/env bash
# audit-links.sh — verifies every link across the hub, the product sites,
# and the repo READMEs. Broken links are printed with their source page.
set -uo pipefail
OUT="$(cd "$(dirname "$0")" && pwd)/link-audit.out"
: > "$OUT"
declare -A SEEN
BROKEN=0

check() { # $1 = url, $2 = origin page
  local url="$1" src="$2"
  case "$url" in
    mailto:*|tel:*|"#"*) return 0 ;;
  esac
  if [ -n "${SEEN[$url]:-}" ]; then return 0; fi
  SEEN["$url"]=1
  local code
  code=$(curl -sL -o /dev/null -w "%{http_code}" -m 25 "$url" 2>/dev/null)
  case "$code" in
    200|302|301|304) : ;;
    *) echo "BROKEN ($code) $url   <= $src" >> "$OUT"; BROKEN=$((BROKEN+1)) ;;
  esac
}

scan_html() { # $1 = page url
  local page="$1" html
  html=$(curl -s -m 30 "$page" 2>/dev/null)
  local base="${page%/*}"
  while IFS= read -r href; do
    case "$href" in
      mailto:*|tel:*|"#"*) continue ;;
      http*) check "$href" "$page" ;;
      /*) check "https://rhls-softdev.github.io$href" "$page" ;;
      *) check "${base}/${href}" "$page" ;;
    esac
  done < <(echo "$html" | grep -oE '(href|src)="[^"]+"' | sed -E 's/^(href|src)="//; s/"$//' | sort -u)
  # also catch URLs embedded in <script> blocks (const X = "https://...")
  while IFS= read -r jsurl; do
    case "$jsurl" in
      mailto:*|tel:*|"#"*) continue ;;
      *) check "$jsurl" "$page (script)" ;;
    esac
  done < <(echo "$html" | grep -oE 'https?://[a-zA-Z0-9./_-]+\.(com|dev|io|cloud|net|org|app)[a-zA-Z0-9./_?=&-]*' | sort -u)
}

# 1) live sites
for page in \
  "https://rhls-softdev.github.io/" \
  "https://rhls-softdev.github.io/subtitle-toolkit-launch/" \
  "https://rhls-softdev.github.io/subtitle-toolkit-launch/app/" \
  "https://rhls-softdev.github.io/kitchenos-launch/" \
  "https://rhls-softdev.github.io/kitchenos-launch/premium/" \
  "https://rhls-softdev.github.io/lingua-mundi-launch/" \
  "https://rhls-softdev.github.io/lingua-mundi-launch/dashboard/"; do
  echo "== $page" >> "$OUT"
  scan_html "$page"
done

# 2) repo READMEs (localized bars + product links)
for repo in lingua-mundi shikibu lingua-mundi-launch lingua-mundi-ops subtitle-toolkit subtitle-toolkit-launch kitchenos kitchenos-launch; do
  readme=$(curl -s -m 30 "https://raw.githubusercontent.com/RHLS-softdev/$repo/main/README.md" 2>/dev/null)
  while IFS= read -r link; do
    case "$link" in
      http*) check "$link" "$repo README" ;;
    esac
  done < <(echo "$readme" | grep -oE '\]\(https?://[^)]+\)' | sed -E 's/^\]\(//; s/\)$//' | sort -u)
done

echo "== done — broken: $BROKEN" >> "$OUT"
echo "link audit complete — broken: $BROKEN (details in link-audit.out)"
