#!/usr/bin/env bash
# ============================================================================
# calendar-tool.sh — local Evolution calendar helper (GNOME Calendar / Mint)
# Standing user grant: 2026-08-27 (see Obsidian Agent/30-Conventions/Permissions)
#
#   calendar-tool.sh add <title> [YYYY-MM-DD] [HH:MM] [description] [RRULE]
#     (RRULE optional, e.g. "FREQ=DAILY" or "FREQ=WEEKLY;BYDAY=MO,WE,FR")
#   calendar-tool.sh list [--upcoming]
#   calendar-tool.sh search <term>
#   calendar-tool.sh rm <uid>
#   calendar-tool.sh export [out.md]   # render upcoming events → Obsidian mirror (with wikilinks)
#   calendar-tool.sh test          # self-check (add+list+remove a probe event)
#
# Calendar file (canonical): <workspace>/.calendar/dsh-calendar.ics — agent-owned.
# Obsidian mirror: Projects/90-Meta/Calendar.md (regenerated nightly + on change).
# ============================================================================
set -uo pipefail

CAL="${CAL:-/home/rex/Documentos/Software Development/DeepSeek Harness/.calendar/dsh-calendar.ics}"
MODE="${1:-list}"
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

[[ -f "$CAL" ]] || { echo "calendar not found: $CAL"; exit 1; }

case "$MODE" in
  add)
    title="${2:?usage: add <title> [YYYY-MM-DD] [HH:MM] [desc] [RRULE]}"
    day="${3:-$(date -d tomorrow +%Y%m%d)}"
    time="${4:-1800}"
    desc="${5:-}"
    rrule="${6:-}"
    day="$(date -d "$day" +%Y%m%d 2>/dev/null || echo "$day")"
    time="${time//:/}"
    python3 - "$CAL" "$title" "$day" "$time" "$desc" "$rrule" <<'PY'
import sys, uuid, datetime
cal, title, day, t, desc, rrule = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
dtstart = f"{day}T{t}00"; dtend = f"{day}T{int(t)+30:04d}00"
vevent = (f"BEGIN:VEVENT\nUID:{uuid.uuid4()}\nDTSTAMP:{now}\nDTSTART:{dtstart}\n"
          f"DTEND:{dtend}\nSUMMARY:{title}\n")
if desc: vevent += f"DESCRIPTION:{desc}\n"
if rrule: vevent += f"RRULE:{rrule}\n"
vevent += "END:VEVENT\n"
s = open(cal).read()
assert "END:VCALENDAR" in s
open(cal, "w").write(s.replace("END:VCALENDAR", vevent + "END:VCALENDAR"))
print("added:", title, dtstart, ("RRULE:" + rrule) if rrule else "")
PY
    # verify the event stuck (EDS may occasionally rewrite the file)
    if grep -q "$title" "$CAL"; then
      echo "note: if it doesn't appear in GNOME Calendar, restart it (or: evolution --force-shutdown)"
    else
      echo "⚠ event was written but EDS may have reverted it — reopen GNOME Calendar and re-run if missing"
    fi
    ;;
  list)
    python3 - "$CAL" "${2:-all}" <<'PY'
import sys, re
cal, scope = sys.argv[1], sys.argv[2]
s = open(cal).read()
evs = re.findall(r"BEGIN:VEVENT(.*?)END:VEVENT", s, re.S)
if not evs: print("(no events)"); sys.exit(0)
for e in evs:
    uid = re.search(r"UID:(.+)", e); summ = re.search(r"SUMMARY:(.+)", e)
    start = re.search(r"DTSTART[^:]*:(.+)", e)
    print(f"{start.group(1).strip() if start else '?':<17} {summ.group(1).strip() if summ else '?'}  [{uid.group(1).strip() if uid else '?'}]")
PY
    ;;
  search)
    term="${2:?usage: search <term>}"
    python3 - "$CAL" "$term" <<'PY'
