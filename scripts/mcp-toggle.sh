#!/usr/bin/env bash
# === Claude Code Harness — mcp-toggle.sh ===
# Usage: mcp {list|enable|disable|enable-all|disable-all|recipe|freshness|score}
set -euo pipefail

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
HARNESS_DIR="${HARNESS_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
SETTINGS="$CLAUDE_HOME/settings.json"
ON_DEMAND="$CLAUDE_HOME/mcp-configs/on-demand-mcps.json"
[ ! -f "$ON_DEMAND" ] && ON_DEMAND="$HARNESS_DIR/mcp-configs/on-demand-mcps.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

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
    with open('$SETTINGS') as f: data=json.load(f)
    print('yes' if '$1' in data.get('mcpServers',{}) else 'no')
except: print('unknown')
" 2>/dev/null
}

get_block() {
  python3 -c "
import json
with open('$ON_DEMAND') as f: data=json.load(f)
b=data.get('mcpServers',{}).get('$1')
print(json.dumps(b,indent=2) if b else 'NOT_FOUND')
" 2>/dev/null
}

enable_mcp() {
  local name="$1"
  [ "$(is_enabled "$name")" = "yes" ] && { echo -e "  ${YELLOW}SKIP${NC} $name — already enabled"; return; }
  [ "$(get_block "$name")" = "NOT_FOUND" ] && { echo -e "  ${RED}FAIL${NC} $name — not in catalog"; return 1; }
  python3 -c "
import json
with open('$SETTINGS') as f: s=json.load(f)
with open('$ON_DEMAND') as f: c=json.load(f)
b=c['mcpServers'].get('$name')
if b: s['mcpServers']['$name']=b; json.dump(s,open('$SETTINGS','w'),indent=2)
" 2>/dev/null
  echo -e "  ${GREEN}OK${NC} $name enabled — restart Claude Code"
}

disable_mcp() {
  local name="$1"
  [ "$(is_enabled "$name")" = "no" ] && { echo -e "  ${YELLOW}SKIP${NC} $name — not enabled"; return; }
  local core=("context7" "sequential-thinking" "memory" "filesystem" "magic" "playwright" "github" "firecrawl")
  for c in "${core[@]}"; do
    [ "$name" = "$c" ] && { echo -e "  ${RED}BLOCKED${NC} $name — core MCP, cannot disable"; return 1; }
  done
  python3 -c "
import json
s=json.load(open('$SETTINGS'))
if '$name' in s.get('mcpServers',{}): del s['mcpServers']['$name']; json.dump(s,open('$SETTINGS','w'),indent=2)
" 2>/dev/null
  echo -e "  ${GREEN}OK${NC} $name disabled — restart Claude Code"
}

list_all() {
  echo ""
  echo -e "${CYAN}=== Core MCPs (always on) ===${NC}"
  for c in context7 sequential-thinking memory filesystem magic playwright github firecrawl; do
    local s=$(is_enabled "$c")
    [ "$s" = "yes" ] && echo -e "  ${GREEN}[ON]${NC}  $c" || echo -e "  ${RED}[OFF]${NC} $c"
  done
  echo ""
  echo -e "${CYAN}=== On-Demand MCPs ===${NC}"
  for group in search media platform deploy browser tools; do
    echo -e "  ${YELLOW}[$group]${NC}"
    for mcp in ${GROUPS[$group]}; do
      local s=$(is_enabled "$mcp")
      [ "$s" = "yes" ] && echo -e "    ${GREEN}[ON]${NC}  $mcp" || echo -e "    ${CYAN}[OFF]${NC} $mcp"
    done
  done
  local total=$(python3 -c "import json; print(len(json.load(open('$SETTINGS')).get('mcpServers',{})))" 2>/dev/null || echo "?")
  echo ""
  echo -e "${CYAN}Total enabled:${NC} $total"
}

