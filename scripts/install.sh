#!/usr/bin/env bash
# === Claude Config Manager — install.sh ===
# Installs the MCP management scripts and sets up the `mcp` alias.
# Usage: bash install.sh
set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS="${GREEN}PASS${NC}"

MANAGER_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN} Claude Config Manager — Installer${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# --- Install scripts ---
mkdir -p "$CLAUDE_HOME/scripts"

cp "$MANAGER_DIR/scripts/mcp-toggle.sh" "$CLAUDE_HOME/scripts/"
cp "$MANAGER_DIR/scripts/mcp-health.sh" "$CLAUDE_HOME/scripts/"
chmod +x "$CLAUDE_HOME/scripts/mcp-toggle.sh" "$CLAUDE_HOME/scripts/mcp-health.sh" 2>/dev/null || true

echo -e "  [$PASS] Scripts installed to ~/.claude/scripts/"

# --- Set up `mcp` alias ---
SHELL_RC=""
if [ -f "$HOME/.bashrc" ]; then SHELL_RC="$HOME/.bashrc"; fi
if [ -f "$HOME/.zshrc" ]; then SHELL_RC="$HOME/.zshrc"; fi
if [ -f "$HOME/.bash_profile" ]; then SHELL_RC="$HOME/.bash_profile"; fi

if [ -n "$SHELL_RC" ]; then
  if ! grep -q "alias mcp=" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Claude Config Manager — mcp alias" >> "$SHELL_RC"
    echo "alias mcp='bash $CLAUDE_HOME/scripts/mcp-toggle.sh'" >> "$SHELL_RC"
    echo "alias mcp-health='bash $CLAUDE_HOME/scripts/mcp-health.sh'" >> "$SHELL_RC"
    echo -e "  [$PASS] Alias added to $SHELL_RC"
    echo "         Run 'source $SHELL_RC' or open a new terminal."
  else
    echo "  [INFO] mcp alias already configured"
  fi
else
  echo "  [INFO] No .bashrc/.zshrc found. Add manually:"
  echo "         alias mcp='bash $CLAUDE_HOME/scripts/mcp-toggle.sh'"
  echo "         alias mcp-health='bash $CLAUDE_HOME/scripts/mcp-health.sh'"
fi

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${GREEN} Install complete!${NC}"
echo ""
echo "  Commands:"
echo "    mcp list              — show all MCPs"
echo "    mcp enable <name>     — enable an MCP"
echo "    mcp disable <name>    — disable an MCP"
echo "    mcp enable-all <grp>  — enable a group"
echo "    mcp disable-all       — disable all on-demand"
echo "    mcp-health            — health check + timing"
echo ""
echo "  NOTE: Requires on-demand-mcps.json catalog."
echo "  Get it from claude-code-harness or create your own at"
echo "  ~/.claude/mcp-configs/on-demand-mcps.json"
echo -e "${CYAN}============================================${NC}"
