---
name: mmco-status
description: Show the status of the multi-model orchestrator - available CLIs and routing config
invocation: user
---

# Multi-Model Orchestrator Status

## Your Task

Display the status of the Multi-Model CLI Orchestrator.

## Step 1: Check CLI Registry

Run this command to get CLI availability:

```bash
${CLAUDE_PLUGIN_ROOT}/lib/registry.sh check_all
```

## Step 2: Display the Status

Format the output nicely for the user, including:

1. **CLI Registry Status**
   - Show which CLIs are available and their paths
   - Use ✓ for available, ✗ for not found

2. **Routing Thresholds**
   - Auto-delegate: ≥80% confidence
   - Suggest: ≥50% confidence

3. **Delegation Commands**
   - `@kimi <task>` - Frontend, design, UI components
   - `@gemini <task>` - Research, search, documentation
   - `@codex <task>` - Large context, codebase analysis

## Example Output

```
# Multi-Model Orchestrator Status

## CLI Registry

| CLI | Status | Path |
|-----|--------|------|
| kimi | ✓ Available | /home/user/.local/bin/kimi |
| gemini | ✓ Available | /usr/bin/gemini |
| codex | ✗ Not found | - |

## Routing Configuration

### Confidence Thresholds
- **Auto-delegate**: ≥80% confidence → Task automatically routed to specialist
- **Suggest**: ≥50% confidence → User prompted to confirm delegation

### Delegation Commands

| Command | Specialist | Best For |
|---------|------------|----------|
| `@kimi <task>` | Kimi | Frontend, design, UI components |
| `@gemini <task>` | Gemini | Research, search, documentation |
| `@codex <task>` | Codex | Large context, codebase analysis |
```
