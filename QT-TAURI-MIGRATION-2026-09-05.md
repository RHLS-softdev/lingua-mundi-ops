# Qt → Tauri 2 Migration — Chén Báaxal + Xokbil (2026-09-05)

Rex directive: replace Qt with the estate's multiplatform standard.
Both products are siblings (same foundation, shared audience) and should
keep their own design identity — NOT the RHLS app-store look. Per Xokbil
docs: warm modern palette, Fraunces/Inter typography, light/dark themes,
design-reference quality (like Ledgerly). This is a separate product
family for a different target audience.

## Why Tauri 2 (the estate standard)

Shikibu / KitchenOS / Toscanini-rs all ship deb+exe+apk from ONE codebase
via Tauri 2 + Rust core + React/TS UI. Qt shells only produced a Linux deb
here (no Windows cross-toolchain, no APK path) — exactly the gap Rex wants
closed. The Rust cores are kept unchanged; only the GUI layer migrates.

## Architecture (identical shape for both)

```
projects/<app>/
  core/            (UNCHANGED Rust engine — chen_baaxal_core / xokbil-core)
  src-tauri/       NEW Tauri 2 shell: Cargo.toml, tauri.conf.json,
                   src/main.rs + src/lib.rs (invoke commands),
                   capabilities/, icons/, build.rs
  ui/              NEW Vite + React + TS (per SUGGESTED-FEATURES.md P2:
                   warm palette, Fraunces/Inter, light/dark, adaptive)
```

Reference scaffold: `projects/toscanini-rs/src-tauri/` (same pattern —
pure Rust core linked as a crate, commands call core fns directly, NO
subprocess; the old Qt shell spawned `chenbaaxal-demo`).

## Chén Báaxal — commands (wrap chen_baaxal_core directly)

- `open_mesh(path) -> MeshSummary`  (load_mesh: OBJ text or GLB binary)
- `generate_pattern(input_path, seam_mm) -> {pdf_path, guide_text, panels}`
  — calls load_mesh + unwrap_mesh + pdf::write_pattern + guide writer
- `selftest() -> bool` (core 13/13 path)
UI: file picker (OBJ/GLB), seam slider (default 10mm), Generate → shows
panel count + writes PDF + guide beside input (or to chosen dir), status.

## Xokbil — commands (wrap xokbil-core: import/model/vector)

Phase-0 scope: pattern model, DST import, vector normalize_region.
Commands:
- `import_dst(path) -> PatternSummary` (stitches, colors, regions)
- `normalize_region(points) -> Region`
- `selftest() -> bool` (core 6/6)
UI: canvas preview (stitch/region render, zoom/pan), DST open, palette
swatches (DMC presets later), dark/light toggle.

## Design identity (shared, per Xokbil SUGGESTED-FEATURES P2)

- Warm modern palette (not the RHLS blue): craft/studio feel — e.g. warm
  cream/terracotta/forest/ink; light + dark themes
- Typography: Fraunces (display) + Inter (UI)
- Product-specific accent: Chén Báaxal = Maya/plush (terracotta/warm),
  Xokbil = embroidery (thread colors)
- Mobile-first responsive layout, touch-friendly; offline, $0

## Verification gate

1. `cargo test` in core/ (must stay green: CB 13/13, Xok 6/6)
2. `cargo check` in src-tauri/ (bridge compiles)
3. `npm run build` in ui/
4. `tauri build` produces deb (and is configured for exe/apk via
   `bundle.targets: all` + the windows.yml/android patterns)
5. Both share the scaffold shape; each has its own theme

## Files to remove after UI lands

- Chen Baaxal: `shell/` (Qt CMakeLists + main.cpp) — replaced by src-tauri
- Xokbil: `app/` (QML) + `rust-feasibility/` (cxx-qt probe) — replaced by
  src-tauri + ui (keep if referenced by docs/tests until green)

## Notes

- AGENTS.md/docs that say "Rust/Qt" must be updated to "Rust + Tauri 2".
- The store deb for Chen Baaxal gets rebuilt from the Tauri output once
  green; product name stays Chén Báaxal.
- Keep cores dependency-free and $0 (MoreComp discipline).
