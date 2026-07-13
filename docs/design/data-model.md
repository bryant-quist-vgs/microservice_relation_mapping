---
id: design-data-model
is_source_of_truth: true
derives_from: [design]
---

# Data Model — Fragments, Graph, and Stable Identity

**Status:** DRAFT PROPOSAL — for owner review; not accepted.
**Document role:** Source of Truth for the artifact schemas once accepted.
Derived from [DESIGN.md](../DESIGN.md) determinations D1–D8.

## Artifact set

All artifacts are plain, deterministic, diff-friendly files committed to the
map repository:

```
map-repo/
  fragments/<org>__<repo>.json      # per-repo extraction output (generated)
  graph/graph.json                  # assembled cross-linked graph (generated)
  graph/report.md                   # assembly stats, gaps, suspects (generated)
  services/<service-id>.md          # per-service Markdown views (generated)
  mapping/services.yaml             # repo↔service mapping table (seeded + human-edited)
  annotations/<service-id>.md       # sidecar prose (human-only)
  overrides/assertions.yaml         # human-declared edges (human-only)
  overrides/suppressions.yaml       # human-suppressed edges (human-only)
```

Generated files carry a `generated_by` header (tool version, input commit
SHAs) and are fully rewritten on every run. Human files are never written by
the generator (see [annotations](annotations.md)).

Determinism rules: stable key ordering, sorted arrays, no timestamps inside
generated payloads (run metadata lives in one `meta` block per file), so
regeneration against unchanged inputs is byte-identical and `git diff` is
semantically meaningful.

## Stable identity

Node IDs are strings with a typed prefix. They must survive refactors, so
they never embed file paths or line numbers (those live in evidence).

| Node kind | ID form | Example |
|---|---|---|
| service | `svc:<canonical-name>` | `svc:knox-service` |
| repository | `repo:<org>/<name>` | `repo:verygoodsecurity/knox` |
| HTTP endpoint | `ep:<svc>/http/<METHOD>/<normalized-path>` | `ep:knox-service/http/GET/users/{param}` |
| gRPC method | `ep:<svc>/grpc/<package.Service/Method>` | `ep:knox-service/grpc/vgs.knox.v1.Vault/Redact` |
| channel (queue/topic/stream/bus) | `chan:<kind>/<name>` | `chan:sqs/card-update-jobs` |
| external target | `ext:<normalized-host>` | `ext:api.stripe.com` |
| unresolved target | `unres:<repo>/<hash-of-callsite-signature>` | `unres:verygoodsecurity/calm-api/3f9a…` |
| team | `team:<gh-team-tag>` | `team:team-payments` |

