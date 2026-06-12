# Claude Config Manager（中文）

<p align="right">
  <a href="README.md">English</a>
</p>

<p align="center">
  <img src="docs/logo-icon.svg" width="120" alt="Claude Config Manager">
</p>

<p align="center">
  <b>像包管理器一样管理 Claude Code 的 MCP 服务器。</b><br>
  启用 · 禁用 · 健康检查 · 性能基线 · 一键开关
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <a href="#"><img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-brightgreen.svg"></a>
</p>

---

## 这是什么？

一套轻量级 Claude Code MCP 管理工具。告别手工编辑 `settings.json`——用命令行像包管理器一样管理 MCP。

可独立使用，也可作为 [Claude Code Harness](https://github.com/cqh-xmf/claude-code-harness) 的一部分。

---

## 快速安装

```bash
git clone https://github.com/cqh-xmf/claude-config-manager.git ~/.claude-config-manager
bash ~/.claude-config-manager/scripts/install.sh
```

---

## 命令

### 查看 MCP 列表

```bash
mcp list
```

分组显示所有活跃和可用的 MCP。

### 启用 MCP

```bash
mcp enable fal-ai
mcp enable exa-web-search
```

一条命令，从按需目录复制配置块到 `settings.json`。

### 禁用 MCP

```bash
mcp disable fal-ai
```

从 `settings.json` 移除。核心 MCP 受保护，不会被误删。

### 启用整组

```bash
mcp enable-all search    # 启用 exa, tavily, brave
mcp enable-all media     # 启用 fal-ai, figma
mcp enable-all platform  # 启用 notion, slack, linear, jira, confluence, supabase
```

### 一键关闭所有按需 MCP

```bash
mcp disable-all
```

回到纯核心 8 模式。

### 健康检查

```bash
mcp health
```

显示：活跃 MCP 列表、冷启动耗时、环境变量状态、运行时版本、配置文件状态。

### 保鲜检查 + 自动更新

```bash
mcp freshness    # 检测过期 MCP + 发现新 MCP
mcp update       # 一键自动更新全部（npm + agents + rules）
```

检查 npm 上 MCP 包的最新版本，扫描 GitHub 发现社区新 MCP，验证 agent/rule 是否有上游更新。

### Harness Score 评分

```bash
mcp score
```

7 维度 0-100 评分：MCP 在线率、Token 配置、Agent 就绪、Rules 生效、模板、配方、保鲜度。

### 多工具配方

```bash
mcp recipe list
mcp recipe security-audit
```

预配置工作流：`security-audit`、`pr-review`、`full-deploy`、`doc-sprint`、`new-feature`、`open-source-release`、`ui-sprint`。

---

## 原理

```
                    settings.json                     on-demand-mcps.json
                   ┌──────────────┐                  ┌──────────────────┐
                   │ mcpServers:  │    mcp enable     │ exa-web-search   │
                   │   context7 ✅│◀─────────────────│ tavily            │
                   │   github   ✅│  复制配置块       │ fal-ai           │
                   │   fal-ai   ✅│                  │ figma            │
                   │              │    mcp disable    │ ...              │
                   │   fal-ai   ❌│◀─────────────────│                  │
                   └──────────────┘  移除配置块       └──────────────────┘
```

---

## 环境要求

- **Bash**（macOS/Linux 自带；Windows 用 Git Bash）
- **Python 3**（JSON 处理）
- **Claude Code** v2.1.150+

---

## vs. 手动编辑 JSON

| 任务 | 手动 | Config Manager |
|------|------|---------------|
| 启用一个 MCP | 打开 JSON→找目录→复制→粘贴→重启 | `mcp enable <名字>` |
| 禁用一个 MCP | 打开 JSON→找块→删→小心语法→重启 | `mcp disable <名字>` |
| 看哪些开着 | 滚 JSON，人脑解析 | `mcp list` |
| 检查健康 | 一个个手动测 | `mcp health` |
| 启用全部搜索 | 复制 3 个块 | `mcp enable-all search` |

---

## 许可证

MIT — 随便用、随便改、随便发布。
