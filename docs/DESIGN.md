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

## Open design questions

1. **Config evidence location:** where do Envoy configuration and Kubernetes
   manifests live (per-service repo, central deploy/GitOps repo,
   control-plane-generated)? Where does Terraform live (per-service or central
   infra repos)? Determines which repos the runner must pull beyond the ~300
   service repos, and whether some routing truth is not in git at all.
2. **Service identity:** the natural unit of "service" in this org — repo ≈
   service 1:1? Multi-service repos? Naming key (repo name vs k8s service name
   vs Envoy cluster name) and the mapping between them. Drives the stable
   node-ID scheme.
3. **Matching semantics and confidence model:** evidence tiers (config-resolved
   > contract-corroborated > shape-match), how ambiguity is represented rather
   than guessed, and how cell/tenant-aware routing affects edge semantics.
4. **Fragment and graph schema:** node/edge vocabulary (starting point:
   Understand-Anything's MIT ontology), provenance fields, stable-ID rules.
5. **Annotation sidecar format:** file layout, keying, merge behavior,
   validation.
6. **Trust/sensitivity labeling data model** (deferred feature; design must
   not preclude): label input sources, propagate to functions.
7. **Orca integration contract** (later phase): confirm/deny static edges from
   runtime state.

*(Sections to be written as questions resolve: Architecture, Data Model,
Extraction Pipeline, Matching & Confidence, Artifact Format, Annotation Layer,
Operations.)*
