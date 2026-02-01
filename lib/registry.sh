#!/usr/bin/env bash
# Registry management - detect and validate CLIs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REGISTRY_FILE="${PLUGIN_ROOT}/config/registry.yaml"

# Get CLI paths from registry (supports multiple paths)
get_cli_paths() {
    local cli="$1"
    # Extract paths array for the CLI
    sed -n "/^  ${cli}:/,/^  [a-z]/p" "$REGISTRY_FILE" | \
        grep -E "^\s+- /" | \
        sed 's/^[[:space:]]*- //' | \
        tr -d '"'
}

# Get CLI command from registry
get_cli_command() {
    local cli="$1"
    sed -n "/^  ${cli}:/,/^  [a-z]/p" "$REGISTRY_FILE" | \
        grep "command:" | \
        sed 's/.*command:[[:space:]]*//' | \
        tr -d '"' | \
        head -1
}

# Check if a CLI is available
check_cli() {
    local cli="$1"

    # First try explicit paths from config
    while IFS= read -r path; do
        if [[ -n "$path" && -x "$path" ]]; then
            echo "found:$path"
            return 0
        fi
    done < <(get_cli_paths "$cli")

    # Then try to find command in PATH
    local cmd=$(get_cli_command "$cli")
    if [[ -n "$cmd" ]]; then
        local found=$(which "$cmd" 2>/dev/null || true)
        if [[ -n "$found" ]]; then
            echo "found:$found"
            return 0
        fi
    fi

    echo "not_found"
    return 1
}

# Check all CLIs and output status
check_all() {
    echo "CLI Registry Status:"
    echo "===================="
    for cli in kimi gemini codex; do
        result=$(check_cli "$cli" 2>/dev/null || echo "not_found")
        if [[ "$result" == "not_found" ]]; then
            printf "✗ %-8s → not found\n" "$cli"
        else
            path="${result#found:}"
            printf "✓ %-8s → %s\n" "$cli" "$path"
        fi
    done
}

# Main
case "${1:-check_all}" in
    check) check_cli "$2" ;;
    check_all) check_all ;;
    get_path)
        result=$(check_cli "$2" 2>/dev/null || echo "not_found")
        if [[ "$result" != "not_found" ]]; then
            echo "${result#found:}"
        fi
        ;;
    *) echo "Usage: registry.sh [check <cli>|check_all|get_path <cli>]" ;;
esac
