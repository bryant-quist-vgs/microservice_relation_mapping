---
id: foss-evaluation-2026-07-13
is_source_of_truth: true
derives_from: []
---

# FOSS Tool Evaluation — Microservice Relationship Mapping

**Date:** 2026-07-13
**Status:** Complete
**Document role:** Source of Truth for the evaluation findings that support [ADR-0001](../adr/ADR-0001-build-new-python-tool.md).
**Method:** Four independent code-level reviews (one per candidate), each verifying README/marketing claims against actual source. Evidence is cited as file paths within each cloned repo under `foss_repositories/`.

## Purpose

Before investing in a custom tool, four FOSS repository-mapping candidates were
evaluated against the project's hard requirements. The candidates were cloned
locally and reviewed at source level (commits current as of 2026-07-11 to 2026-07-13).

## Hard requirements evaluated

1. **UX for agents and humans** — output must be comfortable for both.
2. **Shareable** — between team members (git, self-hosted, or SaaS).
3. **No LLM/agent required for core function** — deterministic, cheap to re-run;
   should support human prose augmentation that survives regeneration.
4. **Cross-repository analysis** — link ~300 separate repos to each other
   (call-site in repo A → endpoint/handler in repo B).
5. **Protocol detection** — HTTP clients/routes, gRPC, message queues, etc.
6. **Language support** — Java, Python, JS/TS, Golang, Terraform.

Secondary criteria: supply-chain surface (avoid npm where possible; Python
preferred), local workstation runnability, forkability, taint/trust-label
potential, project health/license.

## Result matrix

| Requirement | codegraph | graphify | Understand-Anything | GitNexus |
|---|---|---|---|---|
| 1. Agent + human UX | PARTIAL | YES | YES | YES |
| 2. Shareable artifact | NO | YES | YES | PARTIAL |
| 3. Core runs w/o LLM | YES | YES | **NO** | YES |
| 3b. Prose survives regen | NO | PARTIAL | NO | LIMITED |
| 4. Cross-repo linking | **NO** | **NO** | **NO** | **YES** |
| 5. Protocol detection | PARTIAL (routes only) | **NO** | PARTIAL (LLM-inferred) | PARTIAL (no AWS msg) |
| 6. All five languages | YES | YES | PARTIAL (TF regex-only) | PARTIAL (**no Terraform**) |
| Implementation | TS/npm | **Python** | TS/npm | TS/npm + native |
| License | MIT | MIT | MIT | **PolyForm Noncommercial** |
| Verdict | Reject | Reject / component | Reject / mine designs | Reject (license) |

## Candidate summaries

### codegraph (`colbymchenry/codegraph`, MIT, TypeScript) — REJECT

An MCP server/CLI whose explicit purpose is feeding coding agents "surgical
context" (`package.json:4`). Deterministic tree-sitter → SQLite extraction with
no LLM in the core; all five target languages including a Terraform resolver.

Disqualifiers:

- **No cross-repo linking.** Edge kinds are all intra-code-structure
  (`src/types.ts:48-60`); "multi-repo" means indexing many repos into one
  SQLite file joined only by shared-code imports. The Terraform resolver
  explicitly refuses out-of-tree edges (`src/resolution/frameworks/terraform.ts`).
- **One-sided protocol awareness.** Detects server route *definitions* across
  many frameworks but has zero HTTP-client, gRPC, or queue pub/sub detection.
- **Artifact not shareable.** Output is a gitignored binary SQLite DB, per-machine
  by design; no annotation layer survives re-index.
- Notable: default-on telemetry to `telemetry.getcodegraph.com` (documented,
  opt-out); bus factor 1; small npm tree (~107 packages).

Salvage value: clean per-language extractor layout (`src/extraction/languages/`)
and framework-resolver registry as prior art.

### graphify (`Graphify-Labs/graphify`, MIT, Python) — REJECT (component candidate)

An AI-assistant knowledge-graph/memory tool (YC S26). Strongest secondary-criteria
fit: Python, deterministic AST-only code extraction with zero LLM
(`BENCHMARKS.md:91-92`), git-committable outputs (`graph.json`, `GRAPH_REPORT.md`,
interactive HTML), rich export surface (GraphML, Cypher, Neo4j/FalkorDB push,
MCP server), all five languages including HCL, active with 141 test files.

Disqualifiers:

- **Zero protocol detection.** Edge vocabulary is purely code-structure; repo-wide
  search for kafka/sqs/sns/grpc/amqp returns nothing. No HTTP client or route
  extraction.
- **No real cross-repo linking.** The "global graph" merges per-repo graphs by
  deduplicating external symbol nodes on shared *names* (`global_graph.py:121-143`)
  — coincidental, not communication-based.
