#!/usr/bin/env bash
# Register the current agent into ~/.agent/active-agents.json
# Usage: agent-register.sh <name> <role> <tool>
# Called from SessionStart hook. Reads ZELLIJ_PANE_ID from environment.

set -euo pipefail

REGISTRY="$HOME/.agent/active-agents.json"
LOG="$HOME/.agent/registry.log"
log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [register] $*" >> "$LOG"; }
NAME="${1:-}"
ROLE="${2:-dev}"
TOOL="${3:-claude-code}"

if [[ -z "$NAME" ]]; then
  # Generate a random adjective+noun name
  ADJECTIVES=(swift iron bold calm dark bright cold wild sharp keen)
  NOUNS=(fox leaf oak wolf tide pine hawk moss reed fern)
  ADJ=${ADJECTIVES[$RANDOM % ${#ADJECTIVES[@]}]}
  NOUN=${NOUNS[$RANDOM % ${#NOUNS[@]}]}
  NAME="${ADJ}-${NOUN}"
fi

PANE_ID="${ZELLIJ_PANE_ID:-}"
PID="${AGENT_PID:-$PPID}"
log "called: PPID=$PPID PANE_ID=${PANE_ID:-none} PWD=$PWD AGENT_PID=${AGENT_PID:-unset} effective_pid=$PID"
CWD="${PWD}"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Initialize registry if missing
if [[ ! -f "$REGISTRY" ]]; then
  echo '{}' > "$REGISTRY"
fi

# Add entry (requires jq)
UPDATED=$(jq \
  --arg name "$NAME" \
  --arg paneId "$PANE_ID" \
  --argjson pid "$PID" \
  --arg role "$ROLE" \
  --arg cwd "$CWD" \
  --arg tool "$TOOL" \
  --arg startedAt "$STARTED_AT" \
  '.[$name] = {
    "paneId": ($paneId | if . == "" then null else (tonumber? // .) end),
    "pid": $pid,
    "role": $role,
    "cwd": $cwd,
    "summary": "",
    "status": "idle",
    "startedAt": $startedAt,
    "tool": $tool
  }' "$REGISTRY")

echo "$UPDATED" > "$REGISTRY"
log "registered: name=$NAME pid=$PID paneId=${PANE_ID:-null}"

# Write identity file so this session can always look up its own name
echo "$NAME" > "$HOME/.agent/identity-$PID"

# Print name to stderr for callers that need just the name
echo "$NAME" >&2

# Output systemMessage to stdout so Claude Code shows the name to the user on session start
printf '{"systemMessage": "Agent registered: %s (pane %s)"}\n' "$NAME" "$PANE_ID"
