#!/usr/bin/env bash
# Process Manager - spawn and stream CLI subprocesses

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source registry functions
source "${SCRIPT_DIR}/registry.sh" 2>/dev/null || true

# ANSI color codes
declare -A COLORS=(
    [kimi]="\033[35m"     # magenta
    [gemini]="\033[34m"   # blue
    [codex]="\033[32m"    # green
    [claude]="\033[33m"   # yellow
    [reset]="\033[0m"
    [bold]="\033[1m"
    [dim]="\033[2m"
)

# Stream output from a CLI with attribution
stream_with_attribution() {
    local cli="$1"
    local color="${COLORS[$cli]:-${COLORS[reset]}}"
    local reset="${COLORS[reset]}"

    while IFS= read -r line; do
        echo -e "${color}[${cli}]${reset} ${line}"
    done
}

# Print a header/separator line
print_header() {
    local cli="$1"
    local message="$2"
    local color="${COLORS[$cli]:-${COLORS[reset]}}"
    local reset="${COLORS[reset]}"

    echo -e "${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
    echo -e "${color}${COLORS[bold]} ${cli} ${reset} ${message}"
    echo -e "${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
}

# Execute a CLI with prompt
execute_cli() {
    local cli="$1"
    local prompt="$2"
    local workdir="${3:-$(pwd)}"

    local color="${COLORS[$cli]:-${COLORS[reset]}}"
    local reset="${COLORS[reset]}"

    # Get CLI path from registry
    local cli_path=$("${SCRIPT_DIR}/registry.sh" get_path "$cli" 2>/dev/null || echo "")

    if [[ -z "$cli_path" ]]; then
        echo -e "${color}[${cli}:error]${reset} CLI not found. Is it installed?"
        return 1
    fi

    print_header "$cli" "Starting..."

    local start_time=$(date +%s)
    local exit_code=0

    # Execute based on CLI type
    case "$cli" in
        kimi)
            # Kimi uses -p for prompt, --yolo for auto-approve, -w for workdir
            "$cli_path" --yolo -w "$workdir" -p "$prompt" 2>&1 | stream_with_attribution "$cli" || exit_code=$?
            ;;
        gemini)
            # Gemini CLI - uses prompt as argument
            "$cli_path" "$prompt" 2>&1 | stream_with_attribution "$cli" || exit_code=$?
            ;;
        codex)
            # Codex CLI - uses --full-auto flag
            "$cli_path" --full-auto "$prompt" 2>&1 | stream_with_attribution "$cli" || exit_code=$?
            ;;
        *)
            echo "Unknown CLI: $cli"
            return 1
            ;;
    esac

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo -e "${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${color}${COLORS[bold]} ${cli} ${reset} ✓ Complete · ${duration}s"
    else
        echo -e "${color}${COLORS[bold]} ${cli}:error ${reset} Exit code: $exit_code"
    fi
    echo -e "${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"

    return $exit_code
}

# Main
case "${1:-}" in
    run)
        execute_cli "$2" "$3" "${4:-$(pwd)}"
        ;;
    *)
        echo "Usage: process-manager.sh run <cli> <prompt> [workdir]"
        ;;
esac
