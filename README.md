# Engineering Gravity — 可泛化的工程经验

> These aren't best practices. They're gravity —
> the same failure patterns, independently reproduced in two unrelated codebases.

约 320 条工程经验, 全部来自真实踩坑, 逐条可追溯到 commit。来源是两个技术栈与业务域完全不同的项目, 各自的 commit 历史被**全文逐条阅读**后提炼:

- **项目 A** — 实验室信息管理系统 (LIMS): 210 万行 VB.NET WinForms 桌面系统向 TypeScript 全栈 (React/antd + Hono + PostgreSQL) 的 Web 移植。868 条 commit, 另加 40+ 份工作记忆与设计约定沉淀。
- **项目 B** — 跨境批发电商 storefront 后台 (Next.js / Shopify / Prisma / Playwright)。1322 条 commit。

收录标准: **能脱离原项目泛化**的经验才收, 项目特定业务事实不收。
括号内为 commit 短哈希 — 无前缀为项目 A, `B xxx` 为项目 B (源仓库私有, 哈希仅作溯源锚点)。
整理日期 2026-09-15。

两个互不相关的项目独立踩出同一批坑 — 这不是巧合, 是工程重力。

## 目录

| 章 | 适用场景 |
|---|---|
| [1. UIUX / 交互](lessons/01-uiux.md) | 设计/评审面向用户的界面: 保存反馈、数据诚实性、空态加载、导航、表格、表单、文案 |
| [2. 前端工程](lessons/02-frontend.md) | React/antd/Next.js: 表单陷阱、状态数据流、样式与 a11y、性能、SSR/构建缓存、埋点 |
| [3. 后端与数据](lessons/03-backend-data.md) | 数据建模、引用完整性、写路径、SQL/ORM、ETL/迁移、外部 API 集成 |
| [4. 安全](lessons/04-security.md) | 认证/授权、IDOR、fail-closed、日志 PII、OAuth 登出、部署白名单 |
| [5. 测试](lessons/05-testing.md) | 断言质量、测试数据纪律、flaky 治理、e2e 基建与选择器 |
| [6. 流程 / 协作](lessons/06-process.md) | 移植考古、修复与审计、任务拆解、架构演进、仓库卫生与 CI |
| [7. 元经验](lessons/07-meta.md) | 把教训变成机制的闭环 |

## 作为 Claude Code skill 使用

```bash
ln -s /path/to/engineering-gravity ~/.claude/skills/engineering-gravity
```

之后 agent 在写/评审对应领域的代码时会按需加载相关章节, 触发逻辑见 [SKILL.md](SKILL.md)。
每章开头有一行「适用场景」, 供人和 AI 判断该不该读这一章。
