# UNIVERSAL PROJECT ARCHAEOLOGY & ARCHITECTURE AUDIT — MEGACYCLE PROTOCOL

Multi-Agent / Multimodal Project Analysis Protocol. This is the full
"megacycle" referenced in `~/Documentos/hail mary.md`. Canonical copy
preserved 2026-09-04 by the dsh session (the version in hail mary.md was
only a farewell note; the full protocol is here).

## Pipeline (from Rex's diagram)

```
PROJECT
   │
   ├── INVENTORY AGENT ──► normalized project map
   │        │
   │   ┌────┼────┬────┬─────┬─────┐
   │   ▼    ▼    ▼    ▼     ▼     ▼
   │ Stack Code Data Runtime UX/UI
   │ Agent Agent Agent Agent  Agent
   │   └────┴────┼────┴──────┘
   │            ▼
   │      CROSS-AUDITOR
   │            ▼
   │   ARCHITECTURE ANALYST
   │            ▼
   │        VALIDATOR
   │            ▼
   │        REPORTER
```

## Core principles (abridged — full text below)

0. Inspect before judging. 2. Distinguish FACT / INFERENCE / RECOMMENDATION.
4. Never assume docs match implementation. 6. Never infer functionality from
mere mentions. 7. Executable evidence > documentation. 9. Runtime evidence >
source assumptions when it exists. 10. Preserve architecture unless evidence
shows a concrete problem. 16. Do not invent missing info → report UNKNOWN.
18. Every significant conclusion carries evidence. 20. Describe the project
as it exists, not as the auditor wishes it existed.

## Execution model

Orchestrator partitions the project into evidence domains and fans out
specialists (Inventory, Architecture, Code, Dependency, Data, Build/Deploy,
Test, Performance, Security, Licensing, UI/UX-multimodal, Documentation).
Specialists are evidence collectors: they return FINDINGS / EVIDENCE /
CONFIDENCE / UNKNOWNs / CONFLICTS — they do NOT redesign. Only the
orchestrator synthesizes, cross-correlates, detects contradictions, removes
duplicates, adjusts confidence, and produces final recommendations.

## Output

1. Human report in 25 sections (Executive Summary → … → Evidence Appendix).
2. Machine-readable JSON: {project, inventory, components, dependencies,
   data_flows, architecture, code_standards, tests, build_system, deployment,
   security, licensing, performance, ux, documentation, strengths,
   weaknesses, contradictions, technical_debt, recommendations, unknowns,
   evidence, confidence}.
3. Every finding: {id, category, finding, evidence[], status:
   verified|inferred|unknown|contradicted, confidence: high|medium|low,
   severity: P0|P1|P2|P3|none, recommendation}.

Technical-debt severity: P0 blocks operation/deployment/security/correctness;
P1 substantial maintenance/reliability risk; P2 recurring friction; P3 minor.

Confidence: HIGH = directly observed; MEDIUM = strong inference from multiple
evidence; LOW = plausible but unconfirmed. Never hide uncertainty.

## Multimodal routing

code→code specialist · config→build/deploy · schema→data ·
screenshots/UI→UI multimodal specialist · diagrams→architecture+multimodal ·
PDF/docs→documentation · model/AI→ML specialist. Do not process irrelevant
modalities. Visual observation is NEVER implementation evidence unless
corroborated.

## Orchestrator rule

Treat the project as an evidence graph; never average specialist opinions.
If Agent A says X and Agent B says Y and they conflict: locate the underlying
evidence, determine whether they refer to different layers, decide which
evidence is stronger, preserve unresolved disagreement. Report "Documentation
states X, while implementation indicates Y" rather than hiding the conflict.

## Audit scope notes (this estate)

- The audit protocol below is generic; when applied to the RHLS estate it is
  run per-project or per-evidence-domain with a bounded file manifest, never
  by handing every specialist the entire tree.
- Low-resource/offline/licensing/security/deployment constraints are
  first-class here (per principle 15): old hardware, no money, offline-first,
  MIT/Apache/proprietary hybrid licensing, same-day deploys.

---

# FULL PROTOCOL TEXT (verbatim, as provided by Rex)

## 0. CORE PRINCIPLES

Follow these rules throughout the audit.

1. Inspect before judging.
2. Describe the existing system before recommending changes.
3. Distinguish FACT from INFERENCE from RECOMMENDATION.
4. Never assume documentation accurately describes implementation.
5. Never assume an unused dependency is actually part of the architecture.
6. Never infer functionality merely because code, documentation, or
   configuration mentions it.
