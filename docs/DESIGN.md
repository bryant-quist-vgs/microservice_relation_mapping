---
id: design
is_source_of_truth: true
derives_from: [adr-0001-build-new-python-tool]
---

# Primary Design Document — Microservice Relationship Mapping

**Status:** DRAFT — design phase in progress (interactive; no implementation
code until this document is agreed).
**Document role:** Source of Truth for the system design once accepted.

## Problem statement

~300 microservice repositories (Java, Python, JS/TS, Go, Terraform) whose
inter-service relationships exist only in code and tribal knowledge. The
security team needs a durable, regenerable, shareable map of those
relationships for vulnerability triage (immediate driver: recurring GuardDuty
SSRF alerts).

## Hard requirements

1. Output UX comfortable for both AI agents and humans.
2. Shareable between team members.
3. Core generation runs deterministically without an LLM; human prose
   augmentation survives regeneration.
4. Cross-repository linking: call-site in repo A → endpoint in repo B.
5. Automatic detection of common inter-service protocols.
6. Languages: Java, Python, JS/TS, Golang, Terraform.

## Constraints and preferences

- Python implementation (uv/ruff toolchain); tree-sitter for parsing.
  Minimal, pinned dependency set; no npm in the core.
- Runnable on a developer workstation; cheap enough to re-run in CI.
- AWS environment; AWS access time-gated; Orca Security available for
  runtime-state queries (later evidence source).
- Must be compatible with a separate security-mapping initiative (future
  merge).
- Files intended for LLM consumption < 800 lines (prefer < 500).

## Design decisions carried in from ADR-0001

- Canonical-contract matching as the cross-repo linking model (reference
  architecture validated by GitNexus; design only, no code reuse).
- Git-committed JSON artifact + local read-only viewer as the distribution
  model.
- Sidecar prose annotations keyed by stable node IDs, merged at build time.
- Terraform as a first-class evidence source.

## Open design questions (to be resolved interactively)

1. Artifact topology: single map repo vs per-repo fragments + assembler.
2. Extraction execution model: central batch runner vs per-repo CI hooks.
3. v1 protocol/evidence scope and priority order.
4. Node identity scheme (stable IDs across regenerations).
5. Matching semantics and confidence model (shape-match collisions at
   300-repo scale; how ambiguity is represented rather than guessed).
6. Trust/sensitivity labeling data model (deferred feature; design must not
   preclude).
7. Query surfaces: CLI, static HTML viewer, MCP server — which are v1.
8. Orca integration contract (later phase).

*(Sections below will be filled in as the design discussion resolves each
question: Architecture, Data Model, Extraction Pipeline, Matching, Artifact
Format, Annotation Layer, Operations.)*
