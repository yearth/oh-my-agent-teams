#!/usr/bin/env bash
# Consume inbox messages on Stop hook.
# Reads up to 10 messages, discards those older than 1 hour,
# outputs systemMessage JSON if any messages remain, then clears inbox.
# Also updates agent status to idle.

set -euo pipefail

INBOX_DIR="$HOME/.agent/inbox"
MAX_MESSAGES=10
EXPIRE_SECONDS=3600  # 1 hour
# shellcheck source=agent-common.sh
source "$(dirname "$0")/agent-common.sh"

resolve_my_name
[[ -n "$MY_NAME" ]] && update_status "$MY_NAME" idle

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

while IFS=$'\t' read -r SENT_AT FROM CONTENT && [[ $COUNT -lt $MAX_MESSAGES ]]; do
  [[ -z "$SENT_AT" ]] && continue

  MSG_TS=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$SENT_AT" +%s 2>/dev/null || \
           date -u -d "$SENT_AT" +%s 2>/dev/null || echo 0)
  AGE=$(( NOW - MSG_TS ))
  [[ $AGE -gt $EXPIRE_SECONDS ]] && continue

  MESSAGES="${MESSAGES}[${FROM}]: ${CONTENT}"$'\n'
  COUNT=$(( COUNT + 1 ))
done < <(jq -r '.sentAt // "" + "\t" + (.from // "unknown") + "\t" + (.content // "" | gsub("\n";"") | gsub("\r";""))' "$INBOX" 2>/dev/null)

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
