#!/usr/bin/env bash
# Router - calculate confidence scores for CLIs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROUTING_FILE="${PLUGIN_ROOT}/config/routing.yaml"

# Calculate confidence score for a CLI based on prompt
calculate_scores() {
    local prompt="$1"
    local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

    declare -A scores
    scores[kimi]=0
    scores[gemini]=0
    scores[codex]=0

    # Check patterns for each CLI
    for cli in kimi gemini codex; do
        local score=0
        local in_cli_section=0

        while IFS= read -r line; do
            # Check if we're entering this CLI's pattern section
            if echo "$line" | grep -qE "^  ${cli}:"; then
                in_cli_section=1
                continue
            fi

            # Check if we're leaving the section
            if [[ $in_cli_section -eq 1 ]] && echo "$line" | grep -qE "^  [a-z]+:"; then
                break
            fi

            # Parse pattern and weight
            if [[ $in_cli_section -eq 1 ]]; then
                if echo "$line" | grep -q "pattern:"; then
                    current_pattern=$(echo "$line" | sed 's/.*pattern:[[:space:]]*"\{0,1\}//' | sed 's/"\{0,1\}[[:space:]]*$//')
                fi
                if echo "$line" | grep -q "weight:"; then
                    current_weight=$(echo "$line" | grep -oE '[0-9]+')
                    if [[ -n "$current_pattern" && -n "$current_weight" ]]; then
                        if echo "$prompt_lower" | grep -qi "$current_pattern"; then
                            score=$((score + current_weight))
                        fi
                    fi
                fi
            fi
        done < "$ROUTING_FILE"

        # Add CLI boost
        local boost=$(grep -A5 "^boosts:" "$ROUTING_FILE" | grep "${cli}:" | grep -oE '[0-9]+' || echo 0)
        score=$((score + boost))

        scores[$cli]=$score
    done

    # Output sorted by score
    for cli in "${!scores[@]}"; do
        echo "${scores[$cli]}:$cli"
    done | sort -t: -k1 -nr
}

# Determine routing decision based on scores
route() {
    local prompt="$1"
    local auto_threshold=$(grep "auto:" "$ROUTING_FILE" | head -1 | grep -oE '[0-9]+' || echo 80)
    local suggest_threshold=$(grep "suggest:" "$ROUTING_FILE" | head -1 | grep -oE '[0-9]+' || echo 50)

    local results=$(calculate_scores "$prompt")
    local top=$(echo "$results" | head -1)
    local top_score=${top%%:*}
    local top_cli=${top##*:}

    if [[ $top_score -ge $auto_threshold ]]; then
        echo "auto:$top_cli:$top_score"
    elif [[ $top_score -ge $suggest_threshold ]]; then
        echo "suggest:$top_cli:$top_score"
    else
        echo "local:claude:$top_score"
    fi
}

# Main
case "${1:-}" in
    scores) calculate_scores "$2" ;;
    route) route "$2" ;;
    *)
        echo "Usage: router.sh [scores|route] <prompt>"
        echo "  scores: Show all CLI scores for prompt"
        echo "  route: Get routing decision (auto/suggest/local)"
        ;;
esac