7. Prefer executable evidence over documentation.
8. Prefer source code over README claims.
9. Prefer runtime behavior over source-code assumptions when runtime
   evidence exists.
10. Preserve existing architecture unless there is evidence that it is
    causing a concrete problem.
11. Do not recommend technology merely because it is newer.
12. Do not optimize hypothetical future requirements.
13. Identify unnecessary complexity as aggressively as missing functionality.
14. Identify duplicated functionality, duplicated data, duplicated
    dependencies, and duplicated abstractions.
15. Treat low-resource environments, offline operation, licensing, security,
    maintainability, and deployment constraints as first-class architectural
    concerns when evidence indicates they matter.
16. Do not invent missing information.
17. If evidence is insufficient, explicitly report: UNKNOWN.
18. Every significant conclusion must have evidence.
19. Conflicting evidence must be reported rather than silently reconciled.
20. The final report must describe the project as it exists, not as the
    auditor wishes it existed.

## 1. FIRST PASS — PROJECT INVENTORY

Determine: project name · apparent purpose · actual purpose · project type ·
primary users · target platforms · deployment model · languages ·
frameworks · libraries · databases · services · build systems · package
managers · runtime environments · external APIs · external datasets ·
generated artifacts · configuration systems · test systems · documentation ·
CI/CD · containers · infrastructure · plugins/extensions · hardware
dependencies · model/AI dependencies · multimedia dependencies · licensing
information.

Classify each as IMPLEMENTED / PARTIALLY IMPLEMENTED / PLANNED /
DOCUMENTED ONLY / DEAD-UNUSED / UNKNOWN. Do not treat PLANNED or DOCUMENTED
ONLY components as implemented. Output a machine-readable inventory.

## 2. PROJECT TOPOLOGY

Component map: components, modules, packages, services, processes, data
stores, external systems, users, input/output boundaries, communication
protocols, build boundaries, deployment boundaries. Dependencies as
SOURCE → RELATIONSHIP → TARGET. Also identify circular dependencies,
unnecessary chains, hidden coupling, duplicated responsibilities, components
with excessive responsibility, isolated/dead components.

## 3. ARCHITECTURE RECONSTRUCTION

3.1 Structural architecture (monolith / modular monolith / client-server /
microservices / pipeline / plugin / event-driven / layered / hexagonal /
MVC-MVVM / compiler pipeline / data-processing pipeline / distributed /
embedded / hybrid / other — do not force a fit).
3.2 Logical layers (presentation/application/domain/data/infrastructure/
integration/processing/storage) — real or merely conceptual boundaries?
3.3 Dependency direction — what depends on what; consistent flow; does
high-level logic depend on implementation details; are abstractions useful?
3.4 Data flow — INPUT → TRANSFORMATION → STORAGE/PROCESSING → OUTPUT;
serialization, parsing, validation, transformation, caching, persistence,
indexing, export, import, synchronization, rendering.

## 4. CODE AUDIT

Coding/naming conventions, module organization, function size, class
responsibility, abstraction level, error handling, validation, type safety,
state management, side effects, mutability, duplication, dead code,
unreachable code, magic constants, configuration handling, logging,
debugging facilities, concurrency/async, resource management, dependency
injection, interface usage, testability. Do NOT criticize style unless it
creates concrete problems. Identify the apparent coding philosophy with
evidence (minimal/modular, highly abstract, procedural, OO, functional,
data-oriented, framework-driven, configuration-driven, experimental,
pragmatic, over-engineered, inconsistent).

## 5. DEPENDENCY AUDIT

For every meaningful dependency: why it exists, where used, whether required,
lighter alternative, licensing/security concerns, platform constraints,
download size, startup time, memory/CPU cost, duplicated functionality.
Classify CORE / OPTIONAL / BUILD-TIME / RUNTIME / DEVELOPMENT / TEST /
DEAD-UNUSED / UNKNOWN. Flag unnecessary dependency weight.

## 6. DATA ARCHITECTURE AUDIT

Authoritative sources, derived data, caches, indexes, normalized vs
denormalized, generated DBs, static assets, configuration data, user data,
temporary data. Trace SOURCE → ETL → REPRESENTATION → APPLICATION. Duplicated
data, stale derived data, undocumented transformations, irreversible
transformations, missing validation, fragile imports/exports, schema
inconsistencies, migration risks.

## 7. BUILD & RELEASE AUDIT

