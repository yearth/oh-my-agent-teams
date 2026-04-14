# oh-my-agent-teams

[English](./README.md) · [中文](./README.zh.md)

多 Agent 协作的共享注册表。自动追踪 claude-code 和 opencode 中运行的 AI Agent，让 Agent 之间能够互相发现和通信。

## 工作原理

每个 Agent session 启动时会自动将自己注册到 `~/.agent/active-agents.json`，包含代号、Pane ID、工作目录和当前任务摘要。任何 Agent 都可以查询这个注册表，找到其他 Agent 并向其发送消息。

## 安装

```bash
git clone https://github.com/yearth/oh-my-agent-teams.git
cd oh-my-agent-teams
bash install.sh
```

安装完成后重启 claude-code / opencode 即可生效。

## 使用

**查看当前活跃的 Agent：**
```bash
~/.agent/scripts/agent-list.sh
```

**向另一个 Agent 发送消息（需要 zellij）：**
```bash
PANE=$(jq -r '.["swift-fox"].paneId' ~/.agent/active-agents.json)
SESSION=$(ps eww -p $(jq -r '.["swift-fox"].pid' ~/.agent/active-agents.json) 2>/dev/null \
  | grep -o 'ZELLIJ_SESSION_NAME=[^ ]*' | cut -d= -f2)
zellij --session "$SESSION" action write-chars --pane-id "$PANE" "你的消息"
zellij --session "$SESSION" action send-keys  --pane-id "$PANE" "Enter"
```

**更新自己的任务摘要：**
```bash
MY_NAME="${AGENT_NAME:-$(cat ~/.agent/identity-$PPID 2>/dev/null)}"
~/.agent/scripts/agent-update.sh "$MY_NAME" "正在实现认证模块"
```

## 注册表格式

```json
{
  "swift-fox": {
    "paneId": 2,
    "pid": 36838,
    "role": "dev",
    "cwd": "/path/to/project",
    "summary": "正在实现认证模块",
    "startedAt": "2026-04-14T10:00:00Z",
    "tool": "claude-code"
  }
}
```

## 支持的工具

| 工具 | 注册方式 | 身份识别 |
|------|---------|---------|
| claude-code | SessionStart/SessionEnd hooks | `~/.agent/identity-$PPID` |
| opencode | `session.created/deleted` 插件事件 | `$AGENT_NAME` 环境变量 |

## 依赖

- `jq`
- zellij >= 0.44.1（Agent 间消息发送）
