#!/usr/bin/env bash
# Mark the current agent as busy. Called from UserPromptSubmit hook.

# shellcheck source=agent-common.sh
source "$(dirname "$0")/agent-common.sh"

resolve_my_name
[[ -n "$MY_NAME" ]] && update_status "$MY_NAME" busy || true
