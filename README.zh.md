# oh-my-agent-teams

[English](./README.md) · [中文](./README.zh.md)

多 Agent 协作的共享注册表。自动追踪 claude-code 和 opencode 中运行的 AI Agent，让 Agent 之间能够互相发现和通信。

## 工作原理

每个 Agent session 启动时会自动注册到 `~/.agent/active-agents.json`，包含随机生成的代号、工作目录和当前任务摘要。任何 Agent 都可以查询这个注册表，找到其他 Agent 并向其发送消息。

## 安装

```bash
git clone https://github.com/yearth/oh-my-agent-teams.git
cd oh-my-agent-teams
bash install.sh
```

安装完成后重启 claude-code / opencode 即可生效。

## 和 Agent 对话

安装完成后，直接用自然语言和 Agent 说就好，Agent 会自己查注册表、找到目标并发送消息。

**问谁在线：**
> "现在有哪些活跃的 Agent？"

**让 Agent 给另一个 Agent 发消息：**
> "给 swift-fox 发一条消息：API 接口定义好了，你可以开始写客户端了。"

**让 Agent 确认自己的身份：**
> "你的 Agent 代号是什么？"

## 支持的工具

| 工具 | 自动注册 |
|------|---------|
| claude-code | ✓ 通过 SessionStart/SessionEnd hooks |
| opencode | ✓ 通过 session.created/deleted 插件事件 |

## 依赖

- `jq`
- zellij >= 0.44.1（Agent 间消息发送）
