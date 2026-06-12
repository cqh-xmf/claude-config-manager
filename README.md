# Claude Config Manager

<p align="center">
  <b>Manage Claude Code MCP servers like a package manager.</b><br>
  Enable · Disable · Health check · Performance baseline · One-click toggle
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <a href="#"><img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-brightgreen.svg"></a>
</p>

---

## What is this?

A lightweight toolkit for managing Claude Code MCP servers. No more hand-editing `settings.json` to toggle MCPs — use CLI commands like a package manager.

Works standalone or as part of [Claude Code Harness](https://github.com/cqh-xmf/claude-code-harness).

---

## Quick Install

```bash
git clone https://github.com/cqh-xmf/claude-config-manager.git ~/.claude-config-manager
bash ~/.claude-config-manager/scripts/install.sh
```

---

## Commands

### List MCPs

```bash
mcp list
```

Shows all active and available MCPs, grouped by category:

```
=== Core MCPs (always on) ===
  [ON]  context7
  [ON]  sequential-thinking
  [ON]  memory
  ...

=== On-Demand MCPs ===
  [search]
    [OFF] exa-web-search
    [OFF] tavily
    [OFF] brave-search
  ...
```

### Enable an MCP

```bash
mcp enable fal-ai
mcp enable exa-web-search
```

One command. The MCP config block is copied from the on-demand catalog into `settings.json`.

### Disable an MCP

```bash
mcp disable fal-ai
```

Removes the MCP from `settings.json`. Core MCPs are protected from accidental removal.

### Enable a group

```bash
mcp enable-all search    # enables exa, tavily, brave
mcp enable-all media     # enables fal-ai, figma
mcp enable-all platform  # enables notion, slack, linear, jira, confluence, supabase
```

### Disable everything on-demand

```bash
mcp disable-all
```

Returns to core-8-only mode.

### Health check

```bash
mcp health
```

Shows:
- Active MCP list with descriptions
- Cold-start timing per MCP
- Environment variable status (tokens set?)
- Runtime versions (node, npx, python3, git)
- Config file presence

---

## How it works

```
                    settings.json                     on-demand-mcps.json
                   ┌──────────────┐                  ┌──────────────────┐
                   │ mcpServers:  │    mcp enable     │ exa-web-search   │
                   │   context7 ✅│◀─────────────────│ tavily            │
                   │   github   ✅│  copies block     │ fal-ai           │
                   │   fal-ai   ✅│                  │ figma            │
                   │              │    mcp disable    │ ...              │
                   │   fal-ai   ❌│◀─────────────────│                  │
                   └──────────────┘  removes block    └──────────────────┘
```

- **`settings.json`** — Claude Code's live config (what's currently running)
- **`on-demand-mcps.json`** — Catalog of 17 pre-configured MCPs (ready to enable)
- **`mcp-toggle.sh`** — Moves blocks between catalog and live config
- **`mcp-health.sh`** — Reads live config and reports status

---

## Requirements

- **Bash** (included on macOS/Linux; Git Bash on Windows)
- **Python 3** (for JSON manipulation)
- **Claude Code** v2.1.150+

---

## vs. Editing JSON by Hand

| Task | Manual | Config Manager |
|------|--------|---------------|
| Enable an MCP | Open JSON, find catalog, copy block, paste, restart | `mcp enable <name>` |
| Disable an MCP | Open JSON, find block, delete, be careful not to break syntax, restart | `mcp disable <name>` |
| See what's active | Scroll through JSON, mentally parse | `mcp list` |
| Check health | Manually test each MCP | `mcp health` |
| Enable all search MCPs | Copy 3 blocks | `mcp enable-all search` |

---

## License

MIT — use it, fork it, ship it.
