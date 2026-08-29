#!/usr/bin/env bash
# create-knowledge-base.sh — one-shot bootstrap of 3 Obsidian vaults + 6pm reminder
set -uo pipefail

KB="$HOME/Documentos/Obsidian"
mkdir -p "$KB"

# ============================================================================
# shared frontmatter schema (also documented in Agent vault)
# type: person|system|project|idea|agent|index|template
# created/updated: YYYY-MM-DD · source: where it came from · verified: bool
# ============================================================================

write_note() { # $1=abs path  $2=content
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" > "$1"
}

# ═══════════════════════════════════════════════════════════════════════════
# VAULT 1 — USER  (about rex)
# ═══════════════════════════════════════════════════════════════════════════
U="$KB/User"; mkdir -p "$U/10-Identity" "$U/20-System" "$U/30-Work" "$U/40-Health" "$U/90-Meta"

write_note "$U/Home.md" '---
type: index
tags: [moc, user]
created: 2026-08-26
source: session
---
# User Knowledge — Home

Everything known about **rex** (Raciel Hernández Hernández). *This is the map; notes hold the detail.*

## Identity
- [[Identity]] — who they are, accounts, handles
- [[Preferences]] — how they like to work

## System
- [[Computer]] — hardware + OS facts
- [[System-Setup]] — what has been configured/changed and why
- [[Vault-Layout]] — The Vault + nightly pipeline + Jellyfin

## Work & Life
- [[Work]] — teaching, translation, Japanese
- [[Health]] — *mostly empty; user should fill in*

## Meta
- Convention schema: [[Conventions]] (in the Agent vault)
- Template: [[Note-Template]]

```dataview
TABLE type, updated, verified FROM "User" WHERE type != "index"
```
'

write_note "$U/10-Identity/Identity.md" '---
type: person
tags: [identity, person]
created: 2026-08-26
source: session-2026-08-26 (CV file, system scans, tailscale)
verified: true
---
# Identity

| Field | Value |
|---|---|
| Full name | **Raciel Hernández Hernández** (from `CV - Raciel Hernández Hernández [2026] [EN].pdf`) |
| Handle / user | `rex` |
| PC hostname | `rhls-asus` (ASUS, Atom Bay Trail) |
| Tailscale account | `racielhernandezhdez@` |
| Languages | Spanish (system locale, native); communicates in English; studies Japanese |
| Location | Mexico timezone (CST) |

## Notes
- Runs an old ASUS Atom machine as their daily driver — token/CPU/IO efficiency matters to them.
- Asked for clickable checklists; prefers reviewing plans before execution.
- Values honesty about limitations (see [[Preferences]]).
'

write_note "$U/10-Identity/Preferences.md" '---
type: person
tags: [preferences, workflow]
created: 2026-08-26
source: session-2026-08-26 (explicit statements)
verified: true
---
# Preferences

- **Token-conscious**: repeatedly asks to minimize token waste; wants strategy first, short outputs, no full listings.
- **Checklists**: wants clickable, reviewable checklists to choose from; nothing implemented without consent.
- **Plan-then-act**: approves a strategy before execution.
- **Honesty**: appreciates when limits are stated plainly (e.g. "this repo is 9 days old", "I verified X not Y").
- **Verification**: likes proof (exit codes, before/after, sources cited).
- **"Adjust on the fly"**: OK with the agent fixing things mid-run when needed.
- Not interested in over-engineering (e.g. declined Steven Universe renumbering; "pick whatever is easiest").
'

write_note "$U/20-System/Computer.md" '---
type: system
tags: [hardware, os, computer]
created: 2026-08-26
source: live scans 2026-08-26 (lscpu, /proc/meminfo, lsblk, dmidecode-equivalents)
verified: true
---
# Computer

## Hardware
- **CPU**: Intel Atom Bay Trail Z36xx/Z37xx, 4 cores (≈2014 era, low-power) — max ~2.66 GHz
- **RAM**: 8 GB (likely soldered; platform max — not upgradeable)
- **Disk**: 1× 931 GB mechanical HDD (`/dev/sda`) — the bottleneck; no SSD
- **GPU**: Intel Atom integrated graphics (Bay Trail); hardware accel OK (no llvmpipe)
- **Thermals**: 70–73 °C typical — warm; dust/thermal-paste refresh suggested
- **Network**: Wi-Fi; now on Tailscale tailnet

