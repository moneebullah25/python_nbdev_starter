# Makefile for easy development workflows.

.DEFAULT_GOAL := default

.PHONY: default install lint test pytest build clean nbdev-export nbdev-test nbdev-docs nbdev-clean agent-rules

default: agent-rules install lint test

install:
	uv sync --all-extras --all-groups

lint:
	uv run python devtools/lint.py

test:
	uv run nbdev-test

pytest:
	uv run pytest

nbdev-export:
	uv run nbdev-export

nbdev-test:
	uv run nbdev-test

nbdev-docs:
	uv run nbdev-docs

nbdev-clean:
	uv run nbdev-clean

upgrade:
	uv sync --upgrade --all-extras --dev

build:
	uv run nbdev-export
	uv build

agent-rules: CLAUDE.md AGENTS.md

CLAUDE.md: .cursor/rules/general.mdc .cursor/rules/python.mdc .cursor/rules/project.mdc
	cat .cursor/rules/general.mdc .cursor/rules/python.mdc .cursor/rules/project.mdc > CLAUDE.md

AGENTS.md: .cursor/rules/general.mdc .cursor/rules/python.mdc .cursor/rules/project.mdc
	cat .cursor/rules/general.mdc .cursor/rules/python.mdc .cursor/rules/project.mdc > AGENTS.md

clean:
	-rm -rf dist/
	-rm -rf *.egg-info/
	-rm -rf .pytest_cache/
	-rm -rf .mypy_cache/
	-rm -rf .venv/
	-rm -rf CLAUDE.md AGENTS.md
	-find . -type d -name "__pycache__" -exec rm -rf {} +
