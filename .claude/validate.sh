#!/usr/bin/env bash
# Post-edit validation hook. Reads the changed file path from stdin JSON,
# then runs make targets appropriate for what changed.
# Exit 2 on failure so asyncRewake wakes the model.

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Extract changed file path from hook JSON payload
CHANGED_FILE=$(python3 -c "
import sys, json
data = json.load(sys.stdin)
inp = data.get('tool_input', {})
print(inp.get('file_path', '') or inp.get('notebook_path', ''))
" 2>/dev/null || echo "")

# Regenerate CLAUDE.md when rule files change
if echo "$CHANGED_FILE" | grep -qE "(\.cursor/rules/.*\.mdc$|\.claude/rules/.*\.md$)"; then
    echo "--- make agent-rules ---"
    if ! make agent-rules; then
        echo "FAILED: make agent-rules"
        exit 2
    fi
    exit 0
fi

# Skip validation for non-source files
if echo "$CHANGED_FILE" | grep -qE "\.(mdc|md|json|yaml|yml|toml|txt|sh|env|gitignore|dockerignore)$"; then
    exit 0
fi

FAILED=0

run() {
    echo "--- $* ---"
    if ! "$@"; then
        echo "FAILED: $*"
        FAILED=1
    fi
}

# For notebook changes: clean (strip outputs) then export (sync Python files).
# Mirrors exactly what CI does: nbdev-clean must be a no-op on committed notebooks,
# and nbdev-export must produce no diff vs committed Python files.
if echo "$CHANGED_FILE" | grep -qE "\.ipynb$"; then
    echo "--- uv run nbdev-clean ---"
    if ! uv run nbdev-clean; then
        echo "FAILED: nbdev-clean"
        FAILED=1
    fi
    echo "--- uv run nbdev-export ---"
    if ! uv run nbdev-export; then
        echo "FAILED: nbdev-export"
        FAILED=1
    fi
    # Warn if notebooks still differ after clean (outputs were not stripped before save)
    DIRTY_NBS=$(git diff --name-only -- "*.ipynb" 2>/dev/null || true)
    if [ -n "$DIRTY_NBS" ]; then
        echo "WARNING: notebooks have uncommitted changes after nbdev-clean — commit them before pushing or CI will fail"
    fi
fi

# Always run lint and notebook tests
run make lint
run make nbdev-test

if [ "$FAILED" -ne 0 ]; then
    exit 2
fi
