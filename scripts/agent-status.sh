#!/usr/bin/env bash
# Update the status of a registered agent.
# Usage: agent-status.sh <name> <busy|idle>
# Called from UserPromptSubmit (busy) and Stop (idle) hooks.

set -euo pipefail

# shellcheck source=agent-common.sh
source "$(dirname "$0")/agent-common.sh"

NAME="${1:-}"
STATUS="${2:-}"

if [[ -z "$NAME" || -z "$STATUS" ]]; then
  echo "Usage: agent-status.sh <name> <busy|idle>" >&2
  exit 1
fi

if [[ "$STATUS" != "busy" && "$STATUS" != "idle" ]]; then
  echo "Status must be 'busy' or 'idle'" >&2
  exit 1
fi

update_status "$NAME" "$STATUS"
