---
description: Tooling, build system, and CI rules for python_nbdev_starter
globs: "*"
alwaysApply: true
---

# Tooling Rules

## Package Management

- Always use `uv` for all package and environment operations. Never use `pip`, `pip install`, or bare `python` directly.
- Install dependencies: `uv sync --all-extras`
- Add a new dependency: `uv add <package>`
- Run any command in the project venv: `uv run <command>`
- Upgrade all deps: `uv sync --upgrade --all-extras --dev`

## nbdev Commands

- Export notebooks to Python: `uv run nbdev_export`
- Test notebooks: `uv run nbdev_test`
- Build docs: `uv run nbdev_docs`
- Clean notebook outputs: `uv run nbdev_clean`
- Always run `nbdev_export` after editing notebooks before running lint or tests.

## Make Targets

| Target | What it does |
|---|---|
| `make` (default) | Runs `agent-rules`, `install`, `lint`, `test` in order |
| `make install` | `uv sync --all-extras` |
| `make lint` | `uv run python devtools/lint.py` (codespell, ruff check --fix, ruff format, basedpyright) |
| `make test` | `uv run pytest` |
| `make nbdev-export` | Export notebooks to `python_nbdev_starter/` |
| `make nbdev-test` | Run tests inside notebooks |
| `make nbdev-docs` | Build documentation |
| `make nbdev-clean` | Strip notebook outputs |
| `make upgrade` | `uv sync --upgrade --all-extras --dev` |
| `make build` | `nbdev_export` + `uv build` |
| `make clean` | Removes dist, caches, .venv |
| `make agent-rules` | Regenerates `CLAUDE.md` and `AGENTS.md` from `.cursor/rules/*.mdc` |

## Testing

- Test paths: `python_nbdev_starter`. Configured via `testpaths` in `pyproject.toml`.
- `pythonpath = ["."]` is set in pytest config so imports resolve.
- `python_files = ["*.py"]` — pytest discovers tests in any `.py` file.
- Run all tests: `make test`
- Run notebook tests: `make nbdev-test`
- Run a single test with output: `uv run pytest -s path/to/file.py`

## Linting

- `make lint` runs `devtools/lint.py`, which executes in order:
  1. `codespell --write-changes` on `python_nbdev_starter devtools README.md`
  2. `ruff check --fix` on `python_nbdev_starter devtools`
  3. `ruff format` on `python_nbdev_starter devtools`
  4. `basedpyright --stats` on `python_nbdev_starter devtools`
- Always run `make lint` after changes and fix all errors before considering work complete.

## Versioning

- Uses `uv-dynamic-versioning` which reads version from git tags at build time.
- The `git` binary must be available for versioning to work.
- `fetch-depth: 0` is required in CI checkout for full tag history.
- Do not hardcode version strings; the version is always derived from git.

## CI Pipeline

- `test.yaml` uses `fastai/workflows/nbdev-ci@master` — the standard nbdev CI workflow.
- Runs on push/PR/workflow_dispatch.

## Post-Edit Validation Hook

- `.claude/settings.json` registers a `PostToolUse` hook on `Edit|Write|NotebookEdit`.
- The hook runs `.claude/validate.sh` with a 300-second timeout and `asyncRewake: true`.
- Conditional logic in `validate.sh`:
  - **Skips entirely** for non-source files (`.md`, `.json`, `.yaml`, `.yml`, `.toml`, `.txt`, `.sh`, `.env`, `.gitignore`, `.dockerignore`).
  - **For `.ipynb` files**: runs `nbdev_export` first, then `make lint` and `make test`.
  - **For `.py` files**: always runs `make lint` and `make test`.
- Exit code 2 on failure wakes the model to address the issue.

## Pre-commit Hooks

- To run hooks manually: `uv run pre-commit run --all-files`
- Never skip pre-commit checks. If a hook fails, fix the underlying issue.
