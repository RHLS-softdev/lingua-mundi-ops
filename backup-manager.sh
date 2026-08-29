#!/usr/bin/env bash
# ============================================================================
# backup-manager.sh — lightweight encrypted backup manager (seed for a full
# system). Backs up configured SOURCES into The Vault as encrypted archives
# (OpenSSL AES-256-CBC + PBKDF2). Engine is swappable (age/restic later).
#
#   Usage:
#     backup-manager.sh run            # backup all sources (default)
#     backup-manager.sh list           # list existing archives
#     backup-manager.sh verify [file]  # decrypt + validate an archive
#     backup-manager.sh restore <file> [dest]   # decrypt + extract (never overwrites)
#
#   Config (env-overridable): SOURCES, DEST, RETENTION, KEY, LOG
# ============================================================================
set -uo pipefail

VAULT="${VAULT:-$HOME/Descargas/The Vault}"
CONF="${CONF:-$HOME/.config/dsh-backup}"
KEY="$CONF/kb.key"
DEST="${BACKUP_DEST:-$VAULT/_backups/kb}"
RETENTION="${RETENTION:-14}"
LOG="${LOG:-$HOME/.local/state/dsh-backup.log}"

# ── sources: add one line per source to grow the manager ────────────────
SOURCES=(
  "/home/rex/Documentos/Software Development/DeepSeek Harness/Obsidian"     # the knowledge base ("memory")
)

MODE="${1:-run}"
mkdir -p "$CONF" "$DEST" "$(dirname "$LOG")"

log() { printf '%s\n' "$*" | tee -a "$LOG"; }

ensure_key() {
  if [[ ! -f "$KEY" ]]; then
    umask 077
    openssl rand -hex 32 > "$KEY"
    chmod 600 "$KEY"
    log "⚠  Generated new backup key: $KEY"
    log "⚠  COPY THIS KEY SOMEWHERE SAFE (e.g. your phone via Tailscale) — if lost, backups are unrecoverable."
  fi
  [[ -f "$KEY" ]] || { echo "key missing: $KEY"; exit 1; }
}

encrypt_file() { # $1=plain path  $2=cipher path
  openssl enc -aes-256-cbc -pbkdf2 -salt -in "$1" -out "$2" -pass file:"$KEY"
}
decrypt_stream() { # stdin=cipher → stdout=plain
  openssl enc -d -aes-256-cbc -pbkdf2 -pass file:"$KEY"
}

run_backup() {
  ensure_key
  local stamp src base tmp name n lines
  stamp="$(date '+%F-%H%M%S')"
  tmp="$(mktemp)"
  log ""
  log "── backup run $stamp ──"
  for src in "${SOURCES[@]}"; do
    [[ -d "$src" ]] || { log "  skip (missing): $src"; continue; }
    base="$(basename "$src")"
    name="$DEST/$base-$stamp.tar.gz.enc"
    tar -czf "$tmp" -C "$(dirname "$src")" "$base" && \
      encrypt_file "$tmp" "$name"
    n="$(openssl enc -d -aes-256-cbc -pbkdf2 -pass file:"$KEY" -in "$name" 2>/dev/null | tar tz 2>/dev/null | wc -l)"
    if [[ -n "$n" ]] && [[ "$n" -gt 0 ]]; then
      log "  ✓ $base → $name ($n entries, decrypt-verified)"
    else
      log "  ✗ FAILED: $base ($name not verifiable)"
    fi
  done
  rm -f "$tmp"
  # prune: keep the newest RETENTION archives per source
  for base in "${SOURCES[@]}"; do
    local b; b="$(basename "$base")"
    ls -1 "$DEST"/"$b"-*.tar.gz.enc 2>/dev/null | sort -r | tail -n +$((RETENTION + 1)) | while read -r old; do
      rm -f "$old"; log "  pruned: $(basename "$old")"
    done
  done
  log "── backup done ──"
}

case "$MODE" in
  run|backup) run_backup ;;
  list)
    ensure_key
    ls -la "$DEST"/*.tar.gz.enc 2>/dev/null || echo "no archives yet" ;;
  verify)
    ensure_key
    f="${2:-$(ls -1 "$DEST"/*.tar.gz.enc 2>/dev/null | sort -r | head -1)}"
    [[ -n "$f" && -f "$f" ]] || { echo "no archive: $f"; exit 1; }
    echo "Verifying: $(basename "$f")"
    decrypt_stream < "$f" | tar tz 2>/dev/null | head -10
    echo "…entries: $(decrypt_stream < "$f" | tar tz 2>/dev/null | wc -l)" ;;
  restore)
    ensure_key
    f="${2:?usage: backup-manager.sh restore <file> [dest]}"
    dest="${3:-$HOME/restored-$(date +%F)}"
    [[ -f "$f" ]] || { echo "not found: $f"; exit 1; }
    mkdir -p "$dest"
    decrypt_stream < "$f" | tar xz -C "$dest"
    echo "Restored to: $dest" ;;
  *) echo "usage: $0 [run|list|verify [file]|restore <file> [dest]]"; exit 2 ;;
esac
