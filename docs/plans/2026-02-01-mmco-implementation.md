# Multi-Model CLI Orchestrator Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Claude Code plugin that delegates tasks to specialist LLM CLIs (Kimi, Gemini, Codex) based on task analysis.

**Architecture:** Plugin hooks into `UserPromptSubmit` to analyze prompts, calculates confidence scores for each specialist CLI, and spawns subprocesses with streaming output. Uses YAML config for routing rules.

**Tech Stack:** Bash/Shell scripts, YAML configuration, Claude Code plugin system (hooks, skills, commands)

---

## Task 1: Plugin Scaffold

**Files:**
- Create: `~/.claude/plugins/multi-model-orchestrator/.claude-plugin/plugin.json`
- Create: `~/.claude/plugins/multi-model-orchestrator/README.md`

**Step 1: Create plugin directory structure**

```bash
mkdir -p ~/.claude/plugins/multi-model-orchestrator/.claude-plugin
mkdir -p ~/.claude/plugins/multi-model-orchestrator/config
mkdir -p ~/.claude/plugins/multi-model-orchestrator/hooks
mkdir -p ~/.claude/plugins/multi-model-orchestrator/skills
mkdir -p ~/.claude/plugins/multi-model-orchestrator/commands
mkdir -p ~/.claude/plugins/multi-model-orchestrator/lib
```

**Step 2: Create plugin.json manifest**

```json
{
  "name": "multi-model-orchestrator",
  "description": "Delegate tasks to specialist LLM CLIs based on their strengths",
  "version": "0.1.0",
  "author": {
    "name": "syedadeel2",
    "email": "syedadeel2@gmail.com"
  },
  "keywords": ["multi-model", "orchestrator", "kimi", "gemini", "codex", "delegation"]
}
```

**Step 3: Create README.md**

Create a brief README explaining the plugin purpose.

**Step 4: Verify plugin is recognized**

Run: `claude plugin list`
Expected: Plugin appears in list (may need restart)

**Step 5: Commit**

```bash
cd ~/.claude/plugins/multi-model-orchestrator
git init
git add .
git commit -m "feat: scaffold multi-model-orchestrator plugin"
```

---

## Task 2: Registry Configuration

**Files:**
- Create: `~/.claude/plugins/multi-model-orchestrator/config/registry.yaml`
- Create: `~/.claude/plugins/multi-model-orchestrator/lib/registry.sh`

**Step 1: Create registry.yaml with CLI definitions**

```yaml
# CLI Registry - defines available specialist CLIs
clis:
  kimi:
    command: kimi
    path: /home/syedadeel2/.local/share/uv/tools/kimi-cli/bin/kimi
    args: ["--yolo", "-p"]
    strengths:
      - frontend
      - design
      - ui
      - ux
      - css
      - animations
      - react
      - vue
      - tailwind
      - landing-page
      - component
      - visual
    timeout: 600
    color: magenta

  gemini:
    command: gemini
    path: ""  # detect from PATH
    args: []
    strengths:
      - research
      - search
      - summarize
      - web
      - content
      - writing
      - documentation
      - explain
      - "what is"
      - "find out"
    timeout: 300
    color: blue

  codex:
    command: codex
    path: ""  # detect from PATH
    args: []
    strengths:
      - large-context
      - analysis
      - codebase-wide
      - refactor
      - legacy
      - "entire codebase"
      - "all files"
    timeout: 600
    color: green

  claude:
    command: claude
    is_host: true
    strengths:
      - coding
      - debugging
      - architecture
      - testing
      - backend
      - api
      - fix
      - implement
    color: yellow
```

**Step 2: Create registry.sh for CLI detection**

