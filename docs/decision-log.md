---
id: decision-log
is_source_of_truth: false
derives_from: [adr-0001-build-new-python-tool, design]
---

# Decision Log

**Document role:** Derived index of decisions. Each substantive decision's
Source of Truth is its ADR (or the noted discussion); this log only summarizes.

| # | Date | Decision | Source of Truth | Status |
|---|---|---|---|---|
| 1 | 2026-07-13 | Build a purpose-built Python tool; do not adopt/fork codegraph, graphify, Understand-Anything, or GitNexus | [ADR-0001](adr/ADR-0001-build-new-python-tool.md) | Accepted |
| 2 | 2026-07-13 | No parallel tactical SSRF sweep of the repo fleet; effort focuses on the durable mapping tool (the separate active investigation covers the tactical need) | Design discussion 2026-07-13 (owner decision) | Accepted |
| 3 | 2026-07-13 | Project documentation lives in this repository (`microservice_relation_mapping`), structure per team standards, started immediately | Design discussion 2026-07-13 (owner decision) | Accepted |
| 4 | 2026-07-13 | Documentation dependency tracking follows the doc-ripple-check convention (frontmatter `id`/`derives_from`/`is_source_of_truth`); index hand-maintained until tooling lands | [dependency-index.md](dependency-index.md) note; tooling deferred | Accepted |
| 5 | 2026-07-13 | v1 scope determinations: central handoff-ready runner topology; four protocol families (HTTP, AWS messaging, gRPC, Kafka/RabbitMQ/NATS); Envoy/k8s config-resolved targets with shape-match as fallback; unresolved outbound targets as first-class nodes; v1 surfaces = CLI + per-service Markdown + MCP (no HTML viewer) | [DESIGN.md](DESIGN.md) §Resolved design determinations | Accepted |
