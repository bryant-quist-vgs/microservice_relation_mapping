# Agent guidance

This is a living document. Keep it brief, and extend it when work reveals a
durable project convention or a recurring, non-secret environment issue.

## Project premise

Build a deterministic, regenerable map of relationships across roughly 300
heterogeneous microservice and platform repositories. The map supports security
triage by linking code-level calls to service endpoints and infrastructure
evidence. Unresolved outbound targets are first-class findings, and human
annotations must survive regeneration.

Treat `docs/DESIGN.md`, accepted documents under `docs/design/`, accepted ADRs,
`docs/glossary.md`, `docs/dependency-index.md`, `docs/decision-log.md`, and the
active checklist task as source of truth. Design changes require a logged
decision. Prefer files under 500 lines; files intended for agent consumption
must remain under 800 lines.

## Working rules

- Preserve unrelated and concurrent changes.
- Never edit `docs/checklists/v1-implementation.json` by hand. Use the
  project-local scripts under `scripts/checklist/`.
- When changing a script, read its sibling `*_contract.md` first, keep the
  script/contract/test trio coherent, and run the paired test.
- Do not weaken verification, bypass sandbox/approval controls, or invent model
  identifiers to get past an environment failure.
- Worker and assessor sessions do not create commits, switch branches, push,
  open PRs, merge, or edit checklist state directly. The lifecycle harness owns
  those operations.
- Only an operator explicitly driving the lifecycle should run `start`,
  `restart`, `assess`, `open_pr`, `finalize`, or `complete`.

## Common commands

Run from the repository root:

```sh
# Read-only environment and checklist status
scripts/checklist/next_task.sh status
python3 scripts/checklist/query.py status \
  docs/checklists/v1-implementation.json --format json

# Checklist tooling verification (hermetic; no real model or network)
zsh scripts/checklist/next_task_test.sh
python3 scripts/checklist/codex_run_summary_test.py
zsh -n scripts/checklist/next_task.sh

# Repository hygiene
git diff --check
git status --short

# Default project verification after Python scaffolding exists
uv run pre-commit run --all-files
uv run pytest
```

See `scripts/checklist/README.md` for lifecycle actions and environment
controls.

## Surface environment issues

Continue safe, read-only diagnosis, but stop before a blocked state-changing
action. Tell the operator:

1. the exact failing command and exit code;
2. the shortest useful error output;
3. the current branch and relevant `git status --short` entries;
4. what prerequisite is missing or uncertain; and
5. the safest next action or decision needed from the operator.

Do not silently install dependencies, change authentication, disable checks,
use unsafe Codex approval/sandbox modes, or discard local changes. Never record
credentials, tokens, tenant data, or other secrets here.

Add recurring project-specific findings below with a date, symptom, impact, and
resolution or operator action. Update or remove stale entries when resolved.

### Known environment notes

- 2026-07-15: Before task `0.1` creates the Python scaffold,
  `pyproject.toml` and the default uv verification gate may be absent. Report
  that bootstrap condition; do not substitute an unrelated gate.
- 2026-07-15: Checklist status may report a missing actor in a fresh shell.
  Read-only commands still work, but checklist writes require the operator to
  provide the documented actor/model/session environment.
