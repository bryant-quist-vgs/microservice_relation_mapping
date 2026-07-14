---
id: adr-0002-accept-v1-design
is_source_of_truth: true
derives_from: [design, design-data-model, design-matching, design-annotations]
---

# ADR-0002: Accept the v1 design (deterministic fragments, tiered matching, human-input layer)

**Date:** 2026-07-14
**Status:** Accepted
**Document role:** Source of Truth for the acceptance decision and the
review-contested choices. The designs themselves live in
[DESIGN.md](../DESIGN.md) and its sub-documents.

## Context

Following ADR-0001 (build new in Python), the design was developed
interactively with the project owner across three rounds (determinations
D1–D8) and three proposal documents. The owner reviewed the proposals on
2026-07-13/14.

## Decision

Accept the v1 design as recorded in [DESIGN.md](../DESIGN.md),
[data-model.md](../design/data-model.md), [matching.md](../design/matching.md),
and [annotations.md](../design/annotations.md), with one review amendment.

## Choices examined during review

| Choice | Outcome |
|---|---|
| Unresolved-target identity | **Amended.** Original signature (repo, function qualified name, callee shape) collides across same-named code in different namespaces. Amended to include the AST-derived namespace (declared package/module, never the filesystem path); residual duplicates get a deterministic ordinal suffix with a report-flagged collision group; assembler hard-fails if uniqueness still fails. File/line remain evidence-only so triage state survives refactors. |
| Mapping-table workflow | **Confirmed as proposed.** Propose-then-promote (`services.proposed.yaml` → human promotion); accepted friction in exchange for trusted identity. |
| Test-code call sites | **Confirmed as proposed.** Extracted and kept in fragments marked `context: test`; excluded from the default graph and views. |
| Datastore nodes (shared DB/cache coupling) | **Confirmed deferred.** Not v1; the node-kind vocabulary is additive so this lands later without schema breakage. Recorded in deferred items. |

## Consequences

- Design phase is closed; changes to accepted design docs now require a
  logged decision (decision log + ADR when substantive).
- Implementation planning proceeds: work checklist authored in the Sedric
  checklist schema (owner-provided format), then implementation.
- The unres-identity amendment slightly increases extractor obligations:
  every language extractor must emit the AST-derived namespace for each
  call site.