Build commands/dependencies, packaging, artifact generation, env vars,
platform-specific builds, signing, versioning, release process, generated
assets/DBs, installers, deployment mechanism. Do builds fail loudly/silently,
reproducibly; depend on undocumented local state; require manual steps;
accidentally package dev artifacts or omit required runtime assets?

## 8. TESTING AUDIT

Unit/integration/regression/e2e/snapshot/property/performance tests, manual
procedures, fixtures, real-world data. What is actually tested vs not;
do tests reflect real workflows; can they pass while the app is broken; are
critical paths covered; deterministic; validate outputs or merely execution?
Report TESTED / PARTIALLY TESTED / UNTESTED / UNKNOWN.

## 9. PERFORMANCE & RESOURCE AUDIT

CPU/memory/disk/network usage, startup cost, download size, runtime deps,
storage, build time, processing time. Pay special attention to low-spec
hardware, slow networks, offline operation, large WASM/runtime downloads,
heavyweight frameworks, unnecessary background services/resident processes.
Do not optimize purely theoretical bottlenecks.

## 10. PLATFORM & DEPLOYMENT AUDIT

Linux/Windows/macOS/Android/iOS/browser/server/container/embedded
compatibility; platform-specific code and assumptions. Deployment
reproducible/portable/documented/automated/fragile/environment-dependent?

## 11. SECURITY AUDIT

Secrets/credentials, authn/authz, input validation, file handling, subprocess
execution, network exposure, dependency risks, unsafe deserialization,
injection, permissions, local data exposure, update mechanisms. Do NOT
attempt exploitation. Report weaknesses and likely attack surfaces.

## 12. LICENSING AUDIT

Licenses of project code, dependencies, datasets, models, fonts, media,
generated artifacts. Permissive/copyleft/proprietary, attribution
requirements, redistribution/commercial-use restrictions. No legal
conclusions beyond evidence; flag items needing human/legal verification.

## 13. USER EXPERIENCE / UI AUDIT

When visual material exists, inspect screenshots/windows/webpages/mobile
interfaces/diagrams/documents/dashboards/CLI output. Evaluate hierarchy,
consistency, information density, navigation, discoverability, feedback,
error states, accessibility, responsiveness, visual consistency, cognitive
load. Separate visual observation from UX interpretation.

## 14. MULTIMODAL AUDIT

Describe what is directly observable; then what can reasonably be inferred.
Visual interpretation is never implementation evidence unless corroborated.
Diagrams: DIAGRAM CLAIM → IMPLEMENTATION EVIDENCE → VERIFIED / PARTIALLY
VERIFIED / CONTRADICTED / UNKNOWN. Screenshots: SCREENSHOT OBSERVATION →
LIKELY IMPLEMENTATION → CONFIRMATION REQUIRED.

## 15. DOCUMENTATION AUDIT

Matrix: Claim | Evidence | Status (VERIFIED / PARTIALLY VERIFIED /
CONTRADICTED / UNKNOWN). Identify stale docs, undocumented behavior,
undocumented deps/build requirements/architecture, misleading terminology.

## 16. ARCHITECTURAL QUALITY ASSESSMENT

Assess independently: correctness, cohesion, coupling, complexity,
maintainability, testability, portability, resource efficiency,
reproducibility, extensibility, operational reliability, security, licensing.
Do not collapse into one arbitrary score.

## 17. ENGINEERING PHILOSOPHY RECONSTRUCTION

From repeated implementation patterns: minimalism, abstraction, modularity,
performance consciousness, offline-first, open-source preference,
portability, rapid prototyping, strict typing, defensive programming,
experimental, data-driven, automation, reproducibility, simplicity,
extensibility. Each: PRINCIPLE + EVIDENCE + CONFIDENCE. No single-file
inferences about personal preference.

## 18. TECHNICAL DEBT

P0 critical / P1 high / P2 moderate / P3 low. Each item: location, evidence,
impact, severity, confidence, smallest reasonable remediation. No subsystem
rewrites unless evidence supports them.

## 19. ARCHITECTURAL CONTRADICTIONS

High-value: docs say A code does B; claimed modularity but tight coupling;
"offline" needing network; "optional" dep that is mandatory; free edition
containing premium functionality; tests pass but real workflow fails;
normalization claims with duplicated data; performance goals vs
implementation; portability claims vs platform-specific code; security
assumptions vs deployment config.

## 20. MINIMAL-CHANGE RECOMMENDATIONS