cmd_recipe() {
  local RECIPES="$CLAUDE_HOME/mcp-configs/recipes.json"
  [ ! -f "$RECIPES" ] && RECIPES="$HARNESS_DIR/mcp-configs/recipes.json"
  [ ! -f "$RECIPES" ] && { echo "recipes.json not found"; return; }
  if [ "${1:-}" = "list" ] || [ -z "${1:-}" ]; then
    echo ""
    echo -e "${CYAN}=== Available Recipes ===${NC}"
    python3 -c "
import json
for n,r in json.load(open('$RECIPES')).get('recipes',{}).items():
    print(f'  {n}')
    print(f'    {r[\"description\"]}')
    print(f'    {\" → \".join(r[\"tools\"])}  [{r[\"mode\"]}]')
    print()
" 2>/dev/null
    echo "Usage: mcp recipe <name>"
  else
    python3 -c "
import json
r=json.load(open('$RECIPES')).get('recipes',{}).get('${1}')
if r:
    print(f\"\nRecipe: ${1}\"); print(f\"  {r['description']}\"); print(f\"  Mode: {r['mode']}\")
    print(f\"  Tools: {' → '.join(r['tools'])}\"); print(f\"  Output: {r['output']}\")
    print(f\"\nTrigger: ask Claude Code to 'run the ${1} recipe'\")
else:
    print(f\"Recipe '${1}' not found. Try: mcp recipe list\")
" 2>/dev/null
  fi
}

cmd_freshness() {
  local FRESH="$CLAUDE_HOME/scripts/mcp-freshness.sh"
  [ ! -f "$FRESH" ] && FRESH="$HARNESS_DIR/scripts/mcp-freshness.sh"
  [ -f "$FRESH" ] && bash "$FRESH" || echo "mcp-freshness.sh not found"
}

cmd_score() {
  echo ""
  echo -e "${CYAN}=== Claude Code Harness Score ===${NC}"
  local S=0 M=0
  local N=$(python3 -c "import json; print(len(json.load(open('$SETTINGS')).get('mcpServers',{})))" 2>/dev/null || echo 0)
  ((M+=25)); local P=$(( N>=8?25:N*3 )); ((S+=P))
  echo -e "  MCP Online:      $N/8  ($P/25) $([ $N -ge 8 ] && echo '✅' || echo '⚠️')"
  local T=0; [ -n "${GITHUB_PAT:-}" ] && ((T++)); [ -n "${FIRECRAWL_API_KEY:-}" ] && ((T++)); [ -n "${ANTHROPIC_AUTH_TOKEN:-}" ] && ((T++))
  ((M+=20)); local TP=$(( T*6+(T==3?2:0) )); ((S+=TP))
  echo -e "  Tokens Set:      $T/3  ($TP/20) $([ $T -ge 3 ] && echo '✅' || echo '⚠️')"
  local AD="$CLAUDE_HOME/agents"; [ ! -d "$AD" ] && AD="$HARNESS_DIR/agents"
  local AC=$(ls "$AD"/*.md 2>/dev/null | wc -l || echo 0)
  ((M+=20)); local AP=$(( AC>=30?20:AC*2/3 )); ((S+=AP))
  echo -e "  Agents Ready:    $AC  ($AP/20) $([ $AC -ge 30 ] && echo '✅' || echo '⚠️')"
  local RD="$CLAUDE_HOME/rules"; [ ! -d "$RD" ] && RD="$HARNESS_DIR/rules"
  local RC=$(find "$RD" -name "*.md" 2>/dev/null | wc -l || echo 0)
  ((M+=15)); local RP=$(( RC>=10?15:RC )); ((S+=RP))
  echo -e "  Rules Active:    $RC  ($RP/15) $([ $RC -ge 10 ] && echo '✅' || echo '⚠️')"
  local TD="$CLAUDE_HOME/templates/project-claude-md"; [ ! -d "$TD" ] && TD="$HARNESS_DIR/templates/project-claude-md"
  local TC=$(ls "$TD"/*.md 2>/dev/null | wc -l || echo 0)
  ((M+=10)); local TPP=$(( TC>=3?10:TC*3 )); ((S+=TPP))
  echo -e "  Templates:       $TC  ($TPP/10) $([ $TC -ge 3 ] && echo '✅' || echo '⚠️')"
  local RF="$CLAUDE_HOME/mcp-configs/recipes.json"; [ ! -f "$RF" ] && RF="$HARNESS_DIR/mcp-configs/recipes.json"
  local RN=$(python3 -c "import json; print(len(json.load(open('$RF')).get('recipes',{})))" 2>/dev/null || echo 0)
  ((M+=5)); local RPP=$(( RN>=4?5:RN )); ((S+=RPP))
  echo -e "  Recipes:         $RN  ($RPP/5) $([ $RN -ge 4 ] && echo '✅' || echo '💡 mcp recipe list')"
  ((M+=5)); ((S+=3))
  echo -e "  Freshness:       —   (3/5) 💡 mcp freshness"
  local PCT=$((S*100/M))
  echo ""; echo -e "  ${CYAN}Total: $S/$M = $PCT/100${NC}"
  [ $PCT -ge 90 ] && echo -e "  ${GREEN}Excellent! Battle-ready.${NC}"
  [ $PCT -ge 70 ] && [ $PCT -lt 90 ] && echo -e "  ${YELLOW}Good. A few things to tune.${NC}"
  [ $PCT -lt 70 ] && echo -e "  ${YELLOW}Room for improvement.${NC}"
  echo ""
}

case "${1:-}" in
  list|ls|status) list_all ;;
  enable)  [ -z "${2:-}" ] && die "Usage: mcp enable <name>"; enable_mcp "$2" ;;
  disable) [ -z "${2:-}" ] && die "Usage: mcp disable <name>"; disable_mcp "$2" ;;
  enable-all)
    grp="${2:-}"; [ -z "$grp" ] && die "Usage: mcp enable-all <group> (${!GROUPS[*]})"
    [ -z "${GROUPS[$grp]:-}" ] && die "Unknown: $grp"
    echo "Enabling [$grp]..."; for mcp in ${GROUPS[$grp]}; do enable_mcp "$mcp"; done ;;
  disable-all)
    echo "Disabling all on-demand..."; for group in search media platform deploy browser tools; do
      for mcp in ${GROUPS[$group]}; do disable_mcp "$mcp" 2>/dev/null || true; done
    done ;;
  recipe) cmd_recipe "${2:-}" ;;
  freshness) cmd_freshness ;;
  score) cmd_score ;;
  *)
    echo ""
    echo -e "${CYAN}Claude Code Harness CLI${NC}"
    echo "  mcp list           Show all MCPs"
    echo "  mcp enable/disable <name>   Toggle MCP"
    echo "  mcp enable-all <group>      Enable group"
    echo "  mcp disable-all             Disable all on-demand"
    echo "  mcp recipe [name|list]      Multi-tool workflows"
    echo "  mcp freshness               Check for updates"
    echo "  mcp score                   Harness Score 0-100"
    echo "" ;;
esac
