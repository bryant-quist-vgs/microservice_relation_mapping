---
id: adr-0001-build-new-python-tool
is_source_of_truth: true
derives_from: [foss-evaluation-2026-07-13]
---

# ADR-0001: Build a purpose-built Python tool rather than adopt or fork existing FOSS

**Date:** 2026-07-13
**Status:** Accepted
**Document role:** Source of Truth for this decision. Evidence base:
[FOSS evaluation 2026-07-13](../evaluations/foss-evaluation-2026-07-13.md).

## Context

The security team needs a durable, maintainable map of how ~300 microservice
repositories relate to each other through code-level communication (HTTP,
gRPC, message queues, Terraform-declared infrastructure wiring). Immediate
driver: recurring AWS GuardDuty SSRF alerts whose triage is slowed by stale
and siloed documentation. Long-term driver: general vulnerability triage.

Hard requirements: agent- and human-comfortable UX; shareable artifact;
deterministic core that runs without an LLM; cross-repository linking;
protocol detection; Java/Python/JS-TS/Go/Terraform support. Preferences:
minimal supply-chain surface (avoid npm), Python implementation, workstation
runnable, future trust/sensitivity labeling of input sources.

Four FOSS candidates were evaluated at source level: codegraph, graphify,
Understand-Anything, GitNexus.

## Decision

Build a new, purpose-built tool in Python (modern tooling: uv, ruff), using
tree-sitter for multi-language parsing. Do not adopt or fork any evaluated
candidate.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Adopt any candidate as-is | None passes the hard requirements (see evaluation matrix). |
| Fork graphify (MIT, Python) | Zero protocol detection and no true cross-repo linking mean the core capability is built from scratch anyway, inside a 4,500-line engine monolith built for a different purpose. |
| Fork GitNexus (best engineering fit) | PolyForm Noncommercial license bars commercial operational use; also no Terraform, no AWS-native messaging, ~1,300-package npm tree. Legal lead time + remaining build effort exceeds value. |
| Fork Understand-Anything | Graph is LLM-constructed — fails the deterministic-core requirement by design; single-repo only. |
| Widen the FOSS search | The four candidates sample the main tool families (agent-context indexers, knowledge-graph builders, LLM doc generators); the fleet-topology niche is unoccupied. Declined 2026-07-13. |

## Consequences

- We own the full build: extraction, contract matching, artifact format,
  viewer/query surfaces.
- Validated designs are adopted (designs only, no code from the
  license-restricted candidate): canonical-contract matching for cross-repo
  linking (GitNexus reference architecture); committed-JSON artifact plus
  local read-only viewer (Understand-Anything, MIT); sidecar human-prose
  annotations keyed by stable node IDs merged at build time (anti-lesson from
  all candidates).
- Terraform becomes a first-class evidence source — unserved by any FOSS
  candidate and a differentiator for our AWS environment.
- Python + tree-sitter performance is de-risked by graphify's demonstrated
  ~1M-LOC deterministic builds (parsing is C-backed; Python orchestrates).
- graphify's export/MCP layer remains a candidate downstream component if its
  interface fits once our artifact format is designed.
- Supply-chain posture: Python/uv ecosystem with a small pinned dependency
  set; no npm in the core toolchain.

## Follow-ups

- Design phase (interactive) before any implementation code: artifact/data
  model, evidence-source strategy, matching semantics, trust labeling.
- Pursuit of a GitNexus commercial license is **deferred, not planned** — see
  [deferred and out-of-scope](../deferred-and-out-of-scope.md).