import sys, re
cal, term = sys.argv[1], sys.argv[2].lower()
s = open(cal).read()
for e in re.findall(r"BEGIN:VEVENT(.*?)END:VEVENT", s, re.S):
    if term in e.lower():
        uid = re.search(r"UID:(.+)", e); summ = re.search(r"SUMMARY:(.+)", e)
        start = re.search(r"DTSTART[^:]*:(.+)", e)
        print(f"{start.group(1).strip() if start else '?':<17} {summ.group(1).strip() if summ else '?'}  [{uid.group(1).strip() if uid else '?'}]")
PY
    ;;
  rm)
    uid="${2:?usage: rm <uid>}"
    python3 - "$CAL" "$uid" <<'PY'
import sys, re
cal, uid = sys.argv[1], sys.argv[2]
s = open(cal).read()
target = None
for b in re.findall(r"BEGIN:VEVENT.*?END:VEVENT\n?", s, re.S):
    m = re.search(r"UID:([^\s]+)", b)
    if m and m.group(1) == uid:
        target = b
        break
if target is None:
    print("not found:", uid); sys.exit(1)
open(cal, "w").write(s.replace(target, "", 1))
print("removed:", uid)
PY
    ;;
  export)
    out="${2:-}"
    md="$(python3 - "$CAL" <<'PY'
import sys, re, datetime
cal = sys.argv[1]
s = open(cal).read()
evs = []
for e in re.findall(r"BEGIN:VEVENT(.*?)END:VEVENT", s, re.S):
    d = {}
    for k in ("UID", "SUMMARY", "DESCRIPTION"):
        m = re.search(k + r":[^\n]*", e)
        d[k] = m.group(0).split(":", 1)[1].strip() if m else ""
    m = re.search(r"DTSTART[^:]*:(\d{8})T(\d{4})", e)
    if not m: continue
    d["when"] = f"{m.group(1)[:4]}-{m.group(1)[4:6]}-{m.group(1)[6:8]} {m.group(2)[:2]}:{m.group(2)[2:]}"
    d["date"] = m.group(1)[:4] + "-" + m.group(1)[4:6] + "-" + m.group(1)[6:8]
    evs.append(d)
today = datetime.date.today().isoformat()
evs = [e for e in evs if e["date"] >= today]
evs.sort(key=lambda e: e["when"])
def link(desc):
    m = re.search(r"Obsidian\s+([A-Za-z0-9_./ -]+?\.md|[\w-]+)", desc or "")
    if not m: return ""
    name = m.group(1).split("/")[-1].replace(".md", "")
    return f" [[{name}]]"
lines = ["---", "type: index", "tags: [calendar, events]", f"updated: {today}", "source: DSH Calendar (.calendar/dsh-calendar.ics)", "---",
         "# DSH Calendar — upcoming events",
         "_Canonical source: `<workspace>/.calendar/dsh-calendar.ics` (agent-owned). Mirror regenerates nightly + on change._",
         "",
         "| When | Event | Links |", "|---|---|---|"]
if not evs:
    lines.append("| — | *(no upcoming events)* | |")
for e in evs:
    t = e["SUMMARY"].replace("|", "/")
    lines.append(f"| {e['when']} | {t} | {link(e['DESCRIPTION'])} |")
lines.append("")
print("\n".join(lines))
PY
)"
    if [[ -n "$out" ]]; then
      mkdir -p "$(dirname "$out")"
      printf '%s\n' "$md" > "$out"
      echo "mirror written: $out"
    else
      printf '%s\n' "$md"
    fi
    ;;
  test)
    probe="probe-$(date +%s)"
    "$SCRIPT" add "calendar-tool probe" "$(date +%Y-%m-%d)" 1200 "self-test" >/dev/null
    uid=$("$SCRIPT" search probe | grep -oE "\[.*\]" | tr -d '[]' | head -1)
    if [[ -z "$uid" ]]; then echo "self-test FAILED (probe not added)"; exit 1; fi
    "$SCRIPT" rm "$uid" >/dev/null
    if "$SCRIPT" search probe | grep -q probe; then echo "self-test FAILED (probe not removed)"; exit 1; fi
    echo "self-test OK"
    ;;
  *) echo "usage: $0 [add|list|search|rm|test]"; exit 2 ;;
esac
