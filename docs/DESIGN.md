---
id: design
is_source_of_truth: true
derives_from: [adr-0001-build-new-python-tool]
---

# Primary Design Document — Microservice Relationship Mapping

**Status:** ACCEPTED 2026-07-14 (owner review;
[ADR-0002](adr/ADR-0002-accept-v1-design.md)). Subsequent changes require a
logged decision.
**Document role:** Source of Truth for the system design.

## Problem statement

~300 microservice repositories (Java, Python, JS/TS, Go, Terraform) across two
GitHub organizations, whose inter-service relationships exist only in code and
tribal knowledge. The security team needs a durable, regenerable, shareable map
of those relationships for vulnerability triage (immediate driver: recurring
GuardDuty SSRF alerts).

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

## Resolved design determinations (2026-07-13, with project owner)

### D1. Topology and execution: central runner, handoff-ready

One map repository owned by the security team. A batch runner pulls all
repositories from both GitHub organizations, runs per-repo extraction to
produce a **fragment** file per repository, then runs assembly (cross-repo
matching) to produce the linked graph. Fragments and the assembled graph are
committed to the map repo.

The fragment format is a stable contract designed so that, later, individual
repositories' CI can produce and publish their own fragment without a schema
change — the assembler must not care who produced a fragment.

Enumeration/ownership patterns adopted from the owner's existing sync tooling
(`~/tooling/projects/scan_codebase/semgrep_scan_repos.py` — patterns only, not
the implementation):

- Enumerate repos via the GitHub CLI/API across both orgs; cache listings.
- Team ownership from GitHub repo custom properties (`team`), validated
  against a known team list; missing/unknown team is a reported data error,
  not a silent gap.
- Skip archived repositories; handle public/private counterpart pairs.

### D2. v1 protocol families (all confirmed in use)

1. **HTTP/REST internal calls** — client call sites and route definitions.
2. **AWS-native messaging** — SQS/SNS/EventBridge/Kinesis via SDK calls
   (boto3, aws-sdk JS/Java/Go) *and* Terraform declarations of
   queues/topics/rules/subscriptions.
3. **gRPC/protobuf** — proto service contracts, generated-stub call sites,
   server registrations.
4. **Kafka / RabbitMQ / NATS** — producer/consumer call sites joined on
   topic/queue/subject name.

### D3. Discovery and target resolution: Envoy sidecar mesh + Kubernetes DNS

The environment's internal routing runs through **Envoy sidecars** (mTLS,
tenant-aware routing, cross-cell traffic — core to the company's tokenization
proxy offering) plus Kubernetes DNS/service names. Consequences:

- Highest-precision edge resolution comes from joining code-level call sites
  with **Envoy cluster/route configuration and Kubernetes service manifests**,
  not from route-shape matching. Shape matching (GitNexus-style canonical
  contract IDs) is the *fallback* tier, not the primary mechanism.
- **Unresolved outbound targets are first-class nodes**, not discarded noise.
  In an mTLS sidecar mesh, an outbound HTTP call that does not resolve to a
  known Envoy cluster or k8s service is inherently suspicious — this bucket is
  a standing SSRF-suspect inventory and directly serves the GuardDuty driver.
- Open: where Envoy/k8s config is authored (per-repo, central GitOps repo,
  control-plane-generated) — see open questions.

### D4. v1 consumption surfaces

1. **CLI query tool** — who-calls-X, path A→B, blast radius; also the
   interface agents shell out to.
2. **Per-service Markdown pages** — generated, committed, browsable in GitHub
   with zero tooling; merged with sidecar prose annotations.
3. **MCP server** — thin layer over the same query engine as the CLI.

Explicitly not v1: static HTML graph viewer (deferred).

### D5. Evidence corpus: service repos + platform repos (inventory confirmed 2026-07-13)

The runner analyzes the ~300 service repos **plus** the repos that hold
routing/infra truth. Local force-synced analysis mirrors exist at
`~/repositories/` (verygoodsecurity org) and `~/verygood-ops/` (verygood-ops
org) — analysis copies only, not for dev work.

- `verygood-ops/vgs-gitops`, `verygood-ops/vgs-charts` — Helm charts/values,
  GitOps state, `serviceEnvoy.egress` routing blocks, standardized
  `vgs-app-sync` chart. (Note: a `verygood.gitops` repo also exists in the
  org — vintage/relationship to `vgs-gitops` to verify during extraction.)
- `verygoodsecurity/platform` — "nearly deprecated" for ~3 years but
  persists (Bazel/Go/lambda/infra); still an evidence source.
