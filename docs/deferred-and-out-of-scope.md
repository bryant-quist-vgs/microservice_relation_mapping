---
id: deferred-and-out-of-scope
is_source_of_truth: true
derives_from: [adr-0001-build-new-python-tool]
---

# Deferred and Out-of-Scope Items

**Document role:** Source of Truth for what this project has explicitly chosen
not to do (yet). Items move out of this file only via a logged decision.

## Deferred (may return)

| Item | Deferred on | Rationale / re-entry trigger |
|---|---|---|
| GitNexus commercial license pursuit | 2026-07-13 | Best-fit FOSS engine is PolyForm Noncommercial. Revisit only if the custom build stalls on the contract-matching core. |
| Tactical SSRF sweep (semgrep outbound-call inventory across the fleet) | 2026-07-13 | Owner decision: separate active investigation covers the tactical need. Revisit if that investigation dead-ends. |
| `build_dependency_index.py` doc-tooling script | 2026-07-13 | Doc set is small enough to hand-maintain `dependency-index.md`. Write the script (with contract + tests per team script standards) when doc count makes hand maintenance error-prone. |
| Orca Security runtime-data integration | 2026-07-13 | Design phase will define static-first architecture; Orca ingestion (confirming/denying statically inferred edges from runtime state) is a later evidence source. AWS access is time-gated; Orca is the available window into runtime. |
| Trust/sensitivity labeling of input sources with propagation to functions | 2026-07-13 | Stated as a strong preference, not v1 requirement. Design must not preclude it (stable node IDs, provenance on edges). |
| Integration with the separate security-mapping initiative | 2026-07-13 | Compatibility is a design constraint now; actual integration is later work. |
| Datastore node kind (shared DB/cache coupling edges) | 2026-07-14 | Confirmed deferred at design review ([ADR-0002](adr/ADR-0002-accept-v1-design.md)); node vocabulary is additive, lands later without schema breakage. |
| Static HTML graph viewer | 2026-07-13 | Not a v1 surface (DESIGN.md D4); CLI/Markdown/MCP ship first. |

## Out of scope (not planned)

| Item | Decided on | Rationale |
|---|---|---|
| Adopting/forking the evaluated FOSS tools as the foundation | 2026-07-13 | [ADR-0001](adr/ADR-0001-build-new-python-tool.md). |
| LLM/agent dependency in the core extraction pipeline | 2026-07-13 | Hard requirement: the map must regenerate deterministically and cheaply. Agents/LLMs may consume the artifact and may author prose annotations, but never construct graph edges. |
| JavaScript/npm tooling in the core toolchain | 2026-07-13 | Supply-chain posture; owner preference confirmed by evaluation findings. |
