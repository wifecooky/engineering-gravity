# 2. 前端工程 (React / antd / Next.js)

> 适用场景: 写 React / antd / Next.js 代码时对照 — 表单陷阱、状态与数据流、样式与 a11y、性能、SSR/构建缓存、埋点。

## 2.1 表单陷阱清单 (antd v5/v6, 写新代码先对照)

- `destroyOnHidden` Modal/Drawer: 打开前 `setFieldsValue` 写进未挂载实例全丢 → 正解 `key={editing?.id ?? 'new'}` + `initialValues=`; 纯新增默认值也搬 initialValues (可引用作用域 state 动态计算) (`b0746c7`)。检测配方: startEdit 里 setFieldsValue + destroyOnHidden + 无 key/initialValues = 坏。
- `Form.useWatch` 默认只通知已注册字段 — 无 Form.Item 的字段要 `{ form, preserve: true }`。
- `form.getFieldsValue()` 不含未注册字段 — 保存时单独 `getFieldValue`。
- 非受控 `defaultValue` Input 不随数据刷新 — 加 `key={value}` 强制重挂载。
- Modal/Drawer 表单分 tab 要 forceRender — 未渲染 tab 的字段不进提交, 静默丢字段 (`786dd67`)。
- Table pagination 用 `defaultPageSize` 不用受控 `pageSize` (会把用户每页条数改回去)。
- showSearch Select 若 value 是数字 id 必须 `optionFilterProp="label"` — 默认按 value 过滤, 输文字全滤空 (`a505791`); filterOption 按当前已选值过滤会"下拉打不开", onSearch 仅键入时过滤 (`ef8239b`)。

## 2.2 状态与数据流

- null vs undefined 双坑: 草稿"清空"必须用 null (JSON.stringify 丢 undefined, 清空不落库); 受控 Select 清空设 null, undefined 让组件转非受控残显旧值 (`d68b5b2`, `8b87cc8`)。
- 防重复提交用 ref 同步守卫 (useSubmitLock), 单靠 loading state 不够 — setState 异步有竞态窗口, 卡顿时双击建两条 (`a7bf1a0`)。
- 草稿 tempID 计数器用 useRef 不用 state — 渲染闭包读旧值, 同帧连点拿相同 id 互相覆盖 (`bd8f907`)。
- 草稿行互引用用负 id 占位, 提交时统一 idMap 换真 id (含新行之间互引); 单条坏草稿降级跳过+告警, throw 且草稿不清 = 每次保存都失败的永久卡死 (`a135643`, `76807a2`)。
- "添加"用本地草稿行, 不先 create 空服务端行 — 取消就留孤儿脏行 (`9abd8bf`)。
- M2M 关联仅用户 touched 才 PUT — 表单初始化期的空值会把库里数据误清空。
- react-query 缓存失效三型缺口全查: invalidate key 与列表 key 失配 (不刷新)、兄弟组件的 key 无人失效 (弹窗看不到新数据)、父级派生计数不连带; 发现一处做全站同型审计 (`d3f8932`, `0056563`); 变更后连带字典/候选缓存 (`db24903`)。
- render 阶段 setState / 把 useState initializer 当副作用用是 React #310 崩溃源, 改 useEffect + ref (B `4b33b46`, `d666e2d`)。
- 时间派生值 (剩余天数等) 不用空依赖 useMemo 缓存 — 页面常开就过期 (B `539681b`)。
- React Compiler 时代手写 useCallback 反而破坏自动 memo ("Existing memoization could not be preserved") — helper 提出组件外做普通函数; set-state-in-effect 类新 lint 的正解是逻辑进 useState 初始化函数 / hydration 判定用 useSyncExternalStore, 不是 suppress (B `d99a31f`, `03bf478`, `cedde84`, `faaca63`)。
- 互斥 props 用 discriminated union 建模, 让非法组合编译期报错 (B `b3b2d80`)。
- 空结果返回用工厂函数, 不共享可变常量 — 共享的 `EMPTY = []` 被一处 push 全站遭殃 (B `d54ebe9`)。
- 字段正规化 (metafield 优先→raw fallback 之类) 收敛到唯一 transform 层 — 逐 query 手抄必漏一处独显原始值; 多别名逐字段取数改批量 identifiers 接口并删除映射数组, 消除二重管理 (B `b400946`, `49fa974`)。