## OS
- **Linux Mint 22.3 (Zena)**, Ubuntu 24.04 (noble) base
- **Kernel**: 6.14.0-37-generic
- Desktop: Cinnamon

## Storage layout
- `/` = `/dev/sda2` (ext4, 916G, ~33% used at scan time)
- `/boot/efi` = `/dev/sda1`
- Swap: `/swapfile` (2 GB) + zram (zramswap active)
- Mount flags: `noatime` added to `/` in fstab

## Performance notes
- Boot was 5 min 35 s before cleanup; heavy services removed (see [[System-Setup]])
- Load/IO-bound; memory pressure handled via zram + earlyoom
'

write_note "$U/20-System/System-Setup.md" '---
type: system
tags: [setup, services, security]
created: 2026-08-26
source: session-2026-08-26 (applied changes + verification)
verified: partial
---
# System Setup

## Applied (verified 2026-08-26)
- **zram** active (zramswap service); compressed RAM swap to reduce HDD swap
- **earlyoom** installed + running — prevents freezes when RAM is exhausted
- **Services disabled**: docker, containerd, postgresql, ModemManager, smbd/nmbd/samba-ad-dc, avahi-daemon, cups-browsed, bluetooth, sssd (masked), openvpn, irqbalance, NetworkManager-wait-online, accounts-daemon, fstrim.timer
- **casper/ubiquity** (live-installer leftovers) purged
- **Swappiness** file written to `vm.swappiness=10` → *note: runtime value was still 60 at last check; apply with `sudo sysctl --system` or reboot (if zram active, 100 is recommended)*
- **Journal** vacuumed (≈950 MB freed); limit.conf suggested but *write failed initially — verify*
- **noatime** on `/` (fstab + remount pending)
- **Old kernels**: 13 installed — cleanup advised via Mint Update Manager (status: todo)
- **Timeshift**: daily 08:00 snapshots (~30 GB) — keep, consider retention tuning

## Network / remote access
- **Tailscale** on PC (`rhls-asus` → 100.106.59.55) + phone (`z2356` → 100.126.224.115)
- `tailscale serve --https=443 127.0.0.1:3080` → **https://rhls-asus.tail8b43b4.ts.net**
- `dsh web` must run with `--trusted-host rhls-asus.tail8b43b4.ts.net` (Host-header fence; full FQDN required)
- DSH privileged methods (Settings, API keys, `host.pickDirectory`) are **loopback-only by design** — remote workspace creation/settings 403 intentionally

## Media stack
- **Jellyfin**: Flatpak Server 10.11.11 + Desktop; libraries: Movies, Stand-up, TV Shows (+Cartoons), Anime — all pointed at The Vault (see [[Vault-Layout]])
- Metadata provider: TMDB (works keyless; TVDB needs an API key)

## Untouched by design
- Active dictionary pipeline files in `~/` (see Projects → [[Dictionary-Pipeline]])
- Secrets (`~/Documentos/API keys`, `groq key`) — never moved/synced
'

write_note "$U/20-System/Vault-Layout.md" '---
type: system
tags: [vault, pipeline, jellyfin]
created: 2026-08-26
source: session-2026-08-26
verified: true
---
# The Vault — layout & automation

**Location**: `~/Descargas/The Vault` (≈52 GB+; syncs to user personal server)

## Categories
Movies · Shows · Anime · Cartoons · Standup Specials · Music · Books · Manga · Fonts · Code · Teaching · Files (Images/PDFs/Subtitles/Web pages) · Downloads · Software · Miscellaneous · `_alt` (parked dupes) · `_media-junk`

## Nightly pipeline (03:00 systemd user timer)
`vault-nightly.sh` → 1) classify Inbox → 2) Jellyfin video naming → 3) books/manga prep → 4) missing-media report
- **Inbox**: `~/Descargas/Inbox` — drop finished downloads here
- **Missing report**: `vault-missing.txt` (per-series episode/volume gaps)
- Scripts live in `~/Documentos/Software Development/DeepSeek Harness/` (see Agent → [[Scripts]])

## Jellyfin libraries
Movies → `Vault/Movies` · Stand-up → `Vault/Standup Specials` (type Movies) · TV Shows → `Vault/Shows` + `Vault/Cartoons` · Anime → `Vault/Anime`