Canonical service names come from the [service mapping
table](annotations.md#the-service-mapping-table). Path normalization: path
parameters collapse to `{param}`; trailing slashes stripped; case preserved
for path literals, upper-cased for methods.

`unres:` IDs hash the *call-site signature* (repo, function qualified name,
callee expression shape) — not file/line — so an unresolved target keeps its
ID (and its annotations/triage state) across cosmetic moves.

## Node schema

```json
{
  "id": "svc:knox-service",
  "kind": "service",
  "name": "knox-service",
  "attrs": {
    "repos": ["repo:verygoodsecurity/knox"],
    "team": "team:team-payments",
    "cells": ["vault-cell-knox-payments-01", "…"],
    "languages": ["java"],
    "deployment_methods": ["vgs-app-sync"]
  }
}
```

`attrs` is kind-specific and open (new fields are additive). Every node also
carries `evidence` (see below) explaining why it exists.

Kinds in v1: `service`, `repository`, `endpoint`, `channel`, `external`,
`unresolved`, `team`. Explicitly not v1 (deferred, additive later):
`datastore`, `lambda-function` as distinct kinds, `cell` as a node.

## Edge schema

```json
{
  "src": "svc:card-on-file-api",
  "dst": "ep:knox-service/grpc/vgs.knox.v1.Vault/Redact",
  "kind": "calls",
  "tier": "config-resolved",
  "evidence": [
    {
      "source": "code",
      "repo": "repo:verygoodsecurity/card-on-file-api",
      "loc": "src/main/java/…/KnoxClient.java:88",
      "detail": "grpc stub call to 127.0.0.1:10001"
    },
    {
      "source": "helm-envoy",
      "repo": "repo:verygood-ops/vgs-gitops",
      "loc": "product/payments/card-on-file-api/values.yaml",
      "detail": "serviceEnvoy.egress knox-split listenPort 10001 -> knox-service.vault-cell-knox-payments-01.svc.cluster.local:8002"
    }
  ],
  "ambiguous_with": []
}
```

Edge kinds in v1:

| Kind | src → dst | Meaning |
|---|---|---|
| `exposes` | service → endpoint | provider side |
| `calls` | service → endpoint \| external \| unresolved | sync consumer side (HTTP/gRPC) |
| `publishes` | service → channel | async producer |
| `consumes` | service → channel | async consumer |
| `declares` | repository → channel \| service | Terraform/IaC declaration |
| `builds` | repository → service | from the mapping table |
| `owns` | team → repository | from GH custom properties |

Async cross-links are the `publishes`/`consumes` pairs sharing a channel
node — no separate edge kind needed. Envoy-egress routing is not an edge
kind; it is *evidence* on a `calls` edge.

`evidence[].source` enum (v1): `code`, `helm-envoy`, `k8s-manifest`,
`terraform`, `proto-contract`, `http-spec`, `gh-metadata`, `compass`,
`human` (assertions), `shape-match`. Reserved for later: `orca-runtime`.

`tier` is the resolution tier from [matching.md](matching.md). `ambiguous_with`
lists sibling candidate edge targets when resolution found several (never
silently picking one).

## Fragment schema

A fragment is one repo's extraction output, *before* cross-repo resolution.
It contains raw observations only — no guesses:

```json
{
  "meta": { "repo": "verygoodsecurity/card-on-file-api", "commit": "…",
            "extractor_version": "…", "team": "team-payments" },
  "provides": [ { "protocol": "http", "method": "GET", "path": "/cards/{id}",
                  "framework": "spring", "handler": "CardController.get",
                  "loc": "…" } ],
  "consumes_sync": [ { "protocol": "grpc", "symbol": "vgs.knox.v1.Vault/Redact",
                       "target_expr": "127.0.0.1:10001", "target_env_vars": [],
                       "loc": "…", "dynamic_url": false } ],
  "channels": [ { "kind": "sqs", "direction": "publish",
                  "name_expr": "env:CARD_JOBS_QUEUE_URL", "loc": "…" } ],
  "infra": [ { "source": "terraform", "resource": "aws_sqs_queue",
               "name": "card-update-jobs", "loc": "…" } ],
  "deploy": [ { "source": "helm-envoy", "egress": [ { "listen_port": 10001,
               "target_host": "knox-service.….svc.cluster.local",
               "target_port": 8002, "protocol": "grpc" } ] } ],
  "identity_hints": [ { "source": "compass", "name": "card-on-file-api" } ],
  "unparsed": [ { "path": "…", "reason": "grammar-error" } ]
}
```

Key properties:

- `target_expr` / `name_expr` preserve the *raw* expression (literal,
  env-var reference, concatenation shape) — resolution happens at assembly.
- `dynamic_url: true` flags call sites whose URL/host is built from
  variables — the SSRF-relevant attribute, set by the extractor.
- `unparsed` makes coverage gaps data (heterogeneity principle).
- Fragments from GitOps/infra repos populate `deploy`/`infra` blocks keyed
  by the service the values file belongs to; the assembler joins them.

## Reserved attachment points (do-not-preclude items)

- **Trust/sensitivity labels:** nodes and endpoints accept a future
  `labels: {trust: …, sensitivity: …}` attr; `evidence[].source` enum is
  open; label propagation will be an assembly pass, not a schema change.
- **Security-mapping merge:** node IDs are namespaced by prefix, so a
  sibling initiative can add prefixes without collision; `graph.json` `meta`
  carries a `schema_version`.
- **Orca reconciliation:** edges accept a future `runtime: {confirmed_at,
  observed_calls}` block sourced `orca-runtime`.

## Size and diffability estimate

~300 fragments at 10–200 KB each; assembled graph optimistically
1k–3k service/endpoint/channel nodes and low-10k edges — well within
plain-JSON handling; if graph.json exceeds review-friendly size it can shard
by service (`graph/<service-id>.json`) without schema change.