## 2.3 样式与可访问性

- 自定义主题覆盖控件样式必须连全部状态 (:disabled 等) 一起覆盖, 漏一态 = 全站系统性视觉 bug (`a62691f`)。
- `<div onClick>` 是键盘死区 → 抽共用 kbd() helper (role=button + tabIndex + Enter/Space) + `:focus-visible` 焦点环; 有 cursor:pointer+hover 却无 onClick 同样是误导 (`62429c9`)。
- 硬编码色 token 化只换与 token 值精确相等的语义色, 图表系列色/装饰色保留 (`73f1a6a`); CSS 变量名拼错不报错只走 fallback, 纳入 audit (`98f8045`); 内联 hex 是 token 演进时的漂移源 (`2942692`)。
- a11y 系统性修法: axe 走查 + token 同源加深 + 违规计数清零式推进 (`d23d297`)。
- backdrop-filter/transform 会创建隐式 stacking context 令子元素 z-index 静默失效 — 给容器显式 position+z-index; overlay 的 z-index 要压过固定底部导航, 且 overflow:hidden 会盖掉内部 overflow-y:auto (B `0321857`, `d60fe73`)。
- Tailwind Preflight 会把富文本 HTML (CMS/博客 contentHtml) 重置成平文 — 配 prose 样式层, 且 h4-h6 也要覆盖 (粘贴内容常生成 h4) (B `06eedda`, `b498c42`)。
- 跨仓移植 UI 带着源项目的样式类, 目标项目构建时类不存在**不报错只静默裸奔** (白底白字按钮不可见) — 移植必须转译到目标设计体系 (B `6f70fd2`, `d176ff1`)。
- 移动端适配清单: 触屏断点关 hover transform / 触target ≥44px / iOS safe-area / 浮动元素避让底部导航 / 未设断点的 grid 逐个补护 (B `f3290d0`, `9f4cf67`)。
- 响应式只有手机/桌面两档必在平板带 (768–1024) 崩坏 — CJK min-content 撑爆分数列致 aspect-ratio 破绽, 补中间断点; flex/grid 的 min-content 约束链每一层都要 min-height:0 / minmax(0,), 漏一层照样撑破 (B `19c4dda`, `216e1b7`, `6d832b2`)。
- 移动抽屉 a11y 套路: focus-trap + aria-modal + Escape 关闭, 做成共享组件 (B `7e00246`)。

## 2.4 性能

- 性能配方 (React 审查一轮沉淀 `bf4bf0b`): useFormDirty 替代 `Form.useWatch([])` 整表订阅; 重库 (exceljs/html2pdf/jsbarcode) 动态 import 出首屏; react-query 4xx 不重试 (坏链接 7s→120ms); invalidate 按域精确; 密集文本格改 defaultValue+onBlur+key; >100 行开虚拟表格。
- 高频键入别触发全页重渲: 草稿态收在局部, commit 时才上提。
- router 把导航包进 transition 后旧页保持渲染 (v7), 慢网点菜单似死机 — 自建"chunk 在途"信号出骨架; 自建并发通知要处理"后归零者无人等待"死锁 (`2f43c96`)。
- 首屏性能三件套: 取数 Promise.all 并列 + loading.tsx 骨架 + LCP 图 priority+sizes; below-the-fold 用 Suspense 边界切成流式渲染, 首屏阻塞 API 数收敛 (B `aef96df`, `0eab584`, `c4c9e02`)。
- 动态页面的慢速外部 API 解析按可视窗口懒执行: 首屏 N 条 + Server Action 按需 + in-flight 去重 + 解析失败负缓存, 否则成本随数据量线性涨 (B `d61d635`)。

## 2.5 工程纪律