## Open items
- Phone files organization (reminder 2026-08-26 18:00) → [[../Projects/20-Backlog/Phone-Files]]
- Missing media (Steven Universe S3/S4/S5, Dr. Stone, Witch Hat, etc.) → [[../Projects/10-Active/Vault-Missing]]
'

write_note "$U/30-Work/Work.md" '---
type: person
tags: [work, teaching, translation, japanese]
created: 2026-08-26
source: session-2026-08-26 (file inventories, teaching materials)
verified: true
---
# Work

## English teaching
- Teaches English (student **Jocelyn** — lessons `Jocelyn *.odp/html/ppt` in Vault/Teaching)
- **Oxford / American English File** materials (Level 1 in Vault/Teaching/Actividades Oxford)
- Grammar Spectrum levels 1–3 complete

## Translation / linguistics
- Translation studies background (e.g. Cronin *Translation in the Digital Age*, AUSTERMÜHL, "Multilingual Lexical Platform" spec)
- **Dictionary pipeline** project (Japanese/OMW/kanji) — see Projects → [[Dictionary-Pipeline]]

## Japanese studies
- Kanji/dictionary data: `kanjidic2.xml`, `joyo_kanji.json`, `omw_multilingual.json` (in `~/`)
- Textbooks: Minna no Nihongo Shokyu I, Japanese Picture Dictionary, 高校入試 国語...
- Reads Japanese media (Witch Hat Atelier, Kakushite, Dr. Stone, Kusuriya no Hitorigoto — 14 vols in Vault/Books)

## Other
- Game dev hobby: Godot projects (catkart, catraft…) — see Projects → [[Godot-Games]]
- Print-on-demand design work ("Diseños para POD" archive)
'

write_note "$U/40-Health/Health.md" '---
type: person
tags: [health]
created: 2026-08-26
source: unknown
verified: false
---
# Health

> **Placeholder.** Nothing is known yet — this section is intentionally empty rather than invented.

Things that would be useful here (only if the user wants to share):
- Any ongoing conditions / considerations
- Ergonomic setup notes (long sessions on an old laptop?)
- Anything the agent should factor into how it works with them

*Mark `verified: true` and fill content when the user provides it.*
'

write_note "$U/90-Meta/Note-Template.md" '---
type: template
tags: [template]
---
---
type: <person|system|project|idea|agent|index>
tags: [tag1, tag2]
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
source: <session id | scan | web (url) | user-stated | inferred>
verified: <true|false|partial>
confidence: <high|medium|low>
related: ["[[Note]]"]
---
# Title

Body. **Provenance rule**: state where every fact came from; prefer [[wikilinks]] over repeated text.
'

# ═══════════════════════════════════════════════════════════════════════════
# VAULT 2 — PROJECTS  (things to do, not things that are)
# ═══════════════════════════════════════════════════════════════════════════
P="$KB/Projects"; mkdir -p "$P/10-Active" "$P/20-Backlog" "$P/30-Ideas" "$P/90-Meta"

write_note "$P/Home.md" '---
type: index
tags: [moc, projects]
created: 2026-08-26
source: session
---
# Projects — Home

**Things to do, not things that are.** Every note = one project/idea with a next action.

## Active
- [[Vault-Organization]] — the media/books pipeline (mostly done, ongoing)
- [[Dictionary-Pipeline]] — Japanese/OMW/kanji work (in `~/`, untouched by design)
- [[Jellyfin-Setup]] — libraries live; missing content to fetch

## Backlog
- [[Phone-Files]] — organize phone files like the Vault ⏰ *reminder 2026-08-26 18:00*
- [[Vault-Missing]] — incomplete series/books to download
- [[KitchenOS]] — audit/fixes project
- [[Godot-Games]] — game dev ideas

## Ideas
- [[Ideas]]

```dataview
TABLE status, updated FROM "Projects" WHERE type = "project" OR type = "idea"
```
'

write_note "$P/90-Meta/Project-Template.md" '---
type: template
tags: [template]
---
---
type: project
status: <idea|backlog|active|paused|done>
tags: []
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
source:
verified:
next-action: <one concrete next step>
---
# Title

## Goal
## Context / history
## Next actions
- [ ] 
## References
'