- `verygoodsecurity/unified-proxy` — Envoy xDS control plane
  (`route-provider-service` feeds `proxy-ingress-service` from S3-sourced
  state); its *tenant routing is dynamic and not in git* (see D8).
- `verygoodsecurity/messages` — central gRPC/protobuf contracts (proto +
  generated Java/Python); primary gRPC matching anchor.
- `verygoodsecurity/product` — central HTTP API specs.
- **Terraform lives across the verygood-ops org**, not in one repo:
  per-service repos follow a `terraform-aws-vgs-<service>` naming convention
  (~60 observed, e.g. `terraform-aws-vgs-knox-service`), alongside
  `terraform-aws-*` library modules (many upstream forks) and
  `infrastructure-live` / `infrastructure-prod` / `infrastructure-dev`.
  The naming convention itself seeds service identity (D7).
- `compass.yml` files (Atlassian Compass component metadata) appear in repos
  (observed in `messages`) — an additional identity/ownership seeding
  source.

### D6. The localhost-dial join: Helm/Envoy config is a required evidence layer

In the documented sidecar-egress pattern, application code dials
`127.0.0.1:<listenPort>`; the true target
(`<service>.<namespace>.svc.cluster.local`) lives in `serviceEnvoy.egress`
blocks in Helm values. Consequences:

- Code-level extraction alone cannot resolve these edges. The extractor
  joins call-site targets (host:port, env-var indirections) against parsed
  Helm values/Envoy egress config by listen port.
- Kubernetes FQDNs parse into (service, namespace) — namespace often encodes
  cell; cells collapse into one logical service node with cell membership as
  an attribute (see D8).
- Localhost dials with **no matching egress block** join the
  unresolved-outbound-target inventory (D3) — as do dials to targets outside
  the mesh.

### D7. Service identity: first-class service entity with a correctable mapping

Repo ≈ service, but deployed names drift from repo names. Therefore:

- `service` is a first-class node distinct from `repository`.
- A repo↔service mapping table is **auto-seeded** from evidence (Helm chart
  names, k8s service names, GitOps app definitions, GH `team` custom
  property) and **human-correctable** via a committed override file that
  survives regeneration (same sidecar principle as prose annotations).
- Deployables that cannot be mapped to a repo (and repos with no deployable)
  are loudly reported, not silently dropped.
- Stable node IDs derive from the service identity, not from file paths, so
  annotations and future trust labels survive refactors.

### D8. Cell/tenant routing is dynamic: map the logical graph

Tenant-aware and cross-cell routing decisions live in the unified-proxy
control plane (S3-sourced xDS), not in git. The static map models **logical
service-to-service edges**; per-cell/per-tenant physical routing is out of
static scope. Where cells are statically enumerable (e.g. Knox cell values
files), cell membership is recorded as a node attribute. Runtime
reconciliation via Orca is the designated later evidence source
(deferred item).

### Design principle: assume heterogeneity, never assume the Golden Path

Owner's observation: up to 7 distinct lambda deployment methods coexist
(excluding archived repos). The Golden Path (gRPC internal, HTTP external,
Protobuf+Kafka/SQS async, central contract repos) describes the *standard*,
not the *population*. Extractors therefore emit evidence with explicit
confidence and provenance rather than assuming conventions; coverage gaps
are reported as data, not hidden.

## Open design questions

1. **Trust/sensitivity labeling data model** (deferred feature; design must
   not preclude): label input sources, propagate to functions. The data
   model reserves attachment points (see data-model proposal §Reserved).
2. **Orca integration contract** (later phase): confirm/deny static edges
   from runtime state.
3. **`verygood.gitops` vs `vgs-gitops`:** which is live; whether both are
   evidence sources. To verify during extraction implementation.

Accepted sub-documents: [data model](design/data-model.md),
[matching & confidence](design/matching.md),
[annotations & overrides](design/annotations.md) — all accepted 2026-07-14
with the unres-identity amendment
([ADR-0002](adr/ADR-0002-accept-v1-design.md)).

Resolved process items: glossary follows the glossarian spec (linted by
`glossarian-check`; passing as of 2026-07-13). The implementation work plan
will use the Sedric checklist schema
(`~/bryant_repos/sedric/docs/schema.json` + `schema.md`, driven by the
sedric orchestrator CLI) — authored at implementation-planning time, after
design acceptance.

*(Sections to be written as questions resolve: Architecture, Data Model,
Extraction Pipeline, Matching & Confidence, Artifact Format, Annotation Layer,
Operations.)*
