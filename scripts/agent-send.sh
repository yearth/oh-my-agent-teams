#!/usr/bin/env bash
# Send a message to another agent's inbox.
# Usage: agent-send.sh <to> <message>
# If target is idle and running in zellij, delivers immediately via write-chars.
# Otherwise writes to inbox for delivery on next Stop hook.

set -euo pipefail

REGISTRY="$HOME/.agent/active-agents.json"
INBOX_DIR="$HOME/.agent/inbox"
TO="${1:-}"
CONTENT="${2:-}"
CONTENT="${CONTENT%$'\n'}"  # strip trailing newline if any
MAX_CONTENT_LEN=500
MAX_INBOX_BYTES=51200  # 50KB

if [[ -z "$TO" || -z "$CONTENT" ]]; then
  echo "Usage: agent-send.sh <to> <message>" >&2
  exit 1
fi

# Resolve sender name (AGENT_NAME injected by opencode; claude-code uses identity file)
MY_NAME="${AGENT_NAME:-}"
if [[ -z "$MY_NAME" ]]; then
  MY_NAME="$(cat "$HOME/.agent/identity-$PPID" 2>/dev/null || true)"
fi

# Guard: no self-messaging
if [[ -n "$MY_NAME" && "$MY_NAME" == "$TO" ]]; then
  echo "Error: cannot send a message to yourself" >&2
  exit 1
fi

# Guard: content length
if [[ ${#CONTENT} -gt $MAX_CONTENT_LEN ]]; then
  echo "Error: message too long (max ${MAX_CONTENT_LEN} chars, got ${#CONTENT})" >&2
  exit 1
fi

# Guard: inbox size
mkdir -p "$INBOX_DIR"
INBOX="$INBOX_DIR/$TO.jsonl"
if [[ -f "$INBOX" ]]; then
  INBOX_SIZE=$(wc -c < "$INBOX")
  if [[ $INBOX_SIZE -gt $MAX_INBOX_BYTES ]]; then
    echo "Error: $TO's inbox is full (>${MAX_INBOX_BYTES} bytes), message not sent" >&2
    exit 1
  fi
fi

SENT_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
FROM="${MY_NAME:-unknown}"

# Check if target is idle and in zellij — deliver immediately if so
if [[ -f "$REGISTRY" ]]; then
  STATUS=$(jq -r --arg name "$TO" '.[$name].status // "unknown"' "$REGISTRY")
  PANE_ID=$(jq -r --arg name "$TO" '.[$name].paneId // empty' "$REGISTRY")
  TARGET_PID=$(jq -r --arg name "$TO" '.[$name].pid // empty' "$REGISTRY")

  if [[ "$STATUS" == "idle" && -n "$PANE_ID" && -n "$TARGET_PID" ]]; then
    SESSION=$(ps eww -p "$TARGET_PID" 2>/dev/null \
      | grep -o 'ZELLIJ_SESSION_NAME=[^ ]*' | cut -d= -f2 || true)
    ZELLIJ=$(command -v zellij 2>/dev/null \
      || echo "${HOME}/.cargo/bin/zellij")

    if [[ -n "$SESSION" && -x "$ZELLIJ" ]]; then
      "$ZELLIJ" --session "$SESSION" action write-chars \
        --pane-id "$PANE_ID" "[msg from $FROM] $CONTENT" 2>/dev/null && \
      "$ZELLIJ" --session "$SESSION" action send-keys \
        --pane-id "$PANE_ID" "Enter" 2>/dev/null && \
      echo "Delivered directly to $TO (idle)" && exit 0
    fi
  fi
fi

# Fallback: write to inbox
jq -cn --arg from "$FROM" --arg content "$CONTENT" --arg sentAt "$SENT_AT" \
  '{"from":$from,"content":$content,"sentAt":$sentAt}' >> "$INBOX"
echo "Queued in $TO's inbox"
