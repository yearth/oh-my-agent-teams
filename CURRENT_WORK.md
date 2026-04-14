# Current Work

## Goal
Add status machine + inbox queue to oh-my-agent-teams.

## Key paths
- Repo: ~/cc-playground/oh-my-agent-teams
- Local scripts: ~/.agent/scripts/
- Registry: ~/.agent/active-agents.json
- Inbox dir: ~/.agent/inbox/<name>.jsonl

## Tasks — all done ✓

## Guards
- content ≤ 500 chars
- inbox file ≤ 50KB
- from ≠ to
- consume: max 10/turn, expire >1h