```bash
#!/usr/bin/env bash
# Registry management - detect and validate CLIs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REGISTRY_FILE="${PLUGIN_ROOT}/config/registry.yaml"

# Parse YAML (simple grep-based for basic values)
get_cli_path() {
    local cli="$1"
    local path=$(grep -A1 "^  ${cli}:" "$REGISTRY_FILE" | grep "path:" | sed 's/.*path: *//' | tr -d '"')
    echo "$path"
}

# Check if a CLI is available
check_cli() {
    local cli="$1"
    local path=$(get_cli_path "$cli")

    if [[ -n "$path" && "$path" != '""' ]]; then
        # Explicit path given
        if [[ -x "$path" ]]; then
            echo "found:$path"
            return 0
        fi
    else
        # Try to find in PATH
        local found=$(which "$cli" 2>/dev/null || true)
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
        result=$(check_cli "$cli" || true)
        if [[ "$result" == not_found ]]; then
            echo "✗ $cli → not found"
        else
            path="${result#found:}"
            echo "✓ $cli → $path"
        fi
    done
}

# Main
case "${1:-check_all}" in
    check) check_cli "$2" ;;
    check_all) check_all ;;
    *) echo "Usage: registry.sh [check <cli>|check_all]" ;;
esac
```

**Step 3: Make registry.sh executable**

Run: `chmod +x ~/.claude/plugins/multi-model-orchestrator/lib/registry.sh`

**Step 4: Test registry detection**

Run: `~/.claude/plugins/multi-model-orchestrator/lib/registry.sh check_all`
Expected: Shows kimi as found, others as not found (based on current system)

**Step 5: Commit**

```bash
cd ~/.claude/plugins/multi-model-orchestrator
git add .
git commit -m "feat: add CLI registry with detection"
```

---

## Task 3: Routing Configuration

**Files:**
- Create: `~/.claude/plugins/multi-model-orchestrator/config/routing.yaml`
- Create: `~/.claude/plugins/multi-model-orchestrator/lib/router.sh`

**Step 1: Create routing.yaml with patterns and thresholds**

```yaml
# Routing configuration

thresholds:
  auto: 80        # Auto-delegate above this confidence
  suggest: 50     # Suggest delegation above this

# Pattern weights for keyword matching
patterns:
  kimi:
    - pattern: "design"
      weight: 25
    - pattern: "landing page"
      weight: 40
    - pattern: "hero section"
      weight: 35
    - pattern: "dashboard ui"
      weight: 35
    - pattern: "component"
      weight: 20
    - pattern: "css"
      weight: 30
    - pattern: "tailwind"
      weight: 30
    - pattern: "animation"
      weight: 30
    - pattern: "frontend"
      weight: 25
    - pattern: "ui"
      weight: 20
    - pattern: "ux"
      weight: 20
    - pattern: "react component"
      weight: 35
    - pattern: "vue component"
      weight: 35
    - pattern: "visual"
      weight: 20
    - pattern: "beautiful"
      weight: 15
    - pattern: "modern"
      weight: 10
    - pattern: "responsive"
      weight: 15

  gemini:
    - pattern: "search for"
      weight: 35
    - pattern: "find out"
      weight: 30
    - pattern: "what is"
      weight: 25
    - pattern: "research"
      weight: 35
    - pattern: "summarize"
      weight: 30
    - pattern: "explain"
      weight: 20
    - pattern: "documentation"
      weight: 25
    - pattern: "latest"
      weight: 20
    - pattern: "best practices"
      weight: 25
    - pattern: "web"
      weight: 15

  codex:
    - pattern: "analyze entire"
      weight: 40
    - pattern: "whole codebase"
      weight: 40
    - pattern: "all files"
      weight: 35
    - pattern: "large context"
      weight: 35
    - pattern: "codebase-wide"
      weight: 40
    - pattern: "refactor everything"
      weight: 35
    - pattern: "legacy code"
      weight: 30

# CLI-specific boosts (added to pattern score)
boosts:
  kimi: 10
  gemini: 5
  codex: 5

# User overrides (highest priority - exact phrase to CLI)
overrides: {}
  # "react component": kimi
  # "api endpoint": claude
```

**Step 2: Create router.sh for confidence calculation**