- **自查命令与 build 同严格度**: Vite dev 松、tsc 严, "dev 绿 build 挂"一周绊 4 次 (`526d2a2`); solution-style tsconfig 下 `tsc -p .` 静默检查 0 个文件永远 exit 0 — 校验工具本身要先被校验。
- `as never` 等类型断言压掉的报错是定时炸弹; "本地能跑"可能只是数据巧合 (PK 无默认值本地没炸只因行已存在, 全新库必炸) (`a3b29e3`)。
- 路由注册顺序遮蔽: 通用 `/:id/:action` 把后注册的具体路由吃成 no-op 且无报错, 具体路由先挂 (`d5636fb`)。
- 前后端接口走共享 types 包防 schema drift; create 返回值解构并类型化 — `{id}` 被当 number 拼出 `/detail/[object Object]` (`0334a4c`, `87cc223`)。
- 块注释内容里不能出现 `*/` 字符序列 (JSDoc 写通配模式截断注释) (`ac50106`)。
- 给公共组件加特殊 case 会污染所有既有用例, 形态差异大时宁另立新组件 (B `efae34a`)。
- HTTP 客户端迁移 (axios→fetch) 时超时/重试等隐性配置会丢, 逐项核对 (B `b5affcd`)。
- CLI/批处理脚本与应用共仓时给独立 tsconfig (CommonJS + 相对路径), 跑编译后的 dist, 别蹭应用的 bundler 语义 (B `8d57e54`)。
- i18n 后置引入选 Cookie/请求级 locale 注入, 不动 URL 结构 — 既存路由零破坏; 翻译键放错 namespace 只在另一语言运行时爆 MISSING_MESSAGE, 多语言文件对称性要机器校验 (B `2da7af2`, `2d383bb`, `00fbdb8`)。
- 死掉的 lint pragma 也是债 — 项目已换 ESLint 却残留 biome-ignore, 无效抑制注释随手清 (B `ffb2eda`)。

## 2.6 SSR / 构建与缓存 (Next.js 类框架, 均项目 B)

- 部署后用户浏览器还跑旧 JS: generateBuildId 绑 commit hash + 静态资源 Cache-Control 策略配套 (B `df3f22e`)。
- SSG/ISR 页面构建期上游取到空数据会把空态**永久缓存** — 数据驱动页面显式声明缓存策略 (force-dynamic/revalidate); "首页没事"可能只是它恰好 force-dynamic (B `c42adbd`, `79e8b81`)。
- 外部资源 slug (博客 handle 等) 是环境相关配置, 换环境上游 API 静默返 null 而非报错 (B `fe9baf2`, `13a204a`)。
- 框架用异常做控制流 (Next.js redirect() throw NEXT_REDIRECT): 宽 try/catch 会吞掉跳转, session 过期静默不跳登录 — 认证/redirect 放 try 外, 只 catch 数据调用段, 或识别后 rethrow (B `f0b41f2`, `6de7bc4`)。
- 路径参数含非 ASCII 时框架不一定自动 decode — 日文 handle 原样传 API 查无此物 404, 显式 decodeURIComponent (B `61ce46e`, `9787480`)。
- auth middleware 的 matcher 要排除健检/静态资源, 否则监控探针全被踢去登录 (B `699505e`)。
- 分页游标的排序参数必须 SSR 与客户端一致, 不一致 = cursor 错位、加载更多返回空 (B `86b43a5`)。

## 2.7 埋点与分析 (均项目 B)

- 离页前发事件用 event_callback + event_timeout 兜底, 不用 setTimeout 猜时长; transport beacon 与 event_callback 互斥, 二选一 (B `22026e6`, `11a35f2`)。
- 全量交互自动追踪 = 事件洪水, 配额内挤掉关键业务事件, 后果是整批删除 — 埋点从一开始就白名单化 (B `042092e`)。
- 测试/内部流量用 tester_id 归因链隔离; 关掉自动 page_view 后要手动补发, 否则漏斗断头 (B `42e3f32`, `d7e1ae6`)。
- 埋点 useEffect 依赖数组多挂一个状态 = 事件重复发送 (pageview 依赖 auth 态在登录变化时重发) — 每个事件独立 effect, 只挂真正触发源 (B `5540ac9`)。

