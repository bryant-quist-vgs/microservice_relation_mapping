---
id: glossary
is_source_of_truth: true
derives_from: []
---

# Glossary

**Document role:** Source of Truth for project terminology.

> **PLACEHOLDER.** The team has a required glossary structure; this file will
> be rewritten to that specification once provided. Terms are accumulating
> informally below so they are not lost.

- **Contract** — a normalized description of one side of an inter-service
  interaction (e.g. a provider's route definition, a consumer's outbound HTTP
  call), reduced to a canonical ID so the two sides can be matched.
- **Cross-link** — an edge connecting a consumer contract in one repository to
  a provider contract in another; the core output of the mapping tool.
- **Evidence source** — any input the extractor derives edges from (source
  code, Terraform, runtime state via Orca). Every edge carries provenance
  naming its evidence source(s).
- **Sidecar annotation** — human-authored prose (service intent, trust model,
  ownership) stored outside the generated artifact, keyed by stable node ID,
  merged into views at build time so regeneration never destroys it.
