#!/usr/bin/env bash
# Update the summary of a registered agent.
# Usage: agent-update.sh <name> <summary>

set -euo pipefail

REGISTRY="$HOME/.agent/active-agents.json"
NAME="${1:-}"
SUMMARY="${2:-}"

if [[ -z "$NAME" || -z "$SUMMARY" ]]; then
  echo "Usage: agent-update.sh <name> <summary>" >&2
  exit 1
fi

if [[ ! -f "$REGISTRY" ]]; then
  echo "Registry not found: $REGISTRY" >&2
  exit 1
fi

UPDATED=$(jq \
  --arg name "$NAME" \
  --arg summary "$SUMMARY" \
  'if has($name) then .[$name].summary = $summary else . end' \
  "$REGISTRY")

echo "$UPDATED" > "$REGISTRY"
