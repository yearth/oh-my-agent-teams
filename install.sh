#!/usr/bin/env bash
# Agent System Installer
# Installs the shared agent registry and configures claude-code hooks.
# Optionally configures the opencode plugin if opencode is detected.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$HOME/.agent"
SCRIPTS_DIR="$AGENT_DIR/scripts"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

# ── colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; exit 1; }

echo ""
echo "Installing Agent System..."
echo ""

# ── 1. check dependencies ─────────────────────────────────────────────────────
command -v jq >/dev/null 2>&1 || fail "jq is required. Install with: brew install jq"

# ── 2. install scripts ────────────────────────────────────────────────────────
mkdir -p "$SCRIPTS_DIR"
cp "$REPO_DIR/scripts/"*.sh "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/"*.sh
echo '{}' > "$AGENT_DIR/active-agents.json"
ok "Scripts installed to $SCRIPTS_DIR"

# ── 3. configure claude-code hooks ───────────────────────────────────────────
if [[ -f "$CLAUDE_SETTINGS" ]]; then
  # Check if hooks already exist
  if jq -e '.hooks.SessionStart[]?.hooks[]?.command | select(contains("agent-register"))' "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
    warn "claude-code hooks already configured, skipping"
  else
    UPDATED=$(jq \
      --arg reg     "$SCRIPTS_DIR/agent-register.sh" \
      --arg unreg   "$SCRIPTS_DIR/agent-unregister-by-pid.sh" \
      --arg consume "$SCRIPTS_DIR/agent-consume-inbox.sh" \
      --arg busy    "$SCRIPTS_DIR/agent-set-busy.sh" \
      '
      .hooks.SessionStart     = ([{"hooks": [{"type": "command", "command": $reg}]}]                                  + (.hooks.SessionStart // [])) |
      .hooks.SessionEnd       = ([{"hooks": [{"type": "command", "command": $unreg, "async": true}]}]                 + (.hooks.SessionEnd // [])) |
      .hooks.UserPromptSubmit = ([{"hooks": [{"type": "command", "command": $busy,  "async": true}]}]                 + (.hooks.UserPromptSubmit // [])) |
      .hooks.Stop             = ([{"hooks": [{"type": "command", "command": $consume, "asyncRewake": true}]}]         + (.hooks.Stop // []))
      ' "$CLAUDE_SETTINGS")
    echo "$UPDATED" > "$CLAUDE_SETTINGS"
    ok "claude-code hooks configured in $CLAUDE_SETTINGS"
  fi
else
  warn "~/.claude/settings.json not found, skipping claude-code hook setup"
  warn "To configure manually, add hooks pointing to scripts in: $SCRIPTS_DIR"
fi

# ── 4. configure CLAUDE.md ───────────────────────────────────────────────────
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
TEMPLATE="$REPO_DIR/templates/claude-md-section.md"

if [[ -f "$CLAUDE_MD" ]]; then
  if grep -q "Agent Registration" "$CLAUDE_MD" 2>/dev/null; then
    warn "CLAUDE.md already contains agent instructions, skipping"
  else
    { echo ""; cat "$TEMPLATE"; } >> "$CLAUDE_MD"
    ok "Agent instructions appended to $CLAUDE_MD"
  fi
else
  mkdir -p "$(dirname "$CLAUDE_MD")"
  cp "$TEMPLATE" "$CLAUDE_MD"
  ok "Created $CLAUDE_MD with agent instructions"
fi

# ── 5. configure opencode plugin (optional) ──────────────────────────────────
OPENCODE_CONFIG="$HOME/.config/opencode/config.json"
OPENCODE_PLUGINS_DIR="$HOME/.config/opencode/plugins"
PLUGIN_SRC="$REPO_DIR/plugins/agent-registry.js"
PLUGIN_DEST="$OPENCODE_PLUGINS_DIR/agent-registry.js"

if [[ -f "$OPENCODE_CONFIG" ]]; then
  mkdir -p "$OPENCODE_PLUGINS_DIR"
  cp "$PLUGIN_SRC" "$PLUGIN_DEST"

  PLUGIN_URI="file://$PLUGIN_DEST"
  if jq -e --arg uri "$PLUGIN_URI" '.plugin // [] | index($uri) != null' "$OPENCODE_CONFIG" >/dev/null 2>&1; then
    warn "opencode plugin already registered, skipping"
  else
    UPDATED=$(jq --arg uri "$PLUGIN_URI" '.plugin = ((.plugin // []) + [$uri])' "$OPENCODE_CONFIG")
    echo "$UPDATED" > "$OPENCODE_CONFIG"
    ok "opencode plugin registered in $OPENCODE_CONFIG"
  fi
else
  warn "~/.config/opencode/config.json not found, skipping opencode setup"
fi

# ── 6. install claude-code skill ─────────────────────────────────────────────
# Skills are claude-code specific; opencode has no equivalent mechanism.
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
SKILL_SRC="$REPO_DIR/skills/agent-messaging"
SKILL_DEST="$CLAUDE_SKILLS_DIR/agent-messaging"

if [[ -d "$HOME/.claude" ]]; then
  if [[ -d "$SKILL_DEST" ]]; then
    warn "agent-messaging skill already installed, skipping"
  else
    mkdir -p "$CLAUDE_SKILLS_DIR"
    cp -r "$SKILL_SRC" "$SKILL_DEST"
    ok "agent-messaging skill installed to $SKILL_DEST"
  fi
else
  warn "~/.claude not found, skipping skill installation"
fi

# ── done ──────────────────────────────────────────────────────────────────────
echo ""
echo "Done! Restart claude-code / opencode for hooks to take effect."
echo ""
echo "Quick test:"
echo "  ~/.agent/scripts/agent-list.sh"
echo ""
