# Multi-Model CLI Orchestrator (MMCO) Design

**Date:** 2026-02-01
**Status:** Approved

## Overview

A plugin system that enables LLM CLIs to delegate tasks to specialist CLIs based on their strengths. Each CLI remains independent but gains the ability to orchestrate others as sub-agents.

### The Problem

Different LLM CLIs excel at different tasks:
- **Claude Code** - Best for coding, debugging, architecture, testing
- **Kimi CLI** - Best for frontend design, UI/UX, visual components
- **Gemini CLI** - Best for research, search, content, documentation
- **Codex CLI** - Best for large context analysis, codebase-wide refactoring

No single CLI does everything well. Users currently switch between tools manually.

### The Solution

A plugin for each CLI that enables:
- Automatic delegation to specialists based on task analysis
- Streaming output with clear attribution
- Parallel execution of independent tasks
- Graceful fallbacks when a specialist is unavailable

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Your Terminal                            │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                   Claude Code                            ││
│  │  ┌─────────────────────────────────────────────────────┐││
│  │  │            Orchestrator Plugin                      │││
│  │  │  ┌──────────┐ ┌──────────┐ ┌─────────────────────┐ │││
│  │  │  │ Router   │ │ Registry │ │ Process Manager     │ │││
│  │  │  │ (which   │ │ (what's  │ │ (spawn, stream,     │ │││
│  │  │  │  CLI?)   │ │ installed)│ │  coordinate)        │ │││
│  │  │  └──────────┘ └──────────┘ └─────────────────────┘ │││
│  │  └─────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────┘│
│                            │                                 │
│         ┌──────────────────┼──────────────────┐             │
│         ▼                  ▼                  ▼             │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐       │
│  │ Gemini CLI  │   │  Kimi CLI   │   │ Codex CLI   │       │
│  │ (research)  │   │  (design)   │   │ (analysis)  │       │
│  └─────────────┘   └─────────────┘   └─────────────┘       │
│         │                  │                  │             │
│         └──────────────────┴──────────────────┘             │
│                            │                                 │
│                   Shared Project Directory                   │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Responsibility |
|-----------|----------------|
| **Router** | Analyzes tasks, calculates confidence scores, picks the right CLI |
| **Registry** | Tracks installed CLIs, their paths, capabilities, and health status |
| **Process Manager** | Spawns subprocesses, streams output, handles parallel execution |

## Routing & Confidence System

### Three-Tier Delegation

| Confidence | Action | Example |
|------------|--------|---------|
| **High (>80%)** | Auto-delegate | "Design a landing page with animations" → Kimi |
| **Medium (50-80%)** | Suggest | "Create a nice UI" → "Delegate to Kimi?" |
| **Low (<50%)** | Stay local | "Fix this bug" → Claude handles it |

### Default Specialty Mapping

```yaml
specialists:
  kimi:
    strengths: [frontend, design, ui, ux, css, animations, landing-page, visual]
    confidence_boost: 30

  gemini:
    strengths: [research, search, summarize, web, content, writing, documentation]
    confidence_boost: 25

  codex:
    strengths: [large-context, analysis, refactor-large, codebase-wide, legacy]
    confidence_boost: 25

  claude:
    strengths: [coding, debugging, architecture, testing, backend, api]
    confidence_boost: 0  # home base
```

### Confidence Calculation

```
base_score = keyword_matches × weight
user_override = config.priority[cli] or 0
final_confidence = base_score + specialty_boost + user_override
```

### Explicit Commands Always Available

```bash
@kimi design a dashboard
@gemini search for best practices on X
@codex analyze this entire codebase
```

## Process Management

### Subprocess Execution

CLIs are spawned as child processes, sharing the same project workspace. Output is streamed in real-time with clear attribution.

```
───────────────────────────────────────────────────────
 kimi  Creating Dashboard.tsx...
───────────────────────────────────────────────────────
import { LineChart } from 'recharts';

export function Dashboard({ data }) {
  return (
    <div className="dashboard-grid">
      ...
───────────────────────────────────────────────────────
 kimi  ✓ Complete · 3 files · 2.3s
───────────────────────────────────────────────────────
```

### Parallel Execution

When tasks are independent, they run simultaneously:

```
Task: "Design the UI and research accessibility best practices"
       │
       ├── Router detects two independent subtasks
       │
       ├──────────────┬──────────────┐
       ▼              ▼              │
   ┌───────┐    ┌─────────┐         │
   │ Kimi  │    │ Gemini  │         │
   │ (UI)  │    │(research)│         │
   └───┬───┘    └────┬────┘         │
       │             │              │
   [kimi] Creating...               │
   [gemini] Searching...            │
   [kimi] ✓ Header done             │
   [gemini] Found 5 articles...     │
       └─────────────┴──────────────┘
                     │
        Both tasks completed.
```

### Conflict Prevention

- File locks tracked per-CLI during parallel execution
- If two CLIs want same file → serialize those operations
- Workspace state snapshot before delegation

## Registry & Error Handling

### Pre-flight Check