```bash
#!/usr/bin/env bash
# Router - calculate confidence scores for CLIs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROUTING_FILE="${PLUGIN_ROOT}/config/routing.yaml"

# Calculate confidence score for a CLI based on prompt
# Returns: cli:score pairs, sorted by score descending
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

        # Read patterns from config (simplified parsing)
        while IFS= read -r line; do
            pattern=$(echo "$line" | grep -oP 'pattern: "\K[^"]+' || true)
            weight=$(echo "$line" | grep -oP 'weight: \K\d+' || true)

            if [[ -n "$pattern" && -n "$weight" ]]; then
                if echo "$prompt_lower" | grep -qi "$pattern"; then
                    score=$((score + weight))
                fi
            fi
        done < <(sed -n "/^  ${cli}:/,/^  [a-z]/p" "$ROUTING_FILE" | head -n -1)

        # Add CLI boost
        local boost=$(grep -A1 "^boosts:" "$ROUTING_FILE" | grep "${cli}:" | grep -oP '\d+' || echo 0)
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
    local auto_threshold=$(grep "auto:" "$ROUTING_FILE" | grep -oP '\d+' || echo 80)
    local suggest_threshold=$(grep "suggest:" "$ROUTING_FILE" | grep -oP '\d+' || echo 50)

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
```

**Step 3: Make router.sh executable**

Run: `chmod +x ~/.claude/plugins/multi-model-orchestrator/lib/router.sh`

**Step 4: Test router with sample prompts**

Run: `~/.claude/plugins/multi-model-orchestrator/lib/router.sh route "design a landing page with hero section"`
Expected: `auto:kimi:XX` (score >= 80)

Run: `~/.claude/plugins/multi-model-orchestrator/lib/router.sh route "fix this bug in the API"`
Expected: `local:claude:XX` (low score)

**Step 5: Commit**

```bash
cd ~/.claude/plugins/multi-model-orchestrator
git add .
git commit -m "feat: add routing engine with pattern matching"
```

---

## Task 4: Process Manager

**Files:**
- Create: `~/.claude/plugins/multi-model-orchestrator/lib/process-manager.sh`

**Step 1: Create process-manager.sh for subprocess execution**

```bash
#!/usr/bin/env bash
# Process Manager - spawn and stream CLI subprocesses

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${SCRIPT_DIR}/registry.sh" 2>/dev/null || true

# ANSI color codes
declare -A COLORS=(
    [kimi]="\033[35m"     # magenta
    [gemini]="\033[34m"   # blue
    [codex]="\033[32m"    # green
    [claude]="\033[33m"   # yellow
    [reset]="\033[0m"
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

# Execute a CLI with prompt
execute_cli() {
    local cli="$1"
    local prompt="$2"
    local workdir="${3:-$(pwd)}"

    # Get CLI path from registry
    local cli_info=$(check_cli "$cli" 2>/dev/null || echo "not_found")

    if [[ "$cli_info" == "not_found" ]]; then
        echo -e "${COLORS[cli]}[${cli}:error]${COLORS[reset]} CLI not found. Is it installed?"
        return 1
    fi

    local cli_path="${cli_info#found:}"

    echo -e "${COLORS[$cli]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLORS[reset]}"
    echo -e "${COLORS[$cli]} ${cli} ${COLORS[reset]} Starting..."
    echo -e "${COLORS[$cli]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLORS[reset]}"

    # Execute based on CLI type
    case "$cli" in
        kimi)
            # Kimi uses -p for prompt, --yolo for auto-approve, -w for workdir
            "$cli_path" --yolo -w "$workdir" -p "$prompt" 2>&1 | stream_with_attribution "$cli"
            ;;
        gemini)
            # Gemini CLI (adjust based on actual interface)
            "$cli_path" "$prompt" 2>&1 | stream_with_attribution "$cli"
            ;;
        codex)
            # Codex CLI (adjust based on actual interface)
            "$cli_path" "$prompt" 2>&1 | stream_with_attribution "$cli"
            ;;
        *)
            echo "Unknown CLI: $cli"
            return 1
            ;;
    esac

    local exit_code=$?

    echo -e "${COLORS[$cli]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLORS[reset]}"
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${COLORS[$cli]} ${cli} ${COLORS[reset]} ✓ Complete"
    else
        echo -e "${COLORS[$cli]} ${cli}:error ${COLORS[reset]} Exit code: $exit_code"
    fi
    echo -e "${COLORS[$cli]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLORS[reset]}"

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
```

**Step 2: Make process-manager.sh executable**

Run: `chmod +x ~/.claude/plugins/multi-model-orchestrator/lib/process-manager.sh`