write_note "$P/10-Active/Vault-Organization.md" '---
type: project
status: active
tags: [vault, automation]
created: 2026-08-26
source: session-2026-08-26
verified: true
next-action: Decide phone-folder sync mechanism (Termux+sshfs vs Syncthing)
---
# Vault Organization

## Goal
Keep `~/Descargas/The Vault` automatically sorted: media in Jellyfin structure, books/manga organized, duplicates parked.

## Done (2026-08-26)
- Classified ~318 loose files into vault categories
- Jellyfin naming for 240+ videos; books/manga prep; subtitle packs distributed
- Nightly pipeline (03:00): Inbox → classify → Jellyfin → books/manga → missing report
- Scripts: `organize-vault.sh`, `jellyfin-prep.sh`, `books-prep.sh`, `vault-missing.sh`, `vault-nightly.sh`

## Next actions
- [ ] Phone files: choose mechanism (Termux+sshfs recommended; Syncthing if background sync preferred) — reminder 18:00
- [ ] Optionally add phone mount sweep to nightly pipeline
- [ ] Steven Universe TVDB renumbering — *user declined; do not pursue unless asked*

## References
- Agent → [[Scripts]], [[Conventions]]
'

write_note "$P/10-Active/Dictionary-Pipeline.md" '---
type: project
status: active
tags: [japanese, dictionary, nlp]
created: 2026-08-26
source: session-2026-08-26 (file inventory; user decision)
verified: true
next-action: None (user chose to leave in place) — resume only when user initiates
---
# Dictionary Pipeline

Japanese/OMW/kanji lexical data work. **User decision: keep in `~/`, unrenamed, untouched by automation.**

## Files (in `~/`, excluded from vault moves)
- Scripts: `extract_omw.py`, `extract_omw_sqlite.py`, `crossref_deterministic.py`, `merge_dicts.py`, `stage14_tune_guitar.py`, `unified_dictionary_pipeline.py`
- Data: `kanjidic2.xml`, `joyo_kanji.json`, `joyo_list.txt`, `omw_multilingual.json`, `json`, `rc.name AS source_name,`
- Figures: `Figure_1..11.png`
- Related docs: `analysis.txt`, `knowledge project.txt`, "Multilingual Lexical Platform — Engineering Specification (Notion).pdf"

## Related
- User studies Japanese (see User → [[Work]])
'

write_note "$P/10-Active/Jellyfin-Setup.md" '---
type: project
status: active
tags: [jellyfin, media]
created: 2026-08-26
source: session-2026-08-26
verified: true
next-action: None blocking — libraries live; fetch missing media when desired
---
# Jellyfin Setup

Flatpak server (10.11.11) + Desktop on rhls-asus; libraries:
Movies · Stand-up · TV Shows (+Cartoons) · Anime → all from The Vault.

## Notes
- TMDB provider (keyless) — matches current numbering (Steven Universe packs use TMDB order; no renumber needed)
- Comic Vine key optional for CBZ metadata
- Access from phone via Tailscale serve (see User → [[System-Setup]])

## Related
- [[Vault-Missing]] — what content is incomplete
'

write_note "$P/20-Backlog/Phone-Files.md" '---
type: project
status: backlog
tags: [phone, organization]
created: 2026-08-26
source: session-2026-08-26
verified: true
next-action: Set up Termux+sshd on phone; sshfs mount on PC; then run organize-vault.sh with SRC_ONLY
---
# Phone Files

Give the agent phone files to organize like The Vault.

## Plan (agreed 2026-08-26)
1. Phone: **Termux** → `pkg install openssh`, `passwd`, `sshd` (port 8022)
2. PC: `sudo apt install sshfs`; `sshfs <user>@100.126.224.115:/sdcard ~/phone -p 8022`
3. Agent runs `SRC_ONLY=~/phone/...` organize-vault.sh
4. Open question: mostly photos? → dedicated `Files/Phone photos/` bucket
5. Optional: nightly sweep of phone mount → Inbox

## ⏰ Reminder
systemd one-shot timer **2026-08-26 18:00** (`reminder-phone-files.timer`) — revisit this task.
'

write_note "$P/20-Backlog/Vault-Missing.md" '---
type: project
status: backlog
tags: [media, downloads]
created: 2026-08-26
source: session-2026-08-26 (vault-missing.sh output)
verified: true
next-action: Decide which gaps to fetch (SU S5 finale, MAWS S3E10, Dr. Stone manga vols)
---
# Missing Media