On plugin load, check what's available:

```
Orchestrator Plugin Initialized

CLI Registry:
✓ claude    → /usr/local/bin/claude (active)
✓ kimi      → /home/syedadeel2/.local/share/uv/tools/kimi-cli/bin/kimi
✓ gemini    → /usr/bin/gemini
✗ codex     → not found

Routing adjusted: codex tasks → claude fallback
```

### Runtime Error Handling

When a specialist fails, offer alternatives:

```
[kimi:error] Connection lost

⚠ Kimi failed. Options:
1. Retry with Kimi
2. Continue with Claude (I'll finish the design)
3. Try Gemini instead
4. Abort and keep partial work

Files created before failure are preserved.
```

## Plugin Structure

```
~/.claude/plugins/multi-model-orchestrator/
├── plugin.json                 # Plugin manifest
├── config/
│   ├── registry.yaml           # CLI paths & settings
│   ├── routing.yaml            # Specialty mappings & overrides
│   └── defaults.yaml           # Default confidence thresholds
├── agents/
│   ├── router.md               # Routing decision agent
│   └── delegator.md            # Execution & streaming agent
├── skills/
│   ├── delegate.md             # @cli explicit delegation
│   └── configure.md            # /mmco-config command
├── hooks/
│   └── analyze-for-delegation.sh
└── lib/
    ├── process-manager.ts      # Subprocess spawning & streaming
    ├── registry.ts             # CLI detection & health checks
    ├── router.ts               # Confidence scoring & routing
    └── output-formatter.ts     # Stream parsing & attribution
```

## User Commands

### Explicit Delegation

```bash
@kimi design a landing page with hero section
@gemini search for React 19 best practices
@codex analyze the entire src/ directory

# Shorthand
@k design a modal component
@g what are the latest TypeScript features
```

### Control Commands

```bash
/mmco status              # Show registry status
/mmco config              # Open config for editing
/mmco history             # Recent delegations
/mmco prefer kimi react   # Add routing override
/mmco disable gemini      # Temporarily disable CLI
/mmco enable gemini       # Re-enable CLI
```

## Configuration

### Global Config: `~/.config/mmco/config.yaml`

```yaml
general:
  auto_delegate: true
  parallel_execution: true
  confidence_threshold:
    auto: 80
    suggest: 50
  timeout: 300
  stream_output: true

registry:
  claude:
    command: claude
    is_host: true

  kimi:
    command: kimi
    path: /home/syedadeel2/.local/share/uv/tools/kimi-cli/bin/kimi
    strengths: [frontend, design, ui, ux, css, animations, react, vue]
    timeout: 600

  gemini:
    command: gemini
    strengths: [research, search, summarize, web, content, docs]

  codex:
    command: codex
    strengths: [large-context, analysis, codebase-wide, refactor]

routing:
  patterns:
    - match: ["landing page", "hero section", "dashboard ui"]
      cli: kimi
      weight: 40
    - match: ["search for", "find out", "what is"]
      cli: gemini
      weight: 30
    - match: ["analyze entire", "whole codebase"]
      cli: codex
      weight: 35

  overrides:
    "tailwind component": kimi
    "api endpoint": claude

appearance:
  colors:
    kimi: magenta
    gemini: blue
    codex: green
    claude: yellow
  show_confidence: true
  show_timing: true
```

### Project Override: `.mmco.yaml`

```yaml
routing:
  overrides:
    "component": kimi
preferences:
  default_cli: claude
```

## Implementation Phases

### Phase 1: Core Foundation
- Plugin scaffold with plugin.json
- Registry system - detect installed CLIs, health checks
- Basic subprocess spawning and output capture
- Simple streaming with CLI attribution

### Phase 2: Routing Intelligence
- Keyword pattern matching
- Confidence scoring algorithm
- Config file parsing
- Explicit @cli command handling

### Phase 3: Delegation Flow
- UserPromptSubmit hook for auto-analysis
- Suggestion prompts for medium confidence
- User approval/rejection flow
- Fallback handling

### Phase 4: Parallel Execution
- Task independence detection
- Multi-process coordination
- File lock tracking
- Merged output streaming

### Phase 5: Polish & UX
- Color-coded output
- /mmco control commands
- Error recovery with alternatives
- History tracking

## Decision Summary

| Decision | Choice |
|----------|--------|
| Architecture | Plugin per CLI |
| Trigger | Hybrid (auto/suggest/explicit) |
| Output | Streaming with attribution |
| Target CLIs | Claude, Kimi, Gemini, Codex |
| Routing | Defaults + config + keywords |
| Execution | Direct subprocess, shared workspace |
| Parallelism | Auto when independent |
| Errors | Pre-flight check + suggest alternatives |

## Known CLI Paths

| CLI | Path |
|-----|------|
| Kimi | `/home/syedadeel2/.local/share/uv/tools/kimi-cli/bin/kimi` |
| Claude | TBD (detect from PATH) |
| Gemini | TBD (detect from PATH) |
| Codex | TBD (detect from PATH) |