**Step 3: Test with Kimi (the available CLI)**

Run: `~/.claude/plugins/multi-model-orchestrator/lib/process-manager.sh run kimi "say hello"`
Expected: Colored output with [kimi] prefix, shows Kimi response

**Step 4: Commit**

```bash
cd ~/.claude/plugins/multi-model-orchestrator
git add .
git commit -m "feat: add process manager with streaming output"
```

---

## Task 5: Explicit Delegation Skill

**Files:**
- Create: `~/.claude/plugins/multi-model-orchestrator/skills/delegate/SKILL.md`

**Step 1: Create the delegate skill**

```markdown
---
name: delegate
description: Explicitly delegate a task to a specialist CLI using @cli syntax
invocation: user
---

# Delegate to Specialist CLI

When the user uses @cli syntax (e.g., @kimi, @gemini, @codex), delegate the task to that CLI.

## Syntax

- `@kimi <task>` - Delegate to Kimi (frontend/design specialist)
- `@gemini <task>` - Delegate to Gemini (research/search specialist)
- `@codex <task>` - Delegate to Codex (large context specialist)
- `@k`, `@g`, `@c` - Shorthand aliases

## Execution

1. Parse the CLI name and task from the user's message
2. Check if the CLI is available using the registry
3. If available, spawn the CLI with the task using process-manager
4. Stream the output back with attribution
5. Report completion or errors

## Example

User: `@kimi design a modern dashboard with charts`

Response:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 kimi  Starting...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[kimi] Creating Dashboard.tsx...
[kimi] ✓ Generated component
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 kimi  ✓ Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Implementation

When you see @cli syntax in a user message:

1. Extract CLI name: `kimi`, `gemini`, `codex` (or aliases k, g, c)
2. Extract task: everything after the @cli mention
3. Run: `${CLAUDE_PLUGIN_ROOT}/lib/process-manager.sh run <cli> "<task>" "$(pwd)"`
4. Stream the output to the user
5. After completion, summarize what the specialist did
```

**Step 2: Verify skill directory structure**

Run: `ls -la ~/.claude/plugins/multi-model-orchestrator/skills/delegate/`
Expected: SKILL.md exists

**Step 3: Commit**

```bash
cd ~/.claude/plugins/multi-model-orchestrator
git add .
git commit -m "feat: add explicit delegation skill (@cli syntax)"
```

---

## Task 6: Status Command

**Files:**
- Create: `~/.claude/plugins/multi-model-orchestrator/commands/status.md`

**Step 1: Create the /mmco-status command**

```markdown
---
name: mmco-status
description: Show the status of the multi-model orchestrator - available CLIs and routing config
invocation: user
---

# MMCO Status

Show the current status of the Multi-Model CLI Orchestrator.

## What to Display

1. **CLI Registry Status**
   - Run: `${CLAUDE_PLUGIN_ROOT}/lib/registry.sh check_all`
   - Show which CLIs are available and their paths

2. **Routing Thresholds**
   - Auto-delegate threshold (default: 80)
   - Suggest threshold (default: 50)

3. **Quick Reference**
   - @kimi - frontend, design, UI components
   - @gemini - research, search, documentation
   - @codex - large context, codebase analysis

## Example Output

```
Multi-Model Orchestrator Status
===============================

CLI Registry:
✓ kimi    → /home/syedadeel2/.local/share/uv/tools/kimi-cli/bin/kimi
✗ gemini  → not found (install: pip install gemini-cli)
✗ codex   → not found (install: npm install -g @openai/codex-cli)

Routing Thresholds:
• Auto-delegate: ≥80% confidence
• Suggest: ≥50% confidence

Delegation Commands:
• @kimi <task>   - Frontend, design, UI (magenta)
• @gemini <task> - Research, search (blue)
• @codex <task>  - Large context analysis (green)
```
```

**Step 2: Commit**

```bash
cd ~/.claude/plugins/multi-model-orchestrator
git add .
git commit -m "feat: add /mmco-status command"
```

---

## Task 7: UserPromptSubmit Hook for Auto-Analysis