Auto-tracked nightly in `vault-missing.txt`. As of 2026-08-26:

## TV/Anime
- My Adventures with Superman S03E10
- Avatar: The Last Airbender (2024) S02E08
- Steven Universe S3 (E01-02, E25), S4 (E01-10, E25), S5 (E29 — series finale)
- The Rookie: only S01E01
- Dr. Stone S4: only E12-13 (of 36)
- Witch Hat Atelier: only E12-13 (of 24)

## Books/Manga
- Dr. Stone manga: 2/24 volumes (folder claims v01-24)
- Kusuriya no Hitorigoto: 14/17 vols
- Korean Made Simple: 1/3
- American English File: Level 1 of 5 · Minna no Nihongo: Shokyu I only

## Related
- User → [[Vault-Layout]] · Agent → [[Scripts]]
'

write_note "$P/20-Backlog/KitchenOS.md" '---
type: project
status: backlog
tags: [kitchenos]
created: 2026-08-26
source: session-2026-08-26 (files: "KitchenOS fixes", apply_kitchenos_audit.py)
verified: true
next-action: Clarify scope with user before anything else
---
# KitchenOS

References found: `~/KitchenOS fixes` (file) and `~/Descargas/apply_kitchenos_audit.py`.
Held in the vault review bucket — nothing moved, nothing automated.

## Next actions
- [ ] Ask user what KitchenOS is / what they want done
'

write_note "$P/20-Backlog/Godot-Games.md" '---
type: project
status: backlog
tags: [godot, games]
created: 2026-08-26
source: session-2026-08-26 (home inventory)
verified: true
next-action: Ask user which project to pick up
---
# Godot Games

Projects on the machine (untouched by automation — project dirs excluded from vault moves):
`catkart`, `catraft-2-0`, `catraft-3-0`, `dodge-the-creeps`, `falling-kana`, `godot-4-game-template-v-0.1`, `Godot/`
Godot binaries: `Godot_v4.5/4.7` (Documentos → vault Software).

## Ideas to explore (ask user)
- [ ] Kana/Japanese learning game (falling-kana?)
- [ ] Kart/craft game direction
'

write_note "$P/30-Ideas/Ideas.md" '---
type: idea
status: idea
tags: [ideas]
created: 2026-08-26
source: session-2026-08-26 (inferred)
verified: false
---
# Ideas (scratch)

- Phone → vault auto-ingest (see [[Phone-Files]])
- Jellyfin: Comic Vine key for CBZ metadata; maybe a Manga library type via plugin
- Make `dsh web` a systemd user service (survive reboot) — offered, not yet requested
- Automate vault-missing → download suggestions (needs user consent + safe source)
'

# ═══════════════════════════════════════════════════════════════════════════
# VAULT 3 — AGENT  (about the agent / DSH itself)
# ═══════════════════════════════════════════════════════════════════════════
A="$KB/Agent"; mkdir -p "$A/10-Setup" "$A/20-Capabilities" "$A/30-Conventions" "$A/90-Meta"

write_note "$A/Home.md" '---
type: index
tags: [moc, agent]
created: 2026-08-26
source: session
---
# Agent Knowledge — Home

What the agent is, how it runs here, and how it should work. **Start here when unsure how to behave in this environment.**

## Setup
- [[Setup]] — where things live, how the harness runs
- [[Model]] — model, parameters, reasoning
- [[Plugins-Skills]] — skills & tools available

## Capabilities & limits
- [[Capabilities]] — what I can/cannot do here
- [[Scripts]] — the vault pipeline scripts I built

## Conventions
- [[Conventions]] — the knowledge-base standard (frontmatter, naming, provenance)
- [[Custom-Instructions]] — distilled operating rules

```dataview
TABLE updated FROM "Agent" WHERE type != "index"
```
'

write_note "$A/10-Setup/Setup.md" '---
type: agent
tags: [setup, dsh]
created: 2026-08-26
source: environment (2026-08-26)
verified: true
---
# Setup

