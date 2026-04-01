---
description: Backend (FastAPI) and Frontend (React) rules for app_starter
globs: backend/**,frontend/**
alwaysApply: false
---

# Backend and Frontend Rules

## FastAPI App Structure

- The `backend/` package lives at the repo root (not under `src/`).
- Always run the backend with `PYTHONPATH=.:src` so both `backend` and `app` are importable.
- The FastAPI application object is `app` in `backend/main.py`.
- The items router is mounted at prefix `/api`.
- CORS is configured to allow `http://localhost:5173` (the Vite dev server). Do not add wildcard origins.
- Use `make serve` to start the backend on port 8000 with hot-reload.

## API Endpoints

- `GET /health` returns `{"status": "ok"}` with status 200. No authentication required.
- `GET /api/items` returns a list of `Item` objects.
- `POST /api/items` accepts an `ItemCreate` JSON body and returns an `Item`.

## Schemas

- Defined in `backend/schemas.py` as Pydantic `BaseModel` subclasses.
- `Item`: `id: int`, `name: str`
- `ItemCreate`: `name: str`

## Testing

- Tests live in `backend/tests/test_api.py`.
- Use `fastapi.testclient.TestClient` with the `app` from `backend.main`.
- Three tests required:
  1. `test_health` -- GET `/health` returns 200 and `{"status": "ok"}`.
  2. `test_get_items` -- GET `/api/items` returns 200 and a list.
  3. `test_create_item` -- POST `/api/items` with `{"name": "Test Item"}` returns 200.

## Frontend

- The frontend is a Vite + React + TypeScript app in `frontend/`.
- Use `make frontend` to start the dev server on port 5173.
- `VITE_API_URL` env var controls the backend URL; defaults to `http://localhost:8000`. Set it in `frontend/.env` (copy from `.env.example`).
- TypeScript interfaces in `App.tsx` must mirror the Pydantic schemas in `backend/schemas.py`. Keep them in sync when either side changes.

## Running the Full Stack

- Backend: `make serve` (port 8000, `PYTHONPATH=.:src`).
- Frontend: `make frontend` (port 5173).
- The frontend calls the backend directly via `VITE_API_URL`. CORS on the backend allows the frontend origin.
- Run `make setup` once to install both Python and Node dependencies.