- No taint/trust model; no durable annotation layer (rationale nodes come only
  from source comments).
- `extractors/engine.py` is a 4,500-line monolith — a heavy center of gravity
  to modify.

Salvage value: the export/MCP layer could serve as a downstream component fed by
a purpose-built extractor; validates that Python + tree-sitter performs at
~1M-LOC scale.

### Understand-Anything (`Egonex-AI/Understand-Anything`, MIT, TypeScript) — REJECT (mine for design)

An AI-agent plugin pack for codebase onboarding. **Fails the no-LLM requirement
by design:** the deterministic tree-sitter layer only feeds structural facts to
LLM subagents that emit the actual graph nodes/edges "using expert judgment"
(`agents/file-analyzer.md`); there is no deterministic graph-build path, and
protocol edges (`publishes`, `subscribes`, `calls`) exist only if an LLM chooses
to emit them — non-reproducible and unsuitable for audit-grade triage.

Also: strictly single-repo (the merge tool is intra-monorepo only), and
incremental regeneration deletes and rewrites all nodes/edges for changed files,
destroying any human annotation.

Salvage value (significant, MIT-licensed):

- **Ontology:** 13 node types / 26 edge types incl. `service`, `endpoint`,
  `publishes`, `subscribes`, `routes`, `serves`, `provisions`
  (`packages/core/src/schema.ts`) — a strong starting vocabulary.
- **Distribution model:** git-committed JSON graph + read-only local `npx`
  viewer — matches the shareability requirement exactly.
- **Anti-lesson:** human prose must live in sidecar files keyed by stable node
  IDs and be merged at build time, never stored inside the regenerated artifact.

### GitNexus (`abhigyanpatwari/GitNexus`, PolyForm Noncommercial, TypeScript) — REJECT (license)

The closest engineering fit. Genuine cross-repo capability (`src/core/group/`):
per-repo extractors emit provider contracts (route definitions) and consumer
contracts (outbound client calls), normalized to canonical contract IDs
(`http::GET::/users/{param}`, `grpc::<pkg>/<method>`) and matched across repos
into cross-links (`matching.ts`), with cross-repo impact/trace queries and a
plain-JSON `contracts.json` artifact. Deterministic, LLM-free core
(`CLAUDE.md`: "The GitNexus CLI analyzer does not call an LLM"). Deep semantic
analysis (scope resolution, import resolution, type propagation) for Java,
Python, JS/TS, Go. Protocol extractors for HTTP, gRPC, Thrift, Kafka, RabbitMQ,
NATS. An opt-in interprocedural taint engine (CFG, reaching-defs, call
summaries).

Disqualifiers:

- **License.** PolyForm Noncommercial 1.0.0 does not permit operational use by
  a for-profit company's security team. Adoption or forking requires a
  commercial license or explicit legal clearance. This alone rejects it.
- **Stack gaps that hit our environment:** no Terraform/HCL at all; no
  SQS/SNS/Kinesis/EventBridge (AWS-native messaging entirely absent); no SSRF
  sink in the taint model; no Go taint model; taint does not cross repo
  boundaries.
- **Supply chain:** ~1,300 npm packages across the monorepo incl. ~16 native
  tree-sitter grammars built via node-gyp postinstall.
- Cross-repo matching is path/method *shape* matching, not resolution of actual
  target hosts — collision false-positives at 300-repo scale would need tuning.

Salvage value: the contract-matching architecture (consumer/provider
normalization → canonical ID → cross-link with provenance) is the validated
reference design for our core linking layer. Design may be studied; code may
not be copied (license).

## Cross-cutting findings

1. **The gap is real.** All four tools are AI-coding-assistant context tools at
   heart. None was built for fleet-level service topology; only GitNexus grew a
   cross-repo subsystem, and it is license-blocked. The niche this project
   targets is genuinely unoccupied in FOSS (as sampled).
2. **Python performance concern resolved.** graphify demonstrates tree-sitter's
   C-backed parsing driven from Python at ~1M-LOC scale with deterministic
   builds; orchestration language is not the bottleneck.
3. **Terraform is unserved.** No candidate treats Terraform as an evidence
   source for service wiring — codegraph parses it intra-tree only, GitNexus
   ignores it entirely. Our environment (AWS, infra-declared queues/topics)
   makes this a differentiator worth owning.
4. **Validated patterns to adopt:** canonical-contract matching (GitNexus),
   committed-JSON + local viewer distribution (Understand-Anything), sidecar
   prose annotations keyed by stable IDs (anti-lesson from all four).
