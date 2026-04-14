# Current Work

## Goal
Add status machine + inbox queue to oh-my-agent-teams.

## Key paths
- Repo: ~/cc-playground/oh-my-agent-teams
- Local scripts: ~/.agent/scripts/
- Registry: ~/.agent/active-agents.json
- Inbox dir: ~/.agent/inbox/<name>.jsonl

## Tasks
- [x] agent-register.sh: add status: idle
- [ ] agent-status.sh: update status (busy/idle)
- [ ] agent-send.sh: write inbox + guards (content ≤500, file ≤50KB, from≠to)
- [ ] agent-consume-inbox.sh: Stop hook, max 10 msgs, expire >1h, systemMessage inject
- [ ] install.sh: add UserPromptSubmit→busy, Stop→consume+idle hooks
- [ ] agent-messaging skill: document inbox flow
- [ ] sync scripts to ~/.agent/scripts/
- [ ] commit & push

## Guards
- content ≤ 500 chars
- inbox file ≤ 50KB
- from ≠ to
- consume: max 10/turn, expire >1h
