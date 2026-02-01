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

## Execution Steps

When you see @cli syntax in a user message:

1. **Parse the request**: Extract CLI name and task
   - `@kimi design a modal` → cli=kimi, task="design a modal"
   - `@k build a navbar` → cli=kimi, task="build a navbar"

2. **Check CLI availability**: Run the registry check
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/lib/registry.sh check <cli>
   ```

3. **If available**: Execute the delegation
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/lib/process-manager.sh run <cli> "<task>" "$(pwd)"
   ```

4. **Stream output**: Show the CLI's response with attribution

5. **Summarize**: After completion, briefly summarize what the specialist did

## CLI Specialties

| CLI | Strengths | Color |
|-----|-----------|-------|
| **kimi** | Frontend, design, UI/UX, CSS, animations, React, Vue, Tailwind | Magenta |
| **gemini** | Research, search, documentation, explanations, comparisons | Blue |
| **codex** | Large context analysis, codebase-wide refactoring, legacy code | Green |

## Example Interaction

**User:** `@kimi design a modern dashboard with charts`

**Response:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 kimi  Starting...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[kimi] Creating Dashboard.tsx...
[kimi] Adding chart components...
[kimi] Styling with Tailwind...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 kimi  ✓ Complete · 12s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Summary:** Kimi created a Dashboard component with LineChart and BarChart using Recharts, styled with Tailwind CSS dark theme.

## Error Handling

If the CLI is not found:
```
[kimi:error] CLI not found. Is it installed?

To install Kimi CLI:
  uv tool install kimi-cli

Or use a different specialist:
  @gemini for research tasks
  @codex for large codebase analysis
```

## Notes

- Always use the process manager for execution to get proper streaming and attribution
- The working directory is passed to the CLI so it can access project files
- Timeout is CLI-specific (configured in registry.yaml)
