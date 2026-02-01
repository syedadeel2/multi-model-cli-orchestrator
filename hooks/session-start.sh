#!/usr/bin/env bash
# Session start hook - check CLI availability

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Get CLI status
status=$("${PLUGIN_ROOT}/lib/registry.sh" check_all 2>/dev/null || echo "Registry check failed")

# Output success message with CLI info
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "message": "Success",
    "additionalContext": "${status}"
  }
}
EOF
