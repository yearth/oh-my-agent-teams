#!/usr/bin/env bash
# Consume inbox messages on Stop hook.
# Reads up to 10 messages, discards those older than 1 hour,
# outputs systemMessage JSON if any messages remain, then clears inbox.
# Also updates agent status to idle.

set -euo pipefail

REGISTRY="$HOME/.agent/active-agents.json"
INBOX_DIR="$HOME/.agent/inbox"
MAX_MESSAGES=10
EXPIRE_SECONDS=3600  # 1 hour

MY_NAME="${AGENT_NAME:-}"
if [[ -z "$MY_NAME" ]]; then
  MY_NAME="$(cat "$HOME/.agent/identity-$PPID" 2>/dev/null || true)"
fi

# Update status to idle
if [[ -n "$MY_NAME" && -f "$REGISTRY" ]]; then
  jq --arg name "$MY_NAME" \
    'if has($name) then .[$name].status = "idle" else . end' \
    "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
fi

# Check inbox
if [[ -z "$MY_NAME" ]]; then
  exit 0
fi

INBOX="$INBOX_DIR/$MY_NAME.jsonl"
if [[ ! -s "$INBOX" ]]; then
  exit 0
fi

NOW=$(date -u +%s)
MESSAGES=""
COUNT=0

while IFS= read -r line && [[ $COUNT -lt $MAX_MESSAGES ]]; do
  SENT_AT=$(echo "$line" | jq -r '.sentAt // empty' 2>/dev/null)
  if [[ -z "$SENT_AT" ]]; then continue; fi

  MSG_TS=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$SENT_AT" +%s 2>/dev/null || \
           date -u -d "$SENT_AT" +%s 2>/dev/null || echo 0)
  AGE=$(( NOW - MSG_TS ))
  if [[ $AGE -gt $EXPIRE_SECONDS ]]; then continue; fi

  FROM=$(echo "$line" | jq -r '.from // "unknown"' 2>/dev/null)
  CONTENT=$(echo "$line" | jq -r '.content // ""' 2>/dev/null | tr -d '\n\r')
  MESSAGES="${MESSAGES}[${FROM}]: ${CONTENT}"$'\n'
  COUNT=$(( COUNT + 1 ))
done < "$INBOX"

# Clear inbox (consumed or expired)
rm -f "$INBOX"

if [[ $COUNT -eq 0 ]]; then
  exit 0
fi

# Inject messages into claude context via systemMessage and wake claude up (exit 2)
# Use jq to build valid JSON — avoids literal newlines breaking the JSON string
MSG_TEXT="You have ${COUNT} inbox message(s):"$'\n'"${MESSAGES}"
jq -n --arg msg "$MSG_TEXT" '{"systemMessage": $msg}'
exit 2
