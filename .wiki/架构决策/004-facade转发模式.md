# 为什么 SettingsStore 拆分用 facade 转发 setter 而非让调用方直接访问 domain 子对象

## 背景

P0-7 把 471 行的 `store/SettingsStore.ets` 按设置域拆分为三部分：

- `store/SettingsStore.ets` 门面，持有持久化根状态 `SettingsState` 与共享上下文 `SettingsContext`
- `store/settings/SettingsState.ets` 持久化根状态类（所有字段集中存放，便于整体序列化）
- `store/settings/domain/` 下 8 个域子 store：`ThemeSettings` / `DisplaySettings` / `MediaSettings` / `ReadingSettings` / `SocialListSettings` / `FilterKeywordSettings` / `NoteSettings` / `CheckinSettings`

拆分前，调用方通过 `appStore.settings.setTheme(x)`、`settingsStore.setVideoMuted(x)` 等门面方法读写设置。拆分后实际逻辑（写 `ctx.state` 字段、同步 `AppStorage`、调用 `ctx.persist()`）落在各 domain 子 store 内。需要决定调用方如何触达拆分后的逻辑。

## 方案对比

| 方案 | 优势 | 劣势 |
|------|------|------|
| facade 转发（门面持 `readonly` 各 domain，setter 转发 `this.themeSettings.setTheme(x)`）✅ | 调用方零改动、门面单一入口便于编排 `init` / `reset` / `persistSettings` | 门面方法是薄转发层、调试调用栈多一跳 |
| 调用方改 `settingsStore.themeSettings.setTheme(x)` 直接访问 domain | 无转发层、路径直达 | 暴露内部 domain 布局、调用方耦合实现细节、domain 增减波及调用方 |
| 用 `Record<DomainKey, DomainStore>` 动态分发 | 配置驱动、增减 domain 不改门面 | ArkTS 不允许索引签名调度，不可行 |

## 决策

采用 facade 转发：`SettingsStore` 门面持有 8 个 domain 的 `readonly` 字段，每个对外 setter 转发到对应 domain 子 store 的方法，调用方 API 表面不变。

门面在构造时为 8 个 domain 注入同一个共享 `SettingsContext`（`SettingsStore.ets:52-62`），各 domain 通过 `ctx.state` 读写共享根状态、通过 `ctx.persist()` 触发统一持久化。对外 setter 全部为单行转发（`SettingsStore.ets:121-174`），跨域生命周期则由门面编排：`init` 依次注入依赖并按需 `loadUserSettings`（`SettingsStore.ets:64-74`）、`reset` 统一清空根状态并调用需重置的 domain（`SettingsStore.ets:77-83`）、`loadUserSettings` 串行调用 8 个 domain 的 `load` 分片（`SettingsStore.ets:99-116`）、`persistSettings` 统一序列化整个 `SettingsState`（`SettingsStore.ets:91-97`）。

## 理由

1. 调用方零改动降低重构风险，与 barrel re-export（ADR 003）同一思路。门面在 `SettingsStore.ets:23-25` 还把 `SettingsState` / `FavBoard` / `BlacklistEntry` 等 re-export，调用方维持 `from './SettingsStore'` 不变，所有 `pages/` 的设置读写无需修改。
2. ArkTS 约束下每个 domain 必须是门面的显式 `readonly` 字段——不支持映射类型 `Record<DomainKey, DomainStore>`、不允许索引签名调度、不支持条件类型/infer，无法用「按 key 动态分发」的方式驱动门面。facade 转发是该约束下的自然形态，8 个 domain 各自一行字段声明（`SettingsStore.ets:43-50`）。
3. 门面单一入口便于编排跨域操作：`init` 顺序注入 store/queue/auth/context 并按 `auth.uid` 触发加载、`reset` 统一重建 `SettingsState` 并重置有副作用的 domain、`loadUserSettings` 串行调用 8 个 domain 的 `load` 再统一回填 4 个 AppStorage key、`persistSettings` 走 `SerialQueue` 整体序列化 `SettingsState`。这些跨域编排若分散到调用方各自调用 domain，会丢失一致性与时序保证。
4. 保留 `SettingsStore` 作为稳定 API 表面，domain 内部重组（如 `ThemeSettings` 再拆、或 `MediaSettings` 字段迁移）不波及调用方。domain 间通过 `SettingsContext` 共享根状态与持久化回调，domain 实现可独立演进。
5. 与 `AppStore` 顶层 Facade 模式一致（`AppStore` 委托各子 store），`SettingsStore` 内部复用同一模式，架构层级统一，降低认知成本。

## 代价

- 门面方法是薄转发层，每个 setter 重复签名（`setTheme` / `setVideoMuted` / `setTtsPerson` / ...），视觉上冗余，50+ 个转发方法占满 `SettingsStore.ets:121-174`。
- 调试时调用栈多一跳（门面转发 → domain 实现），定位实际逻辑需进入 domain 文件。
- domain 增减需同步修改门面：加 `readonly` 字段、构造注入、`loadUserSettings` 中补 `load` 调用、按需补转发 setter，不能完全配置驱动。

## 参见

- [Store 架构](../状态管理层/Store架构.md)
- [架构决策 001 单一 Module 与 @Observed](001-单一Module与@Observed状态管理.md)
- [架构决策 003 barrel re-export](003-barrel-re-export模式.md)（相似思想）
