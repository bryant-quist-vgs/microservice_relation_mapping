---
id: design-annotations
is_source_of_truth: true
derives_from: [design, design-data-model]
---

# Annotations, Mapping Table, and Overrides

**Status:** DRAFT PROPOSAL — for owner review; not accepted.
**Document role:** Source of Truth for the human-input layer once accepted.
Derived from [DESIGN.md](../DESIGN.md) D7 and the [data model](data-model.md).

## Principle

Every human input lives in files the generator never writes. The generator
*reads* them at assembly, merges them into views, and *reports* on their
health (orphans, conflicts, staleness) — it never edits, moves, or deletes
them. This is the anti-lesson from every FOSS candidate evaluated.

## The service mapping table — `mapping/services.yaml`

The identity backbone (D7). One entry per service:

```yaml
services:
  knox-service:
    repos: [verygoodsecurity/knox]
    deployed_names: [knox-service]           # k8s/Helm names that mean this service
    terraform_repos: [verygood-ops/terraform-aws-vgs-knox-service]
    team: team-payments
    status: active                            # active | deprecated | unknown
    seeded_by: [helm-chart, terraform-naming, compass]   # provenance of the seed
    confirmed: false                          # flips true on human review
```

Workflow:

- **Seeding:** the runner proposes new/changed entries from evidence (Helm
  chart names, k8s service names, GitOps app definitions,
  `terraform-aws-vgs-*` naming, `compass.yml`, GH `team` property) into
  `mapping/services.proposed.yaml`. A human promotes entries into
  `services.yaml` (mechanical for the obvious 90%).
- **Corrections are durable:** the seeder never rewrites a promoted entry;
  it reports disagreements (e.g. a deployed name that vanished) in the
  assembly report.
- Deployables matching no entry and entries matching no deployable are
  loudly reported (D7).

## Sidecar annotations — `annotations/<service-id>.md`

One Markdown file per annotated service (same stable ID as the node),
frontmatter + free prose:

```markdown
---
node: svc:knox-service
reviewed: 2026-07-13
labels:            # reserved: trust/sensitivity vocabulary TBD (deferred item)
  exposure: internal
---

# knox-service

**Intent:** Tokenization vault for payment credentials; partitioned into
per-tenant-group cells.

**Trust model:** Accepts calls only from … via mTLS sidecar; treats the
`tenant` header as authenticated by …

**Triage notes:** …
```

Rules:

- Keyed by node ID — services, but also `chan:` and `unres:` nodes may be
  annotated (annotating an unresolved target with triage state — "checked
  2026-07, benign S3 presign" — is the SSRF-workflow use case).
- Merged into the per-service Markdown views and queryable via CLI/MCP
  (`annotation` field on the node).
- An annotation whose node ID no longer exists is an **orphan**: reported,
  never deleted. Because IDs are refactor-stable, orphans mean real change.
- `labels` is a reserved namespace for the deferred trust/sensitivity
  scheme; free keys allowed now, vocabulary standardized later.

## Assertions — `overrides/assertions.yaml`

Human-declared edges (T0 in [matching.md](matching.md)):

```yaml
assertions:
  - src: svc:calm-api
    dst: svc:knox-service
    kind: calls
    reason: "gRPC via dynamically-built channel; see PYMTACP-1234"
    author: bryant.quist
    date: 2026-07-13
```

Required `reason`, `author`, `date`. Reported when they conflict with or
duplicate machine-resolved edges (stale assertions decay into documentation
bugs otherwise).

## Suppressions — `overrides/suppressions.yaml`

Same shape plus `expires` (optional). Removes false-positive edges from the
graph; suppressed edges remain in the assembly report as tombstones. A
suppression whose edge no longer gets generated is an orphan → reported.

## Validation

A `validate` subcommand (also run at assembly start) checks: YAML/frontmatter
schema, node-ID syntax, duplicate keys, unknown edge kinds, missing
required fields, and orphan detection. Validation failures in human files
fail loudly but do not block graph generation (the map must not go stale
because one annotation has a typo — the report carries the errors).
