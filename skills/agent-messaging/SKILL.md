---
name: agent-messaging
description: Use when sending a message to another Claude agent, coordinating between multiple agents running in parallel, or looking up what other agents are currently active. Agents are registered automatically in ~/.agent/active-agents.json on session start. Currently implemented via zellij (tmux support planned).
---

# Agent Messaging

Send messages to other active agents by name. Pane IDs are resolved automatically from the agent registry — no manual lookup needed.

## Transport

Currently implemented via **zellij** (requires zellij 0.44.1 or later). tmux support is planned.

## Find Active Agents

```bash
~/.agent/scripts/agent-list.sh
```

Output example:
```json
{
  "swift-fox": { "paneId": 1, "pid": 36838, "cwd": "/project/a", "summary": "implementing auth module" },
  "iron-leaf":  { "paneId": 3, "pid": 41200, "cwd": "/project/b", "summary": "" }
}
```

## Send a Message

Resolve the target's `paneId` and session name from the registry, then send:

```bash
PANE=$(jq -r '.["swift-fox"].paneId' ~/.agent/active-agents.json)
SESSION=$(ps eww -p $(jq -r '.["swift-fox"].pid' ~/.agent/active-agents.json) 2>/dev/null \
  | grep -o 'ZELLIJ_SESSION_NAME=[^ ]*' | cut -d= -f2)

# Text and Enter must be separate commands
zellij --session "$SESSION" action write-chars --pane-id "$PANE" "your message here"
zellij --session "$SESSION" action send-keys  --pane-id "$PANE" "Enter"
```

> **Note:** `write-chars` and `Enter` must be two separate commands. `\n` inside `write-chars` renders as `^M` and does not submit.

## Update Your Own Summary

Once you know your task, update your summary so other agents can see what you're doing:

```bash
# Find your own name first
MY_NAME=$(jq -r --argjson pid $$ 'to_entries[] | select(.value.pid == $pid) | .key' ~/.agent/active-agents.json)

# Then update
~/.agent/scripts/agent-update.sh "$MY_NAME" "your task description"
```

## Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Agent not in registry | Session started before hook was configured | Check `agent-list.sh`; re-open session if needed |
| Message goes to wrong process | Another process is in foreground of that pane | Confirm target agent is idle and waiting for input |
| `--pane-id` flag not recognized | zellij older than 0.44.1 | Upgrade: `cargo install --locked zellij` |
| Message appears but not submitted | Used `\n` inside `write-chars` | Use separate `send-keys Enter` command |
