#!/usr/bin/env bash
# List all active agents, filtering out stale entries by pid.
# Usage: agent-list.sh

REGISTRY="$HOME/.agent/active-agents.json"

if [[ ! -f "$REGISTRY" ]]; then
  echo '{}'
  exit 0
fi

# Extract all entries as "pid\tkey" pairs, verify pid liveness, collect live keys,
# then filter registry in a single jq pass — avoids N jq forks per entry.
LIVE_KEYS=$(jq -r 'to_entries[] | "\(.value.pid)\t\(.key)"' "$REGISTRY" | \
  while IFS=$'\t' read -r pid key; do
    kill -0 "$pid" 2>/dev/null && echo "$key"
  done | jq -Rn '[inputs]')

jq --argjson keys "$LIVE_KEYS" 'with_entries(select(.key as $k | $keys | index($k) != null))' "$REGISTRY"
