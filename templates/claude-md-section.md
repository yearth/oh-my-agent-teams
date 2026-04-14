# Agent Registration

Each session is automatically registered in `~/.agent/active-agents.json` on startup.

**Look up your own name:**
```bash
# AGENT_NAME is injected by opencode; claude-code uses the identity file
MY_NAME="${AGENT_NAME:-$(cat ~/.agent/identity-$PPID 2>/dev/null)}"
echo "$MY_NAME"
```

**Update your summary once you know your task:**
```bash
MY_NAME="${AGENT_NAME:-$(cat ~/.agent/identity-$PPID 2>/dev/null)}"
~/.agent/scripts/agent-update.sh "$MY_NAME" "<task description>"
```

**List all active agents:**
```bash
~/.agent/scripts/agent-list.sh
```
