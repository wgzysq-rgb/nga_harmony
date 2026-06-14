# 为什么 NgaApi / BBCodeParser / HtmlThreadParser 拆分时用 barrel re-export 而非直接改调用方 import

## 背景

模块化重构期间多处需要把超大入口文件按职责拆成子模块，但它们的调用方早已散布在全项目，且项目没有单测网兜底。具体场景：

- **P0-5**：`service/NgaApi.ets` 原本 1564 行，按业务域拆成 `service/api/` 下 7 个子文件（`AuthApi` / `UserApi` / `ForumApi` / `ThreadApi` / `FavoriteApi` / `MessageApi` / `MiscApi`）。全项目有 24 个文件直接 `import { fetchThread, verifyToken, ... } from "../service/NgaApi"`。
- **P1-6**：`parser/bbcode/` 的 `tryMatchBlock` 拆成 `lexer.ets` / `inline-parser.ets` / `parser.ets` / `block-handlers/`。
- **P2-1**：`parser/HtmlThreadParser.ets` 原 669 行，拆成 `parser/nga/html-thread/` 下 5 个子模块。

拆分后需要决定如何处理已有调用方的 import 路径。

## 方案对比

| 方案 | 优势 | 劣势 |
|------|------|------|
| barrel re-export（NgaApi.ets 改为 `export * from "./api/XxxApi"` 聚合）✅ | 24 个调用方零改动、可增量迁移子文件、保留单一入口、降低重构风险 | 多一层间接、符号来源不直观 |
| 直接改 24+ 调用方 import 路径指向 `api/XxxApi` | 物理上最直接、无间接层 | 工作量大、易漏改、重构风险高 |
| 留 NgaApi.ets 作函数转发（每函数手写代理） | 与 barrel 等效 | 多一层函数调用开销、维护重复签名 |

## 决策

采用 barrel re-export：`NgaApi.ets`、`parser/bbcode/BBCodeParser.ets`、`parser/HtmlThreadParser.ets` 保留为入口文件，内部用 `export *` 或具名 `export` 聚合拆出的子模块，调用方 import 路径不变。

具体实现：

- `service/NgaApi.ets` 用 `export * from './api/AuthApi'` 等聚合 7 个业务域（见 `NgaApi.ets:17-23`）。
- `parser/bbcode/BBCodeParser.ets` 具名转发 `export { parseBBCode } from './parser'`（见 `BBCodeParser.ets:9`）。
- `parser/HtmlThreadParser.ets` 具名转发 `export { parseHtmlToRawJson } from './nga/html-thread/index'`（见 `HtmlThreadParser.ets:13`）。

## 理由

1. 调用方零改动是降低大型重构风险的关键——24 处 import 手动改极易遗漏，且项目无单测基建，漏改只能靠运行时崩溃暴露。
2. 可增量迁移：子文件可逐个从大文件剪切出去而不破坏调用方，重构可分多个 commit 推进（P0-1 类型迁移、P0-5 函数拆分各自独立推进）。
3. 保留单一入口（`from "../service/NgaApi"`）使模块对外 API 表面稳定，消费方不感知内部拆分。
4. ArkTS 编译无 tree-shaking 性能损失（与 Web 打包不同），barrel 的运行时代价可忽略。
5. 领域数据类的迁移（P0-1）与函数拆分（P0-5）分离：类型从 `model/` 导入、函数仍从 `NgaApi` barrel 导入，职责清晰。

## 代价

- barrel 文件是一层间接，IDE "go to definition" 需多跳一次才到真实实现。
- 新增 API 时需确保只在 `api/` 某一个子文件定义，避免 barrel 聚合时重名冲突（多个 `export *` 聚合时重名符号会在编译期报重复声明）。
- 符号来源不直观：读 `from "../service/NgaApi"` 时不知道 `fetchThread` 来自 `ThreadApi`，需依赖 barrel 注释（`NgaApi.ets:3-11` 已注明各子文件职责）。

## 参见

- [API 通信](../服务层/API通信.md)
- [BBCode 解析与渲染](../服务层/BBCode解析与渲染.md)
- [数据解析器](../解析器模块/数据解析器.md)
- [架构决策 002 NgaClient 双层架构](002-NgaClient双层架构设计.md)
