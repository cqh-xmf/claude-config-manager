#!/usr/bin/env bash
# === Claude Code Harness — mcp-toggle.sh ===
# Enable/disable on-demand MCP servers without manual JSON editing.
# Usage:
#   mcp-toggle.sh list                          — show all MCPs and status
#   mcp-toggle.sh enable <name>                 — enable one
#   mcp-toggle.sh disable <name>                — disable one
#   mcp-toggle.sh enable-all <group>            — enable group
#   mcp-toggle.sh disable-all                   — disable all on-demand
set -euo pipefail

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
SETTINGS="$CLAUDE_HOME/settings.json"
ON_DEMAND="$CLAUDE_HOME/mcp-configs/on-demand-mcps.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# --- Group definitions ---
declare -A GROUPS
GROUPS[search]="exa-web-search tavily brave-search"
GROUPS[media]="fal-ai figma"
GROUPS[platform]="notion slack linear jira confluence supabase"
GROUPS[deploy]="vercel cloudflare-docs clickhouse"
GROUPS[browser]="browserbase browser-use"
GROUPS[tools]="longhand evalview devfleet"

die() { echo -e "${RED}ERROR:${NC} $*" >&2; exit 1; }

is_enabled() {
  python3 -c "
import json
try:
    with open('$SETTINGS') as f:
        data = json.load(f)
    servers = data.get('mcpServers', {})
    print('yes' if '$1' in servers else 'no')
except Exception:
    print('unknown')
" 2>/dev/null
}

get_block() {
  python3 -c "
import json
try:
    with open('$ON_DEMAND') as f:
        data = json.load(f)
    block = data.get('mcpServers', {}).get('$1')
    if block:
        print(json.dumps(block, indent=2))
    else:
        print('NOT_FOUND')
except Exception:
    print('ERROR')
" 2>/dev/null
}

enable_mcp() {
  local name="$1"
  local status; status=$(is_enabled "$name")
  if [ "$status" = "yes" ]; then
    echo -e "  ${YELLOW}SKIP${NC} $name — already enabled"
    return
  fi

  local block; block=$(get_block "$name")
  if [ "$block" = "NOT_FOUND" ]; then
    echo -e "  ${RED}FAIL${NC} $name — not in on-demand catalog"
    return 1
  fi

  python3 -c "
import json
with open('$SETTINGS') as f:
    settings = json.load(f)
with open('$ON_DEMAND') as f:
    catalog = json.load(f)
block = catalog['mcpServers'].get('$name')
if block:
    settings['mcpServers']['$name'] = block
    with open('$SETTINGS', 'w') as f:
        json.dump(settings, f, indent=2)
    print('ok')
" 2>/dev/null

  echo -e "  ${GREEN}OK${NC} $name enabled — restart Claude Code"
}

disable_mcp() {
  local name="$1"
  local status; status=$(is_enabled "$name")
  if [ "$status" = "no" ]; then
    echo -e "  ${YELLOW}SKIP${NC} $name — not enabled"
    return
  fi

  local core; core=("context7" "sequential-thinking" "memory" "filesystem" "magic" "playwright" "github" "firecrawl")
  for c in "${core[@]}"; do
    if [ "$name" = "$c" ]; then
      echo -e "  ${RED}BLOCKED${NC} $name — core MCP, cannot disable"
      return 1
    fi
  done

  python3 -c "
import json
with open('$SETTINGS') as f:
    settings = json.load(f)
if '$name' in settings.get('mcpServers', {}):
    del settings['mcpServers']['$name']
    with open('$SETTINGS', 'w') as f:
        json.dump(settings, f, indent=2)
    print('ok')
" 2>/dev/null

  echo -e "  ${GREEN}OK${NC} $name disabled — restart Claude Code"
}

list_all() {
  echo ""
  echo -e "${CYAN}=== Core MCPs (always on) ===${NC}"
  local core; core=("context7" "sequential-thinking" "memory" "filesystem" "magic" "playwright" "github" "firecrawl")
  for c in "${core[@]}"; do
    local s; s=$(is_enabled "$c")
    if [ "$s" = "yes" ]; then
      echo -e "  ${GREEN}[ON]${NC}  $c"
    else
      echo -e "  ${RED}[OFF]${NC} $c"
    fi
  done

  echo ""
  echo -e "${CYAN}=== On-Demand MCPs ===${NC}"
  for group in search media platform deploy browser tools; do
    echo -e "  ${YELLOW}[$group]${NC}"
    for mcp in ${GROUPS[$group]}; do
      local s; s=$(is_enabled "$mcp")
      if [ "$s" = "yes" ]; then
        echo -e "    ${GREEN}[ON]${NC}  $mcp"
      elif [ "$s" = "no" ]; then
        echo -e "    ${CYAN}[OFF]${NC} $mcp"
      else
        echo -e "    ${RED}[ERR]${NC} $mcp"
      fi
    done
  done

  local total; total=$(python3 -c "import json; f=open('$SETTINGS'); d=json.load(f); print(len(d.get('mcpServers',{})))" 2>/dev/null || echo "?")
  echo ""
  echo -e "${CYAN}Total enabled:${NC} $total"
}

case "${1:-}" in
  list|ls|status) list_all ;;
  enable)
    [ -z "${2:-}" ] && die "Usage: mcp-toggle.sh enable <name>"
    enable_mcp "$2" ;;
  disable)
    [ -z "${2:-}" ] && die "Usage: mcp-toggle.sh disable <name>"
    disable_mcp "$2" ;;
  enable-all)
    grp="${2:-}";
    if [ -n "$grp" ] && [ -n "${GROUPS[$grp]:-}" ]; then
      echo "Enabling all [$grp] MCPs..."
      for mcp in ${GROUPS[$grp]}; do enable_mcp "$mcp"; done
    else
      die "Usage: mcp-toggle.sh enable-all <group>  (groups: ${!GROUPS[*]})"
    fi ;;
  disable-all)
    echo "Disabling all on-demand MCPs..."
    for group in search media platform deploy browser tools; do
      for mcp in ${GROUPS[$group]}; do disable_mcp "$mcp" 2>/dev/null || true; done
    done ;;
  *) echo "Usage: mcp-toggle.sh {list|enable <name>|disable <name>|enable-all <group>|disable-all}"
     echo ""
     echo "Groups: search, media, platform, deploy, browser, tools"
     echo ""
     echo "Examples:"
     echo "  mcp-toggle.sh list"
     echo "  mcp-toggle.sh enable fal-ai"
     echo "  mcp-toggle.sh enable-all search"
     echo "  mcp-toggle.sh disable-all" ;;
esac
