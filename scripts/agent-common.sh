#!/usr/bin/env bash
# Shared helpers sourced by other agent scripts.

REGISTRY="${REGISTRY:-$HOME/.agent/active-agents.json}"

# Resolve the current agent's name.
# Sets MY_NAME — empty string if not found.
resolve_my_name() {
  MY_NAME="${AGENT_NAME:-}"
  if [[ -z "$MY_NAME" ]]; then
    MY_NAME="$(cat "$HOME/.agent/identity-$PPID" 2>/dev/null || true)"
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
