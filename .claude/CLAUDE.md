# 项目规则 — NGA OH (HarmonyOS ArkUI)

NGA 论坛客户端，stage 模型，API 6.1.0(23)，单 entry 模块。

## 构建命令

- 构建: `hvigorw assemble --mode module`
- 运行: `hvigorw run`
- 清理: `hvigorw clean`

## 项目结构

`entry/src/main/ets/` 目录组织：

| 目录 | 文件数 | 职责 |
|------|--------|------|
| `pages/` | 24 | 页面级组件 |
| `common/` | 30 | 可复用 UI 组件、工具类、常量 |
| `store/` | 8 | 全局状态管理 |
| `service/` | 9 | 网络请求、外部服务调用 |
| `model/` | 11 | 数据模型定义 |
| `parser/` | 10 | BBCode 等富文本解析 |
| `entryability/` | 1 | 应用生命周期入口 |
| `entrybackupability/` | 1 | 备份恢复能力 |

## 规则索引

ArkTS 语法编译约束 @.claude/rules/ArkTS-syntax.md
HarmonyOS API 及动画规范 @.claude/rules/HarmonyOS-development.md
