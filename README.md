# oh-my-agent-teams

[English](./README.md) · [中文](./README.zh.md)

A shared agent registry for multi-agent workflows. Tracks active AI agents across claude-code and opencode sessions, enabling agents to discover each other and communicate.

## How it works

Each agent session automatically registers itself in `~/.agent/active-agents.json` with a generated name, working directory, and a summary of its current task. Any agent can query this registry to find and message other agents.

## Install

```bash
git clone https://github.com/yearth/oh-my-agent-teams.git
cd oh-my-agent-teams
bash install.sh
```

Then restart claude-code / opencode.

## Talking to agents

Once installed, just talk to your agent naturally. The agent knows how to find other agents and send messages to them.

**Ask who's online:**
> "Who are the active agents right now?"

**Ask an agent to send a message:**
> "Send a message to swift-fox: the API schema is ready, you can start implementing the client."

**Ask an agent to check its own identity:**
> "What's your agent name?"

The agent handles the rest — looking up the registry, resolving pane IDs, and delivering the message.

## Supported tools

| Tool | Auto-registration |
|------|------------------|
| claude-code | ✓ via SessionStart/SessionEnd hooks |
| opencode | ✓ via session.created/deleted plugin events |

## Requirements

- `jq`
- zellij >= 0.44.1 (for agent messaging)
