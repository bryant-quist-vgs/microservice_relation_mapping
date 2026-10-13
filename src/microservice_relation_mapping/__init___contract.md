Contract version: v0

# Package Initializer — package identity export: Contract

This module defines the importable package boundary for Microservice Relation
Mapping and exposes the package version used by early tooling and tests.

## Inputs

No inputs.

## Outputs

- **`microservice_relation_mapping.__version__`** — string constant identifying
  this package release.
  Load-bearing: packaging and the paired smoke test expect the project version
  to be available without performing I/O.

## Behaviors

1. **Expose package version.** Defines `__version__` as the version declared
   by the initial project skeleton.
   Load-bearing: callers can inspect the package identity without requiring
   the project to be installed with additional runtime dependencies.

Any behavior the module performs that is not listed here is undeclared and
constitutes drift.

## Declared capability surface

- **Filesystem reads:** No filesystem reads.
- **Filesystem writes:** No filesystem writes.
- **Network access:** No network access.
- **Subprocess invocation:** No subprocess invocation.
- **Environment variables read:** No environment variables read.
- **Secrets handled:** No secrets handled.
- **Privilege escalation:** No privilege escalation.

## Assumptions for operation

- Python 3.12 or later imports the module.
- The module is packaged from the repository's `src/` layout.
- The package version remains synchronized with the version in `pyproject.toml`.

## Anti-patterns this module must not do

- Do **not** perform configuration discovery, logging setup, network access,
  or filesystem access at import time. Importing the package must remain
  dependency-free and side-effect-free.

## Revision rules

- Changing the exported version shape or adding import-time behavior requires
  a contract version bump and matching test coverage.
- The module header references the contract version it was built against.
