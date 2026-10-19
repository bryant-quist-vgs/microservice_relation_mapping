---
id: dependency-index
is_source_of_truth: false
derives_from: []
---

# Documentation Dependency Index

**Document role:** Derived index. Hand-maintained until
`build_dependency_index.py` exists (see
[deferred items](deferred-and-out-of-scope.md)). Update this file whenever a
doc is added, removed, or changes its `derives_from`.

## Sources of Truth and their dependents

### foss-evaluation-2026-07-13 (`evaluations/foss-evaluation-2026-07-13.md`)
Dependents:
- `adr/ADR-0001-build-new-python-tool.md`

### adr-0001-build-new-python-tool (`adr/ADR-0001-build-new-python-tool.md`)
Dependents:
- `DESIGN.md`
- `decision-log.md`
- `deferred-and-out-of-scope.md`

### design (`DESIGN.md`)
Dependents:
- `../README.md`
- `decision-log.md`
- `design/data-model.md`
- `design/matching.md`
- `design/annotations.md`
- `adr/ADR-0002-accept-v1-design.md`
- `../.checklists/v1-implementation.json` (sidecar: `checklist-v1-implementation`)

### design-data-model (`design/data-model.md`)
Dependents:
- `../README.md`
- `design/matching.md`
- `design/annotations.md`
- `adr/ADR-0002-accept-v1-design.md`
- `../.checklists/v1-implementation.json` (sidecar: `checklist-v1-implementation`)

### design-matching (`design/matching.md`)
Dependents:
- `adr/ADR-0002-accept-v1-design.md`
- `../.checklists/v1-implementation.json` (sidecar: `checklist-v1-implementation`)

### design-annotations (`design/annotations.md`)
Dependents:
- `adr/ADR-0002-accept-v1-design.md`
- `../.checklists/v1-implementation.json` (sidecar: `checklist-v1-implementation`)

### adr-0002-accept-v1-design (`adr/ADR-0002-accept-v1-design.md`)
Dependents:
- `decision-log.md`
- `deferred-and-out-of-scope.md`

### checklist-v1-implementation (`../.checklists/v1-implementation.json`, non-markdown SoT via sidecar)
Dependents: none. Derived from the accepted design set (design,
design-data-model, design-matching, design-annotations).

### deferred-and-out-of-scope (`deferred-and-out-of-scope.md`)
Dependents: none.

### glossary (`glossary.md`)
Dependents: none.

## Docs with no upstream (checked, `derives_from: []`)

- `evaluations/foss-evaluation-2026-07-13.md`
- `glossary.md`
- `dependency-index.md` (this file)
