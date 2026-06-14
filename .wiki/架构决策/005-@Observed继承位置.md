# 为什么 @Observed 装饰在最终子类而非抽象基类

## 背景

P1-3 提取了 `common/managers/PaginationManager` 抽象基类，统一 `ThreadPaginationManager`（帖子详情分页）与 `TopicPaginationManager`（主题列表分页）的共性逻辑：

- `generation` 计数器：异步翻页/预取时推进版本号，响应到达后比对以丢弃过期结果（`PaginationManager.ets:32-43`）
- `prefetchedPages` 预取缓存 Map：暂存待 commit 的预取页（`PaginationManager.ets:24`、`80-112`）
- `currentPage / totalPages / hasMore` 三元状态：翻页进度，由 `applyState` 统一收口（`PaginationManager.ets:17-22`、`51-55`）

两个子类都被页面组件 `@State` 绑定（`ThreadPanel`、`TopicListPanel`），需要 ArkUI 响应式观察字段变化。提取基类后，必须决定 `@Observed` 装饰器加在哪一层。

## 方案对比

| 方案 | 优势 | 劣势 |
|------|------|------|
| `@Observed` 在最终子类（Thread/TopicPaginationManager），基类 `abstract class` 不加 ✅ | ArkUI 状态观测按具体类注册、子类实例正确被观察 | 每个子类重复加 `@Observed` |
| `@Observed` 在抽象基类 PaginationManager | 一处声明、DRY | ArkUI 按具体类注册观察，基类装饰对子类实例无效，UI 不响应 |
| 不用继承，复制粘贴共性逻辑 | 无装饰器位置问题 | 违背 DRY、维护负担 |

## 决策

在最终子类 `ThreadPaginationManager`（`ThreadPaginationManager.ets:11`）与 `TopicPaginationManager`（`TopicPaginationManager.ets:10`）上装饰 `@Observed`，基类 `PaginationManager` 用 `abstract class` 声明（`PaginationManager.ets:16`）且不加 `@Observed`。基类源码注释中亦已固化此约束（`PaginationManager.ets:13-14`）。

## 理由

1. ArkUI 的 `@Observed` / `@State` 响应式机制基于具体类注册——运行时对实例按其构造类注册可观察属性。装饰在 `abstract` 基类上，对运行时实际创建的子类实例无效（查阅华为官方文档，`@Observed` 标注的类才是被注册的可观察类）。因此 `@Observed` 必须落在真正被实例化、被 `@State` 绑定的具体类上。
2. 基类是 `abstract class` 不能被 `new` 实例化，本身不会被任何组件直接 `@State` 绑定，既无需加也加了无效。
3. 共性行为（`generation` / `prefetchedPages` / `applyState` / `clearPrefetchedPages`）上提到基类不影响子类的可观察性——ArkUI 的观察性只看最终实例化的类。子类实例持有的继承字段同样会被观测。
4. 该决策是通用规则，同样适用于项目内其他 `@Observed` 继承层级（例如 `store/` 域子 store 若未来引入状态基类，也应在最终子类装饰 `@Observed`）。

## 代价

- 每个最终子类要重复加 `@Observed` 装饰器（视觉冗余，但必要）。
- 新增分页子类时若忘记加 `@Observed`，ArkTS 编译器不报错，但运行时 UI 静默不响应——需在 code review 时重点检查。
- 基类若未来需要被直接实例化（去掉 `abstract`），需同步补 `@Observed`。
- 阅读者可能误以为基类"漏加"装饰器，需依赖基类注释（`PaginationManager.ets:13-14`）说明意图。

## 参见

- [架构决策 001 单一 Module 与 @Observed 状态管理](001-单一Module与@Observed状态管理.md)
- [Store 架构](../状态管理层/Store架构.md)
- [主题列表与帖子详情](../页面模块/主题列表与帖子详情.md)
