---
description: Infrastructure rules for Docker, CI, gitignore, pre-commit, and Claude hooks
globs: docker/**,Dockerfile,.dockerignore,.github/workflows/**,.gitignore,.pre-commit-config.yaml,.claude/**
alwaysApply: false
---

# Infrastructure Rules

## Docker Build

- Always build from the repo root: `docker build -f docker/Dockerfile .`
- The Dockerfile must install `git` via `apt-get install -y --no-install-recommends git` because `uv-dynamic-versioning` calls git to resolve the package version at install time.
- Install production deps with `uv sync --no-dev --no-editable`. The `--no-editable` flag is required so the package is installed into `.venv` as a regular package, not a symlink.
- The full repo context is copied into the image so git history is available for versioning.

## Docker Compose Services

Two services defined in `docker/docker-compose.yml`:

| Service    | Image / Build                     | Port  |
|------------|-----------------------------------|-------|
| `backend`  | Built locally from `docker/Dockerfile` (context: `..`) | 8000  |
| `frontend` | `node:22-alpine`                  | 5173  |

Startup order enforced via `depends_on` with `condition: service_healthy`:
`backend` (healthy) -> `frontend`.

## Healthchecks

- **backend**: HTTP check on port 8000 (`/health`). Interval 10s, start period 15s.
- **frontend**: `wget` check on port 5173. Interval 15s, start period 30s.

## Env Vars in Docker

- `PYTHONPATH=.:src` -- Set so both `backend` and `app` packages are importable.
- `VITE_API_URL=http://localhost:8000` -- Frontend env var for the browser to reach the backend. Uses `localhost` because the browser runs on the host.

## Running Docker

```shell
docker compose -f docker/docker-compose.yml up --build -d
```

## CI Pipeline

Two parallel jobs in `.github/workflows/ci.yml`:

### `build` job
- Matrix: Python 3.11, 3.12, 3.13 on `ubuntu-latest`.
- Checks out with `fetch-depth: 0` (full history needed for version resolution).
- Runs `uv run python devtools/lint.py` for linting.
- Runs `uv run pytest` with `PYTHONPATH=.:src`.

### `docker-build` job
- Runs in parallel with `build`.
- Builds the backend image: `docker build -f docker/Dockerfile -t app-starter-backend:ci .`
- Does not push; build-only verification.

## Gitignore

Key project-specific entries in `.gitignore`:
- **Frontend build**: `frontend/node_modules/`, `frontend/dist/`, `frontend/.env`

## Pre-commit Hooks

Hooks defined in `.pre-commit-config.yaml`:

1. `trailing-whitespace`, `end-of-file-fixer`, `check-yaml`, `check-merge-conflict`
2. `check-added-large-files` with 5 MB limit (`--maxkb=5000`)
3. `ruff` (with `--fix`) and `ruff-format`

If `core.hooksPath` is set in global git config (e.g., by another tool), pre-commit
hooks installed via `pre-commit install` may be silently ignored. To work around this,
run hooks manually:
```shell
uv run pre-commit run --all-files
```

## Post-edit Claude Hook

Configured in `.claude/settings.json` as a `PostToolUse` hook on `Edit|Write|NotebookEdit`.

- `asyncRewake: true` -- Runs in the background; exit code 2 wakes Claude on failure.
- Timeout: 300 seconds.
- Script: `.claude/validate.sh`.

Behavior of `validate.sh`:
- Skips validation entirely for config/doc files (`.md`, `.json`, `.yaml`, `.yml`, `.toml`, `.txt`, `.sh`, `.env`, `.gitignore`, `.dockerignore`).
- Always runs `make lint` and `make test`.
- Exits 2 on any failure to trigger Claude rewake.

Do not modify `validate.sh` or `.claude/settings.json` without understanding the
rewake behavior. A non-zero exit other than 2 will not wake the model.
