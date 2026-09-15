---
name: engineering-gravity
description: Use when writing or reviewing code in any of these domains — user-facing UI (forms, tables, saving, empty/loading states, navigation), React/antd/Next.js frontend engineering, backend data modeling and write paths, external API integration, auth/security-sensitive changes, tests and e2e infrastructure, or porting/migration/audit/process work. A checklist of ~320 hard-won failure patterns mined from 2190 commits across two unrelated production codebases; load only the domain file relevant to the current task.
---

# Engineering Gravity

约 320 条从真实 commit 历史挖出的可泛化踩坑经验。**不要整库读入** — 按当前任务领域只读对应文件:

| 任务领域 | 读这个 |
|---|---|
| 面向用户的界面 (保存/反馈、空态/加载、表格、表单、导航、文案) | `lessons/01-uiux.md` |
| React / antd / Next.js 工程 (表单陷阱、状态、样式、性能、SSR/缓存、埋点) | `lessons/02-frontend.md` |
| 数据建模、写路径、SQL/ORM、ETL/迁移、外部 API 集成 | `lessons/03-backend-data.md` |
| 认证/授权/敏感数据改动 | `lessons/04-security.md` |
| 写测试、flaky 治理、测试数据、e2e 基建 | `lessons/05-testing.md` |
| 移植/考古、修 bug/审计、任务拆解、架构演进、仓库卫生 | `lessons/06-process.md` |
| 复盘/固化机制 | `lessons/07-meta.md` |

## 用法

1. 动手前: 打开对应领域文件, 浏览小节标题, 命中的小节整节读, 作为设计/实现的前置检查单。
2. review 时: 对照相关小节逐条核, 命中的条目在 review 意见里引用原条目。
3. 跨多个领域的任务 (如全栈功能) 读多个文件, 但仍按小节裁剪, 不整吞。
4. 修 bug 时优先查同域条目 — 大概率这个坑已经有名字了; 修完记得按第 7 章的闭环把新教训固化。
5. 改动收尾时跑 `checks/gravity-audit.sh <目标repo>` — 机器能守的条目自动扫, 命中要么改对要么行内加 `gravity-ok: 理由`。

条目末尾括号内是来源 commit 短哈希 (无前缀 = 项目 A, `B xxx` = 项目 B), 仅作溯源锚点, 源仓库私有。