## Harness
- **Implementation checkout**: `/home/rex/deepseek-harness` (source of truth for DSH code)
- **Working directory** (session workspace): `/home/rex/Documentos/Software Development/DeepSeek Harness` — *not the same as the checkout*
- **Web GUI**: `http://127.0.0.1:3080` (served by `dsh web`; only it injects `window.__DSH_BOOT__`)
- **Start command** (user): `NODE_OPTIONS="--max-old-space-size=4096" pnpm dsh web` (from checkout) — must add `--trusted-host rhls-asus.tail8b43b4.ts.net` for phone access
- **User data**: `~/.dsh/` (sessions, settings.yaml, storages/workspace.json)
- Client plugins: changes hot-reload via HMR *only while `pnpm run dev:web` runs*; everything else needs a rebuild + refresh

## Remote access
- Tailscale serve → https://rhls-asus.tail8b43b4.ts.net (Host-header fence: must match `--trusted-host` **FQDN**)
- Privileged methods (Settings/API keys/host.pickDirectory) are loopback-only by design

## Sandbox (this agent)
- bwrap sandbox: host FS visible for reads; writes limited to workspace unless escalated
- `sudo` **impossible** ("no new privileges") — system installs must be run by the user
- `/tmp` does NOT persist between bash calls — fetch+parse must happen in one command
- Process list is namespaced (can see own processes only); cgroups/`systemctl`/`/proc` give host data
'

write_note "$A/10-Setup/Model.md" '---
type: agent
tags: [model]
created: 2026-08-26
source: environment
verified: true
---
# Model

- Model: **deepseek-v4-flash** (as configured in this harness)
- Reasoning: extended thought blocks used for planning
- Works best with: explicit task decomposition, todo lists, batched independent tool calls
- Operating style: verify before claiming (exit codes, re-checks), cite sources for web facts
'

write_note "$A/10-Setup/Plugins-Skills.md" '---
type: agent
tags: [skills, tools]
created: 2026-08-26
source: environment
verified: true
---
# Plugins & Skills

Tool families available this session:
- **Files**: read, write, edit, glob, grep — workspace-scoped writes by default
- **Shell**: bash (sandboxed; escalations: workspace-write, danger-full-access)
- **Web**: web_search (with source URLs)
- **Delegation**: subagent / subagent_fork (background by default), workflow (JS orchestration), ralph (fresh-agent loops)
- **Memory & goals**: todo_write, create_goal/update_goal/get_goal
- **Media**: read_image
- **Ask**: ask_user_question (for choices/confirmation)

Session skill catalog: load with the `skill` tool by exact name before acting on matching tasks.
'

write_note "$A/20-Capabilities/Capabilities.md" '---
type: agent
tags: [capabilities, limits]
created: 2026-08-26
source: environment
verified: true
---
# Capabilities & Limits

## Can do
- Read/analyze the whole user filesystem (reads are open under read-only policy)
- Modify files: workspace freely; elsewhere only with approval escalation (workspace-write / danger-full-access)
- Run commands, background jobs, manage systemd **user** units (system units need user sudo)
- Fetch from the internet (curl/python/urllib work; Wikipedia blocks default UA — use a browser UA)
- Build/reuse the vault pipeline scripts (see [[Scripts]])

## Cannot do
- **sudo** (sandbox "no new privileges") — installs/root tasks must be run by the user
- See other users processes (PID-namespaced) — use cgroups/journalctl/systemctl for host state
- Persist files in `/tmp` across bash calls
- Reach the user phone directly — folders must be mounted/synced to the PC first
- Bypass approval prompts (a denial is final; never work around)

## Behavioral rules (summary → [[Custom-Instructions]])
'

write_note "$A/20-Capabilities/Scripts.md" '---
type: agent
tags: [scripts, vault]
created: 2026-08-26
source: session-2026-08-26 (built & verified)
verified: true
---
# Scripts I Built (vault pipeline)

All in `~/Documentos/Software Development/DeepSeek Harness/`:

| Script | Purpose |
|---|---|
| `organize-vault.sh` | Classify loose files → Vault categories (`SRC_ONLY` env scopes source; `--apply`/`--dry-run`) |
| `jellyfin-prep.sh` | Rename/move media into Jellyfin structure (Movies/Shows/Anime/Standup) |
| `books-prep.sh` | Books/manga: repack epub, cbz manga, name cleanup, dedupe |
| `vault-missing.sh` | Nightly incomplete-series report → `vault-missing.txt` |
| `vault-nightly.sh` | 03:00 pipeline wrapper (Inbox → classify → jellyfin → books → missing) |
| `optimization-checklist.html` | Clickable system-optimization checklist (done/archived) |

