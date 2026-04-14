# oh-my-agent-teams

A shared agent registry for multi-agent workflows. Tracks active AI agents across claude-code and opencode sessions, enabling agents to discover each other and communicate.

## How it works

Each agent session automatically registers itself in `~/.agent/active-agents.json` with its name, pane ID, working directory, and a summary of its current task. Any agent can query this registry to find and message other agents.

## Install

```bash
git clone https://github.com/yearth/oh-my-agent-teams.git
cd oh-my-agent-teams
bash install.sh
```

Then restart claude-code / opencode.

## Usage

**List active agents:**
```bash
~/.agent/scripts/agent-list.sh
```

**Send a message to another agent (zellij):**
```bash
PANE=$(jq -r '.["swift-fox"].paneId' ~/.agent/active-agents.json)
SESSION=$(ps eww -p $(jq -r '.["swift-fox"].pid' ~/.agent/active-agents.json) 2>/dev/null \
  | grep -o 'ZELLIJ_SESSION_NAME=[^ ]*' | cut -d= -f2)
zellij --session "$SESSION" action write-chars --pane-id "$PANE" "your message"
zellij --session "$SESSION" action send-keys  --pane-id "$PANE" "Enter"
```

**Update your summary:**
```bash
MY_NAME="${AGENT_NAME:-$(cat ~/.agent/identity-$PPID 2>/dev/null)}"
~/.agent/scripts/agent-update.sh "$MY_NAME" "implementing auth module"
```

## Registry format

```json
{
  "swift-fox": {
    "paneId": 2,
    "pid": 36838,
    "role": "dev",
    "cwd": "/path/to/project",
    "summary": "implementing auth module",
    "startedAt": "2026-04-14T10:00:00Z",
    "tool": "claude-code"
  }
}
```

## Supported tools

| Tool | Registration | Identity |
|------|-------------|----------|
| claude-code | SessionStart/SessionEnd hooks | `~/.agent/identity-$PPID` |
| opencode | `session.created/deleted` plugin events | `$AGENT_NAME` env var |

## Requirements

- `jq`
- zellij >= 0.44.1 (for agent messaging)
