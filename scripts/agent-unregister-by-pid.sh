#!/usr/bin/env bash
# Unregister the agent whose pid matches the current process's parent (PPID).
# Called from SessionEnd hook — no arguments needed.

set -euo pipefail

REGISTRY="$HOME/.agent/active-agents.json"
LOG="$HOME/.agent/registry.log"
log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [unregister-by-pid] $*" >> "$LOG"; }

log "called: PPID=$PPID"

if [[ ! -f "$REGISTRY" ]]; then
  log "registry not found, skip"
  exit 0
fi

# Find the entry whose pid matches PPID (the claude process that's ending)
NAME=$(jq -r --argjson ppid "$PPID" \
  'to_entries[] | select(.value.pid == $ppid) | .key' \
  "$REGISTRY" 2>/dev/null | head -1)

if [[ -n "$NAME" ]]; then
  log "unregistering: name=$NAME"
  exec "$HOME/.agent/scripts/agent-unregister.sh" "$NAME"
else
  log "no entry found for PPID=$PPID, registry keys: $(jq -r 'keys[]' "$REGISTRY" 2>/dev/null | tr '\n' ' ')"
fi
