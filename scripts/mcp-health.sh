#!/usr/bin/env bash
# === Claude Code Harness — mcp-health.sh ===
# Health check with startup timing for all active MCP servers.
# Usage: bash mcp-health.sh
set -euo pipefail

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
SETTINGS="$CLAUDE_HOME/settings.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS="${GREEN}PASS${NC}"; FAIL="${RED}FAIL${NC}"; WARN="${YELLOW}WARN${NC}"

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN} MCP Health Check & Performance Baseline${NC}"
echo -e "${CYAN} $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# --- Parse active MCPs ---
echo "--- Active MCP Servers ---"
MCP_LIST=$(python3 -c "
import json
with open('$SETTINGS') as f:
    data = json.load(f)
servers = data.get('mcpServers', {})
for name, cfg in servers.items():
    cmd = cfg.get('command', cfg.get('url', 'http'))
    desc = cfg.get('description', 'no description')
    print(f'{name}|{cmd}|{desc}')
" 2>/dev/null)

echo "$MCP_LIST" | while IFS='|' read -r name cmd desc; do
  [ -z "$name" ] && continue
  echo -e "  ${CYAN}$name${NC} — $cmd"
  echo "    $desc"
done
echo ""

# --- Runtime checks ---
echo "--- Runtime Checks ---"
command -v node &>/dev/null && echo -e "  [$PASS] node $(node -v)" || echo -e "  [$FAIL] node not found"
command -v npx &>/dev/null && echo -e "  [$PASS] npx $(npx -v 2>/dev/null || echo '?')" || echo -e "  [$FAIL] npx not found"
command -v python3 &>/dev/null && echo -e "  [$PASS] python3 $(python3 --version 2>&1)" || echo -e "  [$WARN] python3 not found"
command -v git &>/dev/null && echo -e "  [$PASS] git $(git --version 2>&1 | cut -d' ' -f3)" || echo -e "  [$WARN] git not found"
echo ""

# --- Token checks ---
echo "--- Environment Variables ---"
check_var() {
  local name="$1" hint="${2:-}"
  if [ -n "${!name:-}" ]; then
    local val="${!name}"
    echo -e "  [$PASS] $name = ${val:0:10}... (${#val} chars)"
  else
    echo -e "  [$WARN] $name not set ${hint:+— $hint}"
  fi
}
check_var "ANTHROPIC_AUTH_TOKEN" "required for Claude Code"
check_var "GITHUB_PAT" "required for github MCP"
check_var "FIRECRAWL_API_KEY" "required for firecrawl MCP"
echo ""

# --- Config files ---
echo "--- Config Files ---"
[ -f "$SETTINGS" ] && echo -e "  [$PASS] settings.json" || echo -e "  [$FAIL] settings.json missing"
[ -f "$CLAUDE_HOME/mcp-configs/on-demand-mcps.json" ] && echo -e "  [$PASS] on-demand-mcps.json" || echo -e "  [$FAIL] on-demand-mcps.json missing"
[ -f "$CLAUDE_HOME/CLAUDE.md" ] && echo -e "  [$PASS] CLAUDE.md" || echo -e "  [$FAIL] CLAUDE.md missing"
echo ""

# --- Cold-start timing ---
echo "--- Cold-Start Timing (quick check) ---"
echo "$MCP_LIST" | while IFS='|' read -r name cmd rest; do
  [ -z "$name" ] && continue
  if [ "$cmd" = "npx" ]; then
    START=$(date +%s%N 2>/dev/null || echo 0)
    timeout 15 npx --yes "${name}" --help &>/dev/null || true
    END=$(date +%s%N 2>/dev/null || echo 0)
    if [ "$START" != "0" ] && [ "$END" != "0" ]; then
      ELAPSED=$(( (END - START) / 1000000 ))
      echo "  ${name}: ${ELAPSED}ms"
    else
      echo "  ${name}: timing unavailable"
    fi
  else
    echo "  ${name}: skip (non-npx)"
  fi
done
echo ""

# --- Summary ---
TOTAL=$(echo "$MCP_LIST" | grep -c '|' 2>/dev/null || echo "?")
echo -e "${CYAN}--- Summary ---${NC}"
echo "  Active MCPs: $TOTAL"
echo "  Platform: $(uname -s)"
echo "  Claude Home: $CLAUDE_HOME"
echo ""
echo "Run 'bash $CLAUDE_HOME/scripts/mcp-toggle.sh list' for on-demand catalog."
echo -e "${CYAN}============================================${NC}"
