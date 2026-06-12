# Usage Guide

## Setup

### Prerequisites

1. Claude Code installed (v2.1.150+)
2. Git Bash (Windows) or Terminal (macOS/Linux)
3. Python 3 (for JSON processing)

### Install

```bash
git clone https://github.com/cqh-xmf/claude-config-manager.git ~/.claude-config-manager
bash ~/.claude-config-manager/scripts/install.sh
source ~/.bashrc  # or ~/.zshrc
```

### What gets installed

- `~/.claude/scripts/mcp-toggle.sh` — MCP management script
- `~/.claude/scripts/mcp-health.sh` — Health check script
- Shell aliases: `mcp` and `mcp-health`

---

## Daily Use

### Check what's running

```bash
mcp list
```

Sample output:
```
=== Core MCPs (always on) ===
  [ON]  context7
  [ON]  sequential-thinking
  [ON]  memory
  [ON]  filesystem
  [ON]  magic
  [ON]  playwright
  [ON]  github
  [ON]  firecrawl

=== On-Demand MCPs ===
  [search]
    [OFF] exa-web-search
    [OFF] tavily
    [OFF] brave-search
  [media]
    [OFF] fal-ai
    [OFF] figma
  ...

Total enabled: 8
```

### Enable an MCP when you need it

```bash
mcp enable figma
# Output: OK figma enabled — restart Claude Code
```

Restart Claude Code. Done.

### Disable when you're done

```bash
mcp disable figma
# Output: OK figma disabled — restart Claude Code
```

### Enable a whole group at once

```bash
mcp enable-all search    # All search MCPs
mcp enable-all deploy    # Vercel, Cloudflare, ClickHouse
```

### Back to basics

```bash
mcp disable-all
# Removes all on-demand MCPs, keeps core 8
```

### Health check

```bash
mcp-health
```

Shows everything about your MCP setup.

---

## MCP Catalog

The on-demand catalog at `~/.claude/mcp-configs/on-demand-mcps.json` contains 17 pre-configured MCPs. Each has:

- A unique name
- A command (npx, uvx, or HTTP endpoint)
- Required environment variables
- A description

### Adding your own MCP to the catalog

Edit `~/.claude/mcp-configs/on-demand-mcps.json`:

```json
{
  "mcpServers": {
    "my-custom-mcp": {
      "command": "npx",
      "args": ["-y", "my-custom-mcp-server"],
      "env": { "MY_API_KEY": "${MY_API_KEY}" },
      "description": "My custom MCP server"
    }
  }
}
```

Then:
```bash
mcp enable my-custom-mcp
```

---

## Troubleshooting

### "python3 not found"
Install Python 3. On Windows: `winget install Python.Python.3`. On macOS: `brew install python3`.

### "settings.json not found"
Run `claude` once to initialize Claude Code, which creates `~/.claude/settings.json`.

### "NOT_FOUND in catalog"
The MCP name isn't in `on-demand-mcps.json`. Check the name or add it to the catalog.

### "BLOCKED — core MCP"
You tried to disable a core MCP. Core MCPs (`context7`, `sequential-thinking`, `memory`, `filesystem`, `magic`, `playwright`, `github`, `firecrawl`) are protected.