Each: PROBLEM / EVIDENCE / CURRENT BEHAVIOR / MINIMAL CHANGE / EXPECTED
BENEFIT / RISK / EFFORT. Prefer ONE FILE CHANGE over NEW SUBSYSTEM, SMALL
ADAPTER over ARCHITECTURAL REWRITE, REMOVE UNUSED DEPENDENCY over REPLACE
ENTIRE STACK — unless evidence demands more.

## 21. ALTERNATIVE ARCHITECTURE

Only when the current architecture has a demonstrable structural problem OR
a substantially simpler architecture meets the same requirements. Must state
WHAT CHANGES / WHAT STAYS / WHY BETTER / WHAT IT COSTS / RISKS / WHY THE
CURRENT MAY STILL BE PREFERABLE. No fashionable rewrites.

## 22. CONFIDENCE MODEL

HIGH / MEDIUM / LOW per conclusion, reflecting evidence quality. Never hide
uncertainty.

## 23. FINAL REPORT STRUCTURE

1 Executive Summary · 2 Project Identity · 3 Actual Implemented Stack ·
4 Project Topology · 5 Architecture · 6 Data Architecture · 7 Code Standards
· 8 Dependencies · 9 Build & Deployment · 10 Testing · 11 Performance ·
12 Security · 13 Licensing · 14 UI/UX · 15 Documentation Accuracy ·
16 Engineering Philosophy · 17 Architectural Strengths · 18 Architectural
Weaknesses · 19 Contradictions · 20 Technical Debt · 21 Prioritized Issues ·
22 Minimal-Change Recommendations · 23 Alternative Approach · 24
Unknown/Unverified · 25 Evidence Appendix.

## 24. MACHINE-READABLE OUTPUT

Structured JSON with project, inventory, components, dependencies,
data_flows, architecture, code_standards, tests, build_system, deployment,
security, licensing, performance, ux, documentation, strengths, weaknesses,
contradictions, technical_debt, recommendations, unknowns, evidence,
confidence. Each finding: {id, category, finding, evidence[], status,
confidence, severity, recommendation}.

## 25. MULTI-AGENT EXECUTION RULES

Do NOT give every specialist the entire project. Orchestrator partitions
into evidence domains. Specialists: 1 Inventory, 2 Architecture, 3 Code,
4 Dependency, 5 Data, 6 Build/Deployment, 7 Test, 8 Performance, 9 Security,
10 Licensing, 11 UI/UX Multimodal, 12 Documentation. Each receives the
inventory, only domain-relevant files/assets, relevant instructions, and
prior evidence where useful. Each returns FINDINGS / EVIDENCE / CONFIDENCE /
UNKNOWNs / CONFLICTS. Orchestrator performs CROSS-CORRELATION, CONTRADICTION
DETECTION, DUPLICATE REMOVAL, CONFIDENCE ADJUSTMENT, PRIORITIZATION. Only the
orchestrator produces final recommendations.

## 26. SPECIALIST MODEL RULES

Small models are evidence collectors, not architects. MUST NOT redesign,
invent missing architecture, extrapolate beyond evidence, make broad claims
from one file, silently resolve contradictions, recommend unrelated tech.
SHOULD identify concrete evidence (quote identifiers/filenames/commands/
schemas/observables), report uncertainty, identify inconsistencies, produce
concise structured findings.

## 27. MULTIMODAL ROUTING

Source code→code specialist · configuration→build/deploy · DB/schema→data ·
screenshots/UI→UI specialist · diagrams→architecture+multimodal · video→
multimodal · audio→domain audio specialist · PDF/docs→documentation ·
3D/CAD/hardware→hardware specialist · scientific data→data+domain · model/AI→
ML specialist. Do not process irrelevant modalities.

## 28. ORCHESTRATOR RULE

Treat the project as an evidence graph; never average specialist opinions.
Conflicting X/Y: locate evidence, check whether they refer to different
layers, decide which evidence is stronger, preserve unresolved disagreement.
Report "Documentation states X, while implementation indicates Y."

## 29. FINAL QUALITY CONTROL

[ ] Implemented vs planned distinguished. [ ] Dead vs active dependencies
distinguished. [ ] Evidence attached to conclusions. [ ] Contradictions
searched. [ ] UNKNOWNs marked. [ ] Recommendations do not precede
reconstruction. [ ] Recommendations proportional to problems. [ ] No
unnecessary rewrites. [ ] Security findings evidence-based. [ ] Licensing
findings evidence-based. [ ] Multimodal observations separated from
inference. [ ] Specialist findings cross-checked.
