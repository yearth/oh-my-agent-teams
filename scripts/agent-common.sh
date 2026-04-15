#!/usr/bin/env bash
# Shared helpers sourced by other agent scripts.

REGISTRY="${REGISTRY:-$HOME/.agent/active-agents.json}"

# Resolve the current agent's name.
# Sets MY_NAME — empty string if not found.
# Resolution order: AGENT_NAME env → identity file → registry pid lookup
resolve_my_name() {
  MY_NAME="${AGENT_NAME:-}"
  if [[ -z "$MY_NAME" ]]; then
    MY_NAME="$(cat "$HOME/.agent/identity-$PPID" 2>/dev/null || true)"
  fi
  if [[ -z "$MY_NAME" && -f "$REGISTRY" ]]; then
    # Walk up the process tree to find a pid that matches a registry entry
    local cur="$PPID"
    local depth=0
    while [[ "$cur" -gt 1 && $depth -lt 20 ]]; do
      local found
      found="$(jq -r --argjson pid "$cur" \
        'to_entries[] | select(.value.pid == $pid) | .key' \
        "$REGISTRY" 2>/dev/null | head -1 || true)"
      if [[ -n "$found" ]]; then
        MY_NAME="$found"
        break
      fi
      cur="$(ps -o ppid= -p "$cur" 2>/dev/null | tr -d ' ')" || break
      depth=$(( depth + 1 ))
    done
  fi
}

# Update an agent's status in the registry.
# Usage: update_status <name> <busy|idle>
update_status() {
  local name="$1" status="$2"
  [[ -f "$REGISTRY" ]] || return 0
  jq --arg name "$name" --arg status "$status" \
    'if has($name) then .[$name].status = $status else . end' \
    "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
}
