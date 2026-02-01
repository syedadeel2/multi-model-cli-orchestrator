#!/usr/bin/env bash
# Analyze user prompt for potential delegation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read the user prompt from stdin (Claude passes it as JSON)
input=$(cat)
prompt=$(echo "$input" | grep -oP '"content":\s*"\K[^"]+' 2>/dev/null | head -1 || echo "")

# Skip if prompt is empty
if [[ -z "$prompt" ]]; then
    echo '{}'
    exit 0
fi

# Skip if prompt starts with @ (already explicit delegation)
if [[ "$prompt" == @* ]]; then
    echo '{}'
    exit 0
fi

# Skip if prompt is a command (starts with /)
if [[ "$prompt" == /* ]]; then
    echo '{}'
    exit 0
fi

# Get routing decision
decision=$("${PLUGIN_ROOT}/lib/router.sh" route "$prompt" 2>/dev/null || echo "local:claude:0")

action="${decision%%:*}"
rest="${decision#*:}"
cli="${rest%%:*}"
score="${rest##*:}"

# Build response based on action
case "$action" in
    auto)
        # High confidence - add context about auto-delegation
        cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "<delegation-hint cli=\"${cli}\" confidence=\"${score}\">High confidence match (${score}%) for ${cli}. This task aligns well with ${cli}'s specialty. Consider delegating with: @${cli} ${prompt}</delegation-hint>"
  }
}
EOF
        ;;
    suggest)
        # Medium confidence - suggest delegation
        cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "<delegation-suggestion cli=\"${cli}\" confidence=\"${score}\">This task may benefit from ${cli} (${score}% confidence). ${cli} has relevant strengths for this type of work. You can suggest: @${cli} ${prompt}</delegation-suggestion>"
  }
}
EOF
        ;;
    *)
        # Low confidence - no suggestion
        echo '{}'
        ;;
esac
