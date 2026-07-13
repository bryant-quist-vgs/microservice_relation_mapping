---
id: glossary
is_source_of_truth: true
derives_from: []
---

# Glossary

## Governance

The glossary is owned by the project owner (security team). Terms are added
when they first appear in a Source-of-Truth document; a term used in two or
more docs without a glossary entry is a documentation bug. Changes land via
normal review. Structure is enforced by `glossarian-check`
(`~/bryant_repos/sedric/packages/glossarian/`); the file must lint clean
before commit.

## Definitions

### service

```glossary
short: A logical deployable unit; the primary node type in the map.
confusable: repository
```

A logical unit of deployment and ownership — what the organization would name
when asked "what is calling what." A service is a first-class entity distinct
from the repository that builds it, because deployed names drift from repo
names. Stable node IDs derive from service identity.

### repository

```glossary
short: A git repository; builds zero or more services.
confusable: service
```

A git repository in one of the two GitHub organizations. Usually builds
exactly one service, but the mapping is explicitly many-to-many and
human-correctable via the service mapping table.

### contract

```glossary
short: A normalized description of one side of an inter-service interaction.
```

One side of an inter-service interaction reduced to a canonical, comparable
form — a provider contract (a route or RPC the service exposes) or a consumer
contract (an outbound call, publish, or subscribe the service performs).
Contracts are what the assembler matches to produce cross-links.

### cross-link

```glossary
short: An edge matching a consumer contract in one repo to a provider contract in another.
see: contract
```

The core output of the mapping tool: an edge connecting a consumer contract in
one repository to a provider contract in another, carrying evidence,
provenance, and a resolution tier.

### fragment

```glossary
short: The per-repository extraction output file.
```

The deterministic, committed output of extracting a single repository:
declared endpoints, outbound calls, publishes/subscribes, infrastructure
declarations, and raw unresolved references. Fragments are a stable contract —
the assembler does not care whether a central runner or the repository's own
CI produced one.

### evidence source

```glossary
short: Any input from which nodes or edges are derived.
```

Any input the extractor or assembler derives graph data from: application
source code, Helm values and Envoy egress config, Kubernetes manifests,
Terraform, central schema repositories, or (later) Orca runtime state. Every
edge records the evidence sources supporting it.

### resolution tier

```glossary
short: The confidence class of how an edge target was determined.
```

The confidence class assigned to an edge by how its target was resolved:
human-asserted, config-resolved, contract-corroborated, or shape-matched.
Lower tiers are fallbacks; the tier is always recorded so consumers can
filter by confidence.

### unresolved outbound target

```glossary
short: An outbound call whose destination could not be statically resolved.
```

An outbound call site whose destination could not be resolved to a known
service, mesh cluster, or declared external dependency. Kept as a first-class
node rather than discarded — in an mTLS sidecar mesh this population is the
standing SSRF-suspect inventory.

### sidecar annotation

```glossary
short: Human-authored prose stored outside the generated artifact, keyed by stable node ID.
confusable: service mapping table
```

Human-authored augmentation (service intent, trust model, data sensitivity,
ownership notes) stored in committed files outside the generated artifact,
keyed by stable node ID and merged into views at build time. Regeneration
never touches it; orphaned annotations are reported, not deleted.

### service mapping table

```glossary
short: The human-correctable table mapping repositories to services.
confusable: sidecar annotation
```

The committed, auto-seeded, human-correctable table that maps repositories to
services and canonical service names to deployed names. Seeded from Helm chart
names, Kubernetes service names, GitOps app definitions, Terraform repo naming
conventions, Compass component files, and GitHub team properties; corrections
survive regeneration.

### cell

```glossary
short: A tenant-isolation partition of a service's deployment.
```

A partition (Kubernetes namespace) isolating a group of tenants, e.g.
`vault-cell-knox-payments-02`. Cells of one service collapse into a single
logical service node; cell membership is recorded as an attribute where
statically visible. Per-tenant cell routing is dynamic and out of static
scope.

### logical edge

```glossary
short: A service-to-service relationship independent of cell or tenant routing.
see: cell
```

An edge between logical services, abstracted over cells and tenants. The
static map models logical edges only; physical per-cell routes are a later
runtime-reconciliation concern.

## Confusable Pairs

- **service vs repository** — a repository builds a service; annotations,
  trust labels, and cross-links attach to services, while extraction and
  fragments attach to repositories.
- **contract vs cross-link** — a contract is one side (consumer or provider)
  in canonical form; a cross-link is the matched pair.
- **sidecar annotation vs service mapping table** — both are committed,
  regeneration-surviving human inputs; annotations add prose to nodes, the
  mapping table corrects identity (which repo is which service).

## Renames and deprecated terms

None.