**Files:**
- Create: `~/.claude/plugins/multi-model-orchestrator/hooks/hooks.json`
- Create: `~/.claude/plugins/multi-model-orchestrator/hooks/analyze-prompt.sh`

**Step 1: Create hooks.json**

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/analyze-prompt.sh"
          }
        ]
      }
    ]
  }
}
```

**Step 2: Create analyze-prompt.sh**

```bash
#!/usr/bin/env bash
# Analyze user prompt for potential delegation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read the user prompt from stdin (Claude passes it as JSON)
input=$(cat)
prompt=$(echo "$input" | grep -oP '"content":\s*"\K[^"]+' | head -1 || echo "")

# Skip if prompt is empty or starts with @ (already explicit delegation)
if [[ -z "$prompt" ]] || [[ "$prompt" == @* ]]; then
    echo '{}'
    exit 0
fi

# Skip if prompt is a command
if [[ "$prompt" == /* ]]; then
    echo '{}'
    exit 0
fi

# Get routing decision
source "${PLUGIN_ROOT}/lib/router.sh" 2>/dev/null || true
decision=$(route "$prompt" 2>/dev/null || echo "local:claude:0")

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
    "additionalContext": "<delegation-hint>High confidence match (${score}%) for ${cli}. Consider auto-delegating this task to ${cli} which specializes in this type of work. Use: @${cli} ${prompt}</delegation-hint>"
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
    "additionalContext": "<delegation-suggestion>This task may benefit from delegation to ${cli} (${score}% confidence). ${cli} specializes in this type of work. You can suggest: @${cli} ${prompt}</delegation-suggestion>"
  }
}
EOF
        ;;
    *)
        # Low confidence - no suggestion
        echo '{}'
        ;;
esac
```

**Step 3: Make analyze-prompt.sh executable**

Run: `chmod +x ~/.claude/plugins/multi-model-orchestrator/hooks/analyze-prompt.sh`

**Step 4: Test the hook manually**

Run: `echo '{"content": "design a landing page"}' | ~/.claude/plugins/multi-model-orchestrator/hooks/analyze-prompt.sh`
Expected: JSON with delegation-hint for kimi

**Step 5: Commit**

```bash
cd ~/.claude/plugins/multi-model-orchestrator
git add .
git commit -m "feat: add UserPromptSubmit hook for auto-analysis"
```

---

## Task 8: Integration Testing

**Files:**
- No new files, testing existing components

**Step 1: Verify full plugin structure**

Run: `find ~/.claude/plugins/multi-model-orchestrator -type f | head -20`
Expected: All created files listed

**Step 2: Test registry**

Run: `~/.claude/plugins/multi-model-orchestrator/lib/registry.sh check_all`
Expected: Shows kimi as found

**Step 3: Test router with various prompts**

```bash
# Should route to kimi (high confidence)
~/.claude/plugins/multi-model-orchestrator/lib/router.sh route "design a beautiful landing page"

# Should route to gemini (if patterns match)
~/.claude/plugins/multi-model-orchestrator/lib/router.sh route "search for React best practices"

# Should stay local (low confidence)
~/.claude/plugins/multi-model-orchestrator/lib/router.sh route "fix this bug"
```

**Step 4: Test process manager with kimi**

Run: `~/.claude/plugins/multi-model-orchestrator/lib/process-manager.sh run kimi "just say hello world"`
Expected: Colored output from kimi

**Step 5: Reload Claude and test plugin**

Restart Claude Code session and verify:
- `/mmco-status` command works
- @kimi delegation works
- Auto-suggestions appear for design prompts

**Step 6: Final commit**

```bash
cd ~/.claude/plugins/multi-model-orchestrator
git add .
git commit -m "chore: complete phase 1 - core foundation"
```

---

## Summary

After completing all tasks, you will have:

1. **Plugin scaffold** with proper structure
2. **Registry** that detects installed CLIs
3. **Router** that scores prompts and determines delegation
4. **Process Manager** that spawns CLIs with streaming output
5. **Delegate skill** for explicit @cli syntax
6. **Status command** to show plugin state
7. **Hook** that auto-analyzes prompts for delegation

The plugin will work with Kimi immediately (since it's installed). Gemini and Codex support will activate when those CLIs are installed.
