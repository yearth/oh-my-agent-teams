#!/usr/bin/env bash
# Print the current agent's registered name.
# Resolution order:
#   1. AGENT_NAME env var (injected by opencode)
#   2. identity file (~/.agent/identity-<pid>)
#   3. registry lookup by walking up the process tree

# shellcheck source=agent-common.sh
source "$(dirname "$0")/agent-common.sh"

resolve_my_name
echo "$MY_NAME"
