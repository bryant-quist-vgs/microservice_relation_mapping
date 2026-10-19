# Quality-gate targets for the sedric_lite task lifecycle.
# `.sedric-lite.toml` [gate].targets names the targets task_gate runs, in
# order, via `make <target>`; each must exit non-zero on failure.

# Python trees the code gates cover. scripts/checklist/ is untracked vendored
# tooling with its own test harness (see AGENTS.md) and is deliberately out.
PY_PATHS := src/

.PHONY: format format-check test type lint docs-lint

format:
	uv run ruff format $(PY_PATHS)

format-check:
	uv run ruff format --check $(PY_PATHS)

test:
	uv run pytest $(PY_PATHS)

type:
	uv run ty check $(PY_PATHS)

lint:
	uv run ruff check $(PY_PATHS)

# Docs gates: glossary structure (glossarian spec), inbound glossary.md#slug
# link resolution, and the file-size standard (.llm-file-size-guard.toml:
# warn 500 / fail 800). All exit non-zero on violations; size warnings alone
# do not fail the gate. glossarian-* are standalone PATH tools (installed from
# the sedric repo's installer).
docs-lint:
	glossarian-check docs/glossary.md
	glossarian-gather docs/ --failures
	llm-size-guard check
