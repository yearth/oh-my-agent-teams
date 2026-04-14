---
name: agent-messaging
description: Use when sending a message to another Claude agent, coordinating between multiple agents running in parallel, or looking up what other agents are currently active. Agents are registered automatically in ~/.agent/active-agents.json on session start. Currently implemented via zellij (tmux support planned).
---

# Agent Messaging

Send messages to other active agents by name. The registry tracks each agent's status (`idle`/`busy`) and handles delivery automatically — direct if the target is idle, queued in their inbox if busy.

## Find Active Agents

```bash
~/.agent/scripts/agent-list.sh
```

Output includes `status` field:
```json
{
  "swift-fox": { "paneId": 1, "pid": 36838, "status": "idle", "summary": "waiting for input" },
  "iron-leaf":  { "paneId": 3, "pid": 41200, "status": "busy", "summary": "implementing auth" }
}
```

## Send a Message

Use `agent-send.sh` — it handles routing automatically:
- Target **idle**: delivers immediately via zellij
- Target **busy**: writes to inbox, delivered on next Stop

```bash
~/.agent/scripts/agent-send.sh swift-fox "API schema is ready, you can start the client"
```

Limits: content ≤ 500 chars, inbox ≤ 50KB per agent, no self-messaging.

## Check Your Own Identity

```bash
MY_NAME="${AGENT_NAME:-$(cat ~/.agent/identity-$PPID 2>/dev/null)}"
echo "$MY_NAME"
```

## Update Your Summary

```bash
MY_NAME="${AGENT_NAME:-$(cat ~/.agent/identity-$PPID 2>/dev/null)}"
~/.agent/scripts/agent-update.sh "$MY_NAME" "your task description"
```

## How Inbox Works

When you receive inbox messages, they are injected at the start of your next turn via `systemMessage`. Read them and respond or act accordingly. Messages older than 1 hour are automatically discarded.

## Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Agent not in registry | Session started before hook was configured | Re-open session |
| Inbox full | Too many queued messages | Ask sender to wait; you'll process them next turn |
| `--pane-id` flag not recognized | zellij < 0.44.1 | Upgrade: `cargo install --locked zellij` |
