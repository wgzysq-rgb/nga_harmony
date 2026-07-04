<div align="center">
  <img src="AppScope/resources/base/media/startIcon.png" alt="NGA OH Logo" width="120" height="120">
  <h1>NGA OH</h1>
  <p><strong>NGA 玩家社区 · 鸿蒙原生客户端</strong></p>
  <p>
    <img src="https://img.shields.io/badge/HarmonyOS-6.1.0(23)-0078D7?style=flat-square">
    <img src="https://img.shields.io/badge/ArkUI-%F0%9F%93%B1-ff69b4?style=flat-square">
    <img src="https://img.shields.io/badge/API-23-brightgreen?style=flat-square">
    <img src="https://img.shields.io/badge/license-GPL--2.0-blue?style=flat-square">
  </p>
</div>

---

> ## ⚠️ 安装须知
>
> **HarmonyOS 不能直接安装 .hap 文件包**。你需要使用签名工具对 HAP 进行签名后才能安装到手机上。
>
> 推荐使用 **小白调试助手（Auto-Installer）**：
> - 📖 [使用教程视频（B站）](https://www.bilibili.com/video/BV1K6daBrENN)
> - ⬇️ [下载地址（GitHub Releases）](https://github.com/likuai2010/auto-installer/releases/tag/3.1.0)
>
> 该工具支持 Windows / macOS / Linux，可自动完成签名并安装，无需 DevEco Studio。
>
> 从本仓库 Releases 下载的 HAP 均为**未签名包**，请使用上述工具自行签名后安装。

---

## 简介

**NGA OH** 是基于 **HarmonyOS** 原生框架 **ArkUI (ArkTS)** 构建的 [NGA 玩家社区](https://nga.cn) 客户端。致力于在鸿蒙生态中提供流畅、原生的 NGA 论坛浏览与交互体验。

项目完整覆盖了 NGA 论坛的核心功能：板块浏览、帖子阅读、发帖回复、私信聊天、通知推送、AI 内容总结等，并针对手机、平板、二合一设备做了自适应布局适配。

---

## 功能特性

### 论坛浏览
- **板块列表** — 网格视图展示全部分区，支持收藏排序
- **帖子列表** — 分页加载，支持筛选（精华/收藏/作者）
- **帖子详情** — 楼层分页浏览，引用折叠，图片查看，热门回复
- **BBCode 渲染** — 完整解析 NGA 论坛 BBCode（引用、图片、表情、格式、表格、骰子、列表等）
- **HTML 降级解析** — JSON API 不可用时自动切换 HTML 解析
- **表情显示** — 内置 6 套 NGA 表情包（a2/ac/dt/ng/pg/pst）

### 用户系统
- **登录认证** — RSA 加密密码登录、Web 端登录，验证码支持
- **凭证导入/导出** — 支持从文件导入导出 NGA 登录凭证
- **用户主页** — 声望、勋章、管理版块、发帖统计
- **用户卡片** — 悬停/点击查看用户信息

### 互动功能
- **发帖/回复** — BBCode 快捷工具栏，引用回复，附件上传，编辑回复
- **私信系统** — 会话列表，消息详情
- **通知中心** — 回复提醒、点赞通知、系统消息
- **投票** — 投票记录缓存
- **分享** — 帖子/主题分享

### 内容管理
- **收藏管理** — 收藏主题/版块
- **黑名单** — 用户黑名单管理
- **关键词过滤** — 自定义屏蔽关键词
- **用户备注** — 为用户添加备注标签
- **浏览历史** — 本地持久化浏览记录
- **签名控制** — 帖子中签名展开/折叠切换

### 界面与体验
- **自适应布局** — 手机/平板/二合一设备三档自适应（sm/md/lg breakpoints）
- **深色模式** — 支持浅色/深色/跟随系统主题切换
- **举手持/单手模式** — 基于运动传感器的一手操作优化
- **图片查看器** — 全屏手势缩放浏览
- **音频/视频播放** — 内置音视频播放与自适应检测
- **WebView** — 内嵌网页浏览
- **图片加载控制** — 可选择隐藏加载失败的图片

### AI 功能
- **通用 AI 对话** — ChatGPT 式流式聊天界面，支持多轮对话与中断
- **帖子内容分析** — 一键将帖子内容送入 AI 对话，自动注入上下文
- **用户行为分析** — 将用户发帖数据送入 AI 对话，分析时段分布、版块偏好
- **多服务商支持** — 内置 DeepSeek、智谱 GLM、豆包、MiniMax、Kimi、OpenAI 6 个预设 + 自定义服务商
- **AI 配置管理** — 创建/编辑/删除配置、测试连接、获取模型列表
- **场景化提示词定制** — 为帖子总结、用户分析等场景自定义 system prompt
- **流式 Markdown 渲染** — AI 输出的 Markdown 增量实时渲染

### 其他高级功能
- **全局搜索** — 帖子/主题搜索
- **自动签到** — 每日自动完成论坛签到
- **域名切换** — NGA 多域名自动切换与故障转移
- **请求限流** — 按域名的请求频率控制
- **语音朗读** — 基于 Core Speech Kit 的帖子内容语音播报，超长文本自动分段接力播放

---

## 架构

```
	entry/src/main/ets/
	├── entryability/              # 应用入口 UIAbility
	├── entrybackupability/        # 备份恢复扩展能力
	├── common/                    # 公共 UI 组件与工具
	│   ├── BBCodeContentView      # BBCode 内容渲染组件
	│   ├── MdContentView          # Markdown 渲染组件
	│   ├── MdStreamingContentView  # 流式 Markdown 渲染（增量追加）
	│   ├── PostItem               # 帖子楼层组件
	│   ├── EmotionResources       # 表情资源管理（6 套 NGA 表情包）
	│   ├── ProfileCardPopup       # 用户卡片弹出层
	│   ├── ReplyManager           # 回复管理（引用/编辑/新回复）
	│   ├── ReplyDialog            # 回复编辑器弹窗（BBCode 工具栏+表情+匿名）
	│   ├── ImageViewer            # 图片查看器（全屏手势缩放）
	│   ├── AudioPlayer            # 音频播放器
	│   ├── MutedVideo             # 静音视频播放组件
	│   ├── TtsPlayer              # 语音朗读（TTS 引擎管理）
	│   ├── PanelNavBar            # Panel 内嵌导航栏
	│   ├── FloatingLayerComponent # 浮层管理器（图片/用户卡片/回复/确认弹窗）
	│   ├── PageStateView          # 页面状态视图（加载/错误/空）
	│   ├── LazyDataSource         # 懒加载数据源合集
	│   ├── Dialogs                # 通用弹窗（确认/备注/黑名单/关键词）
	│   ├── Constants              # 颜色/主题/字体/域名/断点常量
	│   ├── ShareUtils             # 分享工具
	│   ├── SettingRow             # 设置行组件
	│   └── ...                    # Avatar, NavBar, Toast, Utils 等
	├── model/                     # 数据模型与类型定义
	│   ├── Forum                  # 版块模型
	│   ├── Topic                  # 主题模型
	│   ├── Thread                 # 帖子详情模型
	│   ├── Post                   # 楼层/内容模型
	│   ├── User                   # 用户模型
	│   ├── Notification           # 通知模型
	│   ├── Message                # 私信模型
	│   ├── BBCodeNode             # BBCode 解析节点类型
	│   ├── AiConfig               # AI 服务商配置模型
	│   └── AiScenarioConfig       # AI 场景配置与 system prompt 模型
	├── pages/                     # 页面组件
	│   ├── Index                  # 启动/加载页
	│   ├── LoginPage              # 登录页（密码+Web+凭证导入）
	│   ├── MainPage               # 主页面（自适应三栏布局）
	│   ├── ThreadPanel            # 帖子详情
	│   ├── TopicListPanel         # 主题列表
	│   ├── ProfilePanel           # 用户主页
	│   ├── SearchPanel            # 搜索
	│   ├── SettingsPanel          # 设置
	│   ├── MessageListPanel       # 私信列表
	│   ├── MessageDetailPanel     # 私信详情
	│   ├── NotificationPanel      # 通知中心
	│   ├── WebViewPanel           # 内嵌网页
	│   ├── BlacklistPanel         # 黑名单管理
	│   ├── NotesPanel             # 用户备注管理
	│   ├── FilterKeywordsPanel    # 关键词屏蔽管理
	│   ├── BrowseHistoryPanel     # 浏览历史
	│   ├── TtsSettingsPanel       # 语音朗读设置
	│   ├── CommunityPanel         # 社区版块列表
	│   ├── ActivityRouter         # 活动列路由
	│   ├── BoardRouter            # 板块列路由
	│   └── ai/                    # AI 功能页面
	│       ├── AiChatPage         # 通用 AI 对话页（流式聊天）
	│       └── AiSettingsPanel    # AI 配置管理面板
	├── parser/                    # NGA API 响应解析器
	│   ├── ForumParser            # 版块列表解析
	│   ├── TopicParser            # 主题列表解析
	│   ├── ThreadParser           # 帖子内容 JSON 解析
	│   ├── HtmlThreadParser       # HTML 帖子降级解析
	│   ├── NotificationParser     # 通知解析
	│   ├── MessageParser          # 私信解析
	│   ├── AnonymousParser        # 匿名用户解析
	│   ├── ClientParser           # 客户端信息解析
	│   ├── NgaJsonSanitizer       # JSON 预处理（非法字符清理）
	│   ├── ErrorParser            # NGA API 错误解析
	│   ├── bbcode/                # BBCode 词法分析 & 块处理器（10 个 handler）
	│   ├── md/                    # Markdown 解析器
	│   ├── nga/html-thread/       # HTML 帖子详细解析
	│   ├── task/                  # taskpool 解析任务
	│   └── _shared/               # 共享工具（AttachUrl、HTML 实体编解码）
	├── service/                   # 业务逻辑层
	│   ├── NgaClient              # HTTP 客户端（GB18030、RSA、域名故障转移、限流）
	│   ├── NgaApi                 # API 业务封装入口（转发至各子模块）
	│   ├── BBCodeParser           # BBCode 解析器
	│   ├── BBCodeCache            # 解析缓存（LRU）
	│   ├── ContentParser          # BBCode→HTML 转换
	│   ├── SessionStore           # 会话管理
	│   ├── Throttle               # 请求频率控制
	│   ├── api/                   # 细分 API 子模块
	│   │   ├── AuthApi            # 登录认证 API
	│   │   ├── UserApi            # 用户资料 API
	│   │   ├── ForumApi           # 版块/主题 API
	│   │   ├── ThreadApi          # 帖子/回复/附件 API
	│   │   ├── FavoriteApi        # 收藏/投票/签到 API
	│   │   ├── MessageApi         # 通知/私信 API
	│   │   └── MiscApi            # 域名切换等杂项 API
	│   └── ai/                    # AI 服务层
	│       ├── ActiveAiService    # AI 门面（获取配置、发起对话）
	│       ├── OpenAiCompatibleClient # OpenAI 兼容 API 客户端
	│       ├── AiModelPresets     # 7 个 AI 服务商预设
	│       └── AiErrorTranslator  # 错误码→中文提示翻译
	└── store/                     # 状态管理层
	    ├── AppStore               # 全局应用状态 Facade（编排所有子 Store）
	    ├── RouterStore            # 导航路由状态（双列路由）
	    ├── AuthStore              # 认证状态（多会话管理）
	    ├── SettingsStore          # 用户设置门面（编排 9 个设置域子 Store）
	    ├── CategoryStore          # 版块分类缓存
	    ├── ProfileStore           # 用户资料缓存
	    ├── NotificationStore      # 通知状态（未读数、缓存）
	    ├── VoteStore              # 投票记录持久化
	    ├── HistoryStore           # 浏览历史持久化
	    ├── FloatingLayerStore     # 弹窗/浮层管理
	    ├── BaseStore              # Store 抽象基类（生命周期、uidGuard）
	    └── settings/              # 设置域子 Store
	        ├── SettingsState      # 持久化根状态（23 个字段）
	        ├── SettingsContext    # 设置域共享上下文
	        └── domain/
	            ├── ThemeSettings / DisplaySettings / MediaSettings
	            ├── ReadingSettings / SocialListSettings
	            ├── FilterKeywordSettings / NoteSettings
	            ├── CheckinSettings / AiSettings
```

### 分层设计

| 层 | 职责 |
|---|---|
| **Pages** | 页面编排、布局、页面级状态 |
| **Store** | 全局状态管理（响应式 `@State` / `@Observed`） |
| **Service** | API 调用、数据转换、BBCode 解析、缓存 |
| **Parser** | NGA API 响应数据反序列化 |
| **Model** | 类型定义、数据实体 |
| **Common** | 可复用 UI 组件 |

---

## 技术栈

| 类别 | 技术 |
|---|---|
| **操作系统** | HarmonyOS 6.1.0 (API 23) |
| **UI 框架** | ArkUI（声明式 UI，`@Component` / `@State` / `@Entry` / `@Observed`） |
| **语言** | ArkTS（基于 TypeScript 的鸿蒙原生语言） |
| **构建工具** | Hvigor + DevEco Studio |
| **应用模型** | Stage Model |
| **网络** | `@kit.NetworkKit`（http） |
| **加密** | `@kit.CryptoArchitectureKit`（RSA） |
| **并发** | `@kit.ArkTS`（taskpool） |
| **语音** | `@kit.CoreSpeechKit`（textToSpeech） |
| **测试** | `@ohos/hypium` + `@ohos/hamock` |

---

## 快速开始

### 环境要求

- [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) 5.0+
- HarmonyOS SDK 6.1.0 (API 23)
- Node.js 20+

### 构建运行

```bash
# 克隆仓库
git clone https://github.com/<your-username>/nga_oh.git

# 使用 DevEco Studio 打开项目根目录

# 构建 debug HAP
hvigorw assembleHap --mode debug

# 构建 release HAP
hvigorw assembleHap --mode release

# 运行 ohosTest
hvigorw run ohosTest
```

> 也可直接在 DevEco Studio 中点击 `Run` 按钮部署到真机或模拟器。

### 权限说明

应用需要以下权限：

- `ohos.permission.INTERNET` — 网络访问，用于 NGA API 通信
- `ohos.permission.DETECT_GESTURE` — 手势检测，用于图片查看器等交互

入口文件：`entry/src/main/module.json5:15:22`

---

## 预览

**手机竖屏 (1008×2232)**

<img src="img/Screenshot_2026-05-31T204948.png" alt="手机截图 1" width="200">
<br>&nbsp;<br>
<img src="img/Screenshot_2026-05-31T205112.png" alt="手机截图 2" width="200">
<br>&nbsp;<br>
<img src="img/Screenshot_2026-05-31T205148.png" alt="手机截图 3" width="200">

**平板竖屏 (2048×2232)**

<img src="img/Screenshot_2026-05-31T205017.png" alt="平板竖屏截图 1" width="260">
<br>&nbsp;<br>
<img src="img/Screenshot_2026-05-31T205030.png" alt="平板竖屏截图 2" width="260">

**平板横屏 (3184×2232)**

<img src="img/Screenshot_2026-05-31T205043.png" alt="平板横屏截图 1" width="360">
<br>&nbsp;<br>
<img src="img/Screenshot_2026-05-31T205051.png" alt="平板横屏截图 2" width="360">

---

## 开发指南

### 编码规范

本项目遵循 HarmonyOS ArkTS 严格语法约束，详细信息参见 [AGENTS.md](AGENTS.md)，主要包括：

- 不支持 `any` / `unknown` 类型
- 不支持解构赋值
- 不支持 `for..in` 遍历对象
- 不支持索引签名，使用数组替代
- 不支持 `Function.apply` / `call` / `bind`
- 不支持 `in` 运算符，使用 `instanceof` 替代

### 动画规范

- 优先使用声明式 UI 与 `@State` 驱动动画
- 复杂子组件设置 `renderGroup(true)` 减少渲染批次
- 避免在动画中改变 `width` / `height` / `padding` / `margin` 等布局属性

---

## 致谢

- [NGA 玩家社区](https://nga.cn) — 国内领先的游戏综合讨论社区
- [Justwen/NGA-CLIENT-VER-OPEN-SOURCE](https://github.com/Justwen/NGA-CLIENT-VER-OPEN-SOURCE) — Android 端开源参考实现

---

## 许可证

GNU General Public License v2.0 — 详见 [LICENSE](LICENSE)

---

<p align="center">
  用 ❤️ 和 ArkUI 构建 · 鸿蒙原生体验
</p>
