# Multi-Model CLI Orchestrator (MMCO)

> **Use the right AI for the job.** A Claude Code plugin that intelligently delegates tasks to specialist LLM CLIs based on their strengths.

[![Status](https://img.shields.io/badge/status-beta-brightgreen)](docs/plans/)
[![Claude Code](https://img.shields.io/badge/claude--code-plugin-blue)](https://docs.anthropic.com/en/docs/claude-code)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

Different AI tools excel at different tasks. **Kimi** nails frontend design. **Gemini** crushes research. **Codex** handles massive codebases. But switching between them is a pain.

MMCO fixes this. It analyzes your task and automatically routes it to the best tool—or lets you explicitly delegate with a simple `@cli` command.

```
You: @kimi design a modern dashboard with dark mode

───────────────────────────────────────────
 kimi  Creating Dashboard.tsx...
───────────────────────────────────────────
[kimi] import { LineChart } from 'recharts';
[kimi] export function Dashboard() { ...
───────────────────────────────────────────
 kimi  ✓ Complete · 3 files · 2.3s
───────────────────────────────────────────
```

## Features

### Intelligent Routing
Tasks are analyzed and routed based on confidence scores:

| Confidence | Action | Example |
|------------|--------|---------|
| **≥80%** | Auto-delegate | "Design a landing page" → Kimi |
| **50-80%** | Suggest | "Create a nice UI" → Suggest Kimi? |
| **<50%** | Stay local | "Fix this bug" → Claude handles it |

### Explicit Delegation
Take control with the `@cli` syntax:

```bash
@kimi design a modal component
@gemini research best practices for authentication
@codex analyze this entire codebase for security issues

# Shorthand aliases
@k @g @c
```

### Parallel Execution
Independent tasks run simultaneously:

```
You: @kimi create the UI components @gemini write the documentation

[kimi] Building Header.tsx...     [gemini] Generating API docs...
[kimi] Building Sidebar.tsx...    [gemini] Writing usage guide...
[kimi] ✓ Complete                 [gemini] ✓ Complete
```

### Smart Fallbacks
If a CLI fails or isn't installed, MMCO gracefully falls back:

```
✗ codex → not found
Routing adjusted: codex tasks → claude fallback
```

## Supported CLIs

| CLI | Strengths | Install |
|-----|-----------|---------|
| **Claude** | Coding, debugging, architecture | [claude.ai/code](https://claude.ai/code) |
| **Kimi** | Frontend, design, UI/UX, animations | `uv tool install kimi-cli` |
| **Gemini** | Research, search, documentation | `npm i -g @anthropic/gemini-cli` |
| **Codex** | Large context, codebase analysis | `npm i -g @openai/codex` |

## Installation

```bash
# Clone to your Claude Code plugins directory
git clone https://github.com/syedadeel2/multi-model-cli-orchestrator.git \
  ~/.claude/plugins/multi-model-cli-orchestrator

# Restart Claude Code - plugin auto-loads
```

## Quick Start

1. **Check status** - See which CLIs are available:
   ```
   /mmco-status
   ```

2. **Delegate explicitly** - Send a task to a specific CLI:
   ```
   @kimi create a signup form with validation
   ```

3. **Let it route** - Just describe your task and MMCO picks the best tool:
   ```
   Design a beautiful landing page with hero section
   → Auto-delegating to kimi (92% confidence)
   ```

## Configuration

### Global Config (`~/.config/mmco/config.yaml`)

```yaml
general:
  auto_delegate: true
  parallel_execution: true
  confidence_threshold:
    auto: 80
    suggest: 50

routing:
  patterns:
    - match: ["landing page", "hero section"]
      cli: kimi
      weight: 40
```

### Project Override (`.mmco.yaml`)

```yaml
routing:
  default_cli: kimi  # This project prefers Kimi for ambiguous tasks
  overrides:
    - match: ["api", "backend"]
      cli: claude
```

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code (Host)                    │
│  ┌─────────────────────────────────────────────────────┐ │
│  │           MMCO Orchestrator Plugin                  │ │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────────────┐   │ │
│  │  │  Router  │  │ Registry │  │ Process Manager │   │ │
│  │  └────┬─────┘  └────┬─────┘  └────────┬────────┘   │ │
│  └───────┼─────────────┼─────────────────┼────────────┘ │
└──────────┼─────────────┼─────────────────┼──────────────┘
           │             │                 │
           ▼             ▼                 ▼
    ┌──────────┐  ┌──────────┐      ┌──────────┐
    │   Kimi   │  │  Gemini  │      │  Codex   │
    │ Frontend │  │ Research │      │ Analysis │
    └──────────┘  └──────────┘      └──────────┘
```

1. **Router** analyzes your task and calculates confidence scores
2. **Registry** tracks installed CLIs and their capabilities
3. **Process Manager** spawns subprocesses and streams output

## Plugin Structure

```
multi-model-cli-orchestrator/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── config/
│   ├── registry.yaml        # CLI definitions & paths
│   └── routing.yaml         # Confidence patterns & thresholds
├── lib/
│   ├── registry.sh          # CLI detection & availability
│   ├── router.sh            # Confidence scoring & routing
│   └── process-manager.sh   # Subprocess spawning & streaming
├── skills/
│   └── delegate/
│       └── SKILL.md         # @cli explicit delegation
├── commands/
│   └── mmco-status.md       # /mmco-status command
├── hooks/
│   ├── hooks.json           # Hook registrations
│   ├── analyze-prompt.sh    # Auto-analyze for delegation
│   └── session-start.sh     # CLI availability check
└── docs/
    └── plans/               # Design documents
```

## Project Status

### Roadmap

- [x] Design document & architecture
- [x] Implementation plan
- [x] Phase 1: Core foundation (plugin scaffold, registry, subprocess spawning)
- [x] Phase 2: Routing intelligence (confidence scoring, pattern matching)
- [x] Phase 3: Delegation flow (hooks, suggestions, approval workflow)
- [ ] Phase 4: Parallel execution
- [ ] Phase 5: Polish & UX (history, stats, advanced config)

**Want to help?** See [Contributing](#contributing) below.

## Contributing

We'd love your help! Here's how:

1. **Star this repo** - Helps others discover it
2. **Try it out** - Report bugs and suggest features in [Issues](../../issues)
3. **Submit PRs** - Check the roadmap above for what needs work
4. **Share** - Tweet about it, write a blog post, tell your friends

### Development

```bash
# Clone the repo
git clone https://github.com/syedadeel2/multi-model-cli-orchestrator.git
cd multi-model-cli-orchestrator

# Test the components
./lib/registry.sh check_all
./lib/router.sh route "design a landing page"
./lib/router.sh scores "research React best practices"
```

## FAQ

**Q: Do I need all the CLIs installed?**
A: No. MMCO detects what's available and routes accordingly. Missing CLIs fall back to Claude.

**Q: Can I add my own CLIs?**
A: Yes! Add them to the registry config with their path and specialty keywords.

**Q: Does this work on Windows?**
A: Yes, via WSL. Native Windows support is planned.

**Q: Is my data sent to multiple providers?**
A: Each CLI handles its own API calls. MMCO only routes tasks—it doesn't proxy your data.

## License

MIT © [Syed Adeel](https://github.com/syedadeel2)

---

<p align="center">
  <b>Stop context-switching between AI tools.</b><br>
  <i>Let MMCO pick the right one for you.</i>
</p>

<p align="center">
  <a href="../../stargazers">⭐ Star</a> •
  <a href="../../issues">🐛 Report Bug</a> •
  <a href="../../issues">💡 Request Feature</a>
</p>
