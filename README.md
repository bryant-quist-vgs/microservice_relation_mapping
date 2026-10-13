---
id: project-readme
is_source_of_truth: false
derives_from: [design, design-data-model]
---

# Microservice Relation Mapping

This project builds a deterministic, evidence-based map of relationships among
microservices and platform repositories. The accepted design is the project
source of truth: [docs/DESIGN.md](docs/DESIGN.md).

## Development

Install the pinned development toolchain and run the checks with uv:

```sh
uv sync
uv run ruff check .
uv run ruff format --check .
uv run ty check
uv run pytest
uv run pre-commit run --all-files
```

`glossarian-check` is provided by the team's documentation tooling and must be
available on `PATH` when the pre-commit glossary hook runs.

## Artifact layout

The committed artifact layout follows
[the accepted data model](docs/design/data-model.md#artifact-set). Generated
directories are intentionally empty until their corresponding pipeline stages
exist; `.gitkeep` files preserve the expected structure.

```
fragments/                 # generated per-repository extraction artifacts
graph/                     # generated assembled graph and report
services/                  # generated per-service Markdown views
mapping/                   # seeded and human-corrected service mappings
annotations/               # human-authored sidecar prose
overrides/                 # human assertions and suppressions
src/microservice_relation_mapping/
```
