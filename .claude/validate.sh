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

# For notebook changes, export first
if echo "$CHANGED_FILE" | grep -qE "\.ipynb$"; then
    echo "--- nbdev_export ---"
    if ! uv run nbdev-export; then
        echo "FAILED: nbdev_export"
        FAILED=1
    fi
fi

# Always run lint and notebook tests
run make lint
run make nbdev-test

if [ "$FAILED" -ne 0 ]; then
    exit 2
fi
