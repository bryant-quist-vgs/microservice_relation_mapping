---
id: design-matching
is_source_of_truth: true
derives_from: [design, design-data-model]
---

# Matching & Confidence Model

**Status:** DRAFT PROPOSAL — for owner review; not accepted.
**Document role:** Source of Truth for cross-repo resolution semantics once
accepted. Derived from [DESIGN.md](../DESIGN.md) D3/D6/D8 and the
[data model](data-model.md).

## Principle

The assembler never guesses silently. Every edge carries the tier that
produced it; anything below the top tiers is visibly marked; anything
unresolvable stays unresolved and is *reported as a finding*, because in
this environment an unexplained outbound call is itself security signal.

## Resolution tiers (highest wins; all matches recorded)

### T0 — human-asserted

From `overrides/assertions.yaml`. Wins over everything, but conflicts with
machine-resolved edges are reported (a stale assertion is a documentation
bug, not silent truth).

### T1 — config-resolved

The target is determined by joining code observations with deployment
config. Sub-resolvers, in order of specificity:

1. **Envoy egress join:** call-site target `127.0.0.1:<p>` or
   `localhost:<p>` joins `serviceEnvoy.egress[].listen_port == p` for the
   same service's Helm values; `target_host` k8s FQDN parses to
   (service-name, namespace) → service node via the mapping table.
2. **K8s FQDN literal:** call target is directly a
   `<name>.<namespace>.svc.cluster.local` (or short `<name>.<namespace>`)
   form.
3. **Env-var resolution:** call target is `env:VAR`; VAR's value is found in
   the service's Helm values / task definition / Terraform, then resolved as
   a literal (possibly recursing into 1–2).
4. **Terraform channel join:** SDK channel operations whose `name_expr`
   resolves (directly or via env-var) to a Terraform-declared
   queue/topic/stream name. Producer and consumer both joining the same
   declared channel is config-resolved async linking.
5. **Gateway route table:** where an internal gateway's route config is in
   git, path-prefix → backend mappings resolve calls that traverse it.

### T2 — contract-corroborated

Consumer and provider are linked through a shared, centrally-defined
contract even when the physical target is not statically visible:

1. **Central proto symbol:** consumer imports/calls generated stub for
   `pkg.Service/Method` from `verygoodsecurity/messages`; exactly one
   service implements that gRPC service → link. (The `messages` repo makes
   this the expected common case for internal gRPC.)
2. **HTTP spec join:** consumer's method+path matches an OpenAPI spec in
   `verygoodsecurity/product` that is attributable to exactly one service.

### T3 — shape-matched

GitNexus-style canonical contract matching as the last resort:
consumer `http::GET::/cards/{param}` matches provider route shape in
exactly one other service. Guards:

- Noisy-shape filter: health/readiness/metrics endpoints, root path,
  single-`{param}` paths, and shapes provided by ≥ N services are excluded
  from auto-linking (they emit `ambiguous_with` instead).
- Shape matches never override or merge with T1/T2 results; they only fill
  gaps.

### Unresolved (not a tier — a finding)

A consumer contract with no match above becomes/points to an `unres:` or
`ext:` node:

- Known-external hosts (allowlist of vendor domains, plus anything
  resolving outside cluster DNS) → `ext:` node — the *declared external
  dependency inventory*.
- Everything else → `unres:` node with the `dynamic_url` flag preserved.
  **Ranked report:** `dynamic_url: true` + user-input-adjacent code paths
  rank highest — this is the standing SSRF-suspect list (D3).

## Ambiguity representation

When a resolver yields multiple candidates, the assembler emits **no
resolved edge**. It emits the consumer contract with `ambiguous_with:
[candidate node IDs]`, and the assembly report lists every ambiguity with
its evidence so a human can either fix the source of drift or add a T0
assertion. Ambiguity is a first-class, diffable state — the count trending
down is a health metric.

## Conflict rules

- Tier order: T0 > T1 > T2 > T3. A lower-tier match *agreeing* with a
  higher-tier edge is appended to that edge's evidence (corroboration).
  A lower-tier match *disagreeing* is recorded in the report, not the graph.
- T1 sub-resolvers are ordered; the first hit wins, later hits corroborate
  or report-conflict identically.
- Suppressions (`overrides/suppressions.yaml`) remove an edge from the
  graph but leave a tombstone in the report (suppressed edges must stay
  auditable).

## Test-code and generated-code policy

Call sites in test directories (per-language conventions +
`unparsed`-style explicit config) are extracted but marked
`context: test`; they are excluded from the default graph and views, kept
in fragments (a test that calls a service is still weak evidence of a
relationship — and occasionally the only evidence). Generated code
(protobuf stubs, openapi clients) is attributed to its generator contract
(feeding T2), never treated as hand-written call sites.

## Assembly report

`graph/report.md` (generated, human-readable) carries per-run:

- coverage: repos processed / unparsed files / extractor gaps by language;
- resolution mix: edge counts per tier, trend vs previous committed run;
- findings: unresolved outbound targets (SSRF-ranked), ambiguities,
  T0-vs-machine conflicts, orphaned annotations/assertions, unmapped
  deployables and repo-less services (D7);
- channel orphans: declared-but-unused and used-but-undeclared channels.

The report is the primary "is the map healthy" surface and is deliberately
boring, sorted, and diffable.