Safety contract: never deletes, never overwrites (collision → `-N`), undo via `vault-undo.sh`, logs in `*.log` next to scripts.

Nightly timer: `vault-nightly.timer` (systemd user, 03:00, persistent).
Reminder timer: `reminder-phone-files.timer` (one-shot).
'

write_note "$A/30-Conventions/Conventions.md" '---
type: agent
tags: [conventions, standard]
created: 2026-08-26
source: session-2026-08-26 (established by user request)
verified: true
---
# Knowledge-Base Conventions (the standard)

Goal: human- and machine-accessible, searchable, provenance-first.

## Frontmatter schema (every note)
```yaml
---
type: person | system | project | idea | agent | index | template
tags: [tag1, tag2]
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: <session-id | scan | web (url) | user-stated | inferred>
verified: true | false | partial
confidence: high | medium | low
related: ["[[Note]]"]
---
```

## Rules
1. **Provenance**: every fact states where it came from (`source` field + inline mentions). Never invent history.
2. **Wikilinks** `[[...]]` instead of duplicated text; one fact lives in one note.
3. **Tags** for search: lowercase, kebab-case, topical (`#japanese`, `#vault`).
4. **MOCs**: each vault has `Home.md` index linking sections.
5. **Templates** in `90-Meta/`; new notes start from them.
6. **Verify before writing**: mark `verified: false` / `confidence: low` when uncertain.
7. **Dates**: ISO `YYYY-MM-DD`; update `updated` on every edit.
8. **Folders**: numbered areas (10-, 20-…) per vault; attachments if any → `attachments/`.
9. Machine-access: keep tables/frontmatter parseable (Dataview-compatible).
'

write_note "$A/30-Conventions/Custom-Instructions.md" '---
type: agent
tags: [instructions]
created: 2026-08-26
source: session-2026-08-26 (observed operating rules)
verified: true
---
# Custom Instructions (distilled operating rules)

- **Token efficiency first**: no full listings (counts/head), batch independent calls, background long jobs, summary tables over dumps.
- **Plan before acting** on big tasks; show the strategy; get approval.
- **Checklists**: deliver clickable/reviewable checklists; never implement without consent.
- **Verify**: check exit codes; re-check state after changes; cite web sources as markdown links.
- **Honesty**: state limitations plainly (e.g. "9-day-old repo", "I verified X, not Y"); a denial is final.
- **Safety**: never delete user data; moves reversible (undo logs); secrets never moved/synced.
- **Scope discipline**: e.g. "no more Steven Universe" — honor user scope decisions.
- **Formatting**: markdown inline-code paths for files changed (`path/to/file`).
'

write_note "$A/90-Meta/Note-Template.md" '---
type: template
tags: [template]
---
---
type: agent
tags: []
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
source:
verified:
---
# Title
'

# ═══════════════════════════════════════════════════════════════════════════
# REMINDER — phone files at 18:00
# ═══════════════════════════════════════════════════════════════════════════
cat > "$HOME/.local/bin/remind-phone-files.sh" <<'R'
#!/usr/bin/env bash
STAMP="$(date '+%F %T')"
echo "$STAMP REMINDER: Phone-files organization — see Projects → Phone-Files" >> "$HOME/.local/state/reminders.log"
if command -v notify-send >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
  notify-send -u critical "⏰ Phone files" "Organize phone files into the Vault — see Obsidian: Projects → Phone-Files"
fi
R
chmod +x "$HOME/.local/bin/remind-phone-files.sh"

NOW="$(date +%H%M)"
if [ "$NOW" -lt 1800 ]; then DAY="$(date +%F)"; else DAY="$(date -d tomorrow +%F)"; fi
cat > "$HOME/.config/systemd/user/reminder-phone-files.service" <<'S'
[Unit]
Description=Reminder: organize phone files

[Service]
Type=oneshot
ExecStart=/home/rex/.local/bin/remind-phone-files.sh
S
cat > "$HOME/.config/systemd/user/reminder-phone-files.timer" <<T
[Unit]
Description=Phone-files reminder (18:00)

[Timer]
OnCalendar=${DAY} 18:00:00

[Install]
WantedBy=timers.target
T

echo "Created:"
find "$KB" -type f | sort
echo
echo "Reminder scheduled for: $DAY 18:00"
