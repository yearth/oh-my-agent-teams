#!/usr/bin/env bash
# Remove an agent from the registry and prune stale entries.
# Usage: agent-unregister.sh <name>

set -euo pipefail

REGISTRY="$HOME/.agent/active-agents.json"
NAME="${1:-}"

if [[ ! -f "$REGISTRY" ]]; then
  exit 0
fi

# Read pid before deleting (so identity file can be cleaned up)
if [[ -n "$NAME" ]]; then
  PID=$(jq -r --arg name "$NAME" '.[$name].pid // empty' "$REGISTRY")
  [[ -n "$PID" ]] && rm -f "$HOME/.agent/identity-$PID"
fi

# Delete named entry + prune stale pids in a single jq + shell pass
LIVE_KEYS=$(jq -r --arg name "$NAME" \
  'to_entries[] | select(.key != $name) | "\(.value.pid)\t\(.key)"' "$REGISTRY" | \
  while IFS=$'\t' read -r pid key; do
    kill -0 "$pid" 2>/dev/null && echo "$key"
  done | jq -Rn '[inputs]')

jq --argjson keys "$LIVE_KEYS" \
  'with_entries(select(.key as $k | $keys | index($k) != null))' \
  "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
