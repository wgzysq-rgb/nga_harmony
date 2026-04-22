# 架构总览

## 技术栈

| 层 | 技术 | 说明 |
|---|---|---|
| 运行时 | Node.js 20+ | 后端代理服务器 |
| 语言 | TypeScript 5+ | 全栈统一语言 |
| 后端运行 | tsx（开发）/ tsc（构建） | 零配置开发体验 |
| 前端编译 | esbuild（开发 watch + 构建） | TS→JS 编译，零配置，毫秒级 |
| 前端 UI | Vanilla HTML/CSS/JS | Web Components + ES Modules（编译产物） |
| 包管理 | npm | - |

## 架构图

```
浏览器                                    Node.js 服务器                         NGA 服务器
┌──────────────────────┐              ┌──────────────────────┐              ┌──────────┐
│  HTML (Web Components)│─── Fetch ──→│  /api/* 路由层        │── HTTP ───→│  PHP API  │
│  (编译后的 JS)        │              │  ├─ CORS 中间件      │              │  (GBK)    │
│                      │              │  ├─ 认证中间件        │              │          │
│  ┌────────────────┐  │              │  ├─ GBK 编码转换      │              │          │
│  │ 路由 (hash)    │  │              │  └─ Cookie 注入       │              │          │
│  │ 状态管理       │  │              │                      │              │          │
│  │ 组件系统       │  │              │  JSON 预处理管道      │              │          │
│  └────────────────┘  │              │  ├─ 去JS包装/注释     │              │          │
│                      │              │  ├─ 修复非标准JSON    │              │          │
│  esbuild 编译输出     │              │  └─ 匿名用户名解码    │              │          │
│  (src/client → dist) │              │                      │              │          │
│                      │              │  /static 静态文件服务  │              │          │
└──────────────────────┘              └──────────────────────┘              └──────────┘
```

## 核心设计决策

### 1. 为什么需要 Node.js 后端代理

NGA API 存在以下问题，浏览器直接调用不可行：
- **CORS 限制**：NGA 服务器未设置 `Access-Control-Allow-Origin`
- **GBK 编码**：POST 请求 body 和部分响应使用 GBK 编码
- **Cookie 管理**：需要统一注入 `ngaPassportUid`/`ngaPassportCid`
- **响应格式差异**：`lite=js` 需要去前缀，`__output=8` 直接 JSON

后端代理作为中间层，对前端暴露干净的 JSON API。

### 2. 为什么用 Vanilla JS 而非框架

- 依赖最少，无需构建工具链
- Web Components 是浏览器原生标准，兼容性好
- 论坛客户端以内容展示为主，不需要复杂的状态管理
- 适合学习理解和长期维护

### 3. 前端 TS 编译方案

前端使用 TS 开发，通过 esbuild 编译为 JS 供浏览器加载。esbuild 选用理由：
- 零配置，开箱即用
- 编译速度极快（毫秒级），适合 watch 模式开发
- 仅做 TS→JS 转译和打包，不引入框架级抽象
- 开发时 `esbuild --watch` 自动编译，生产时一次性输出

```
src/client/**/*.ts  ──esbuild──→  dist/client/**/*.js
                                   ↓
                            浏览器 <script type="module"> 加载
```

### 4. 前后端通信

前端通过 `fetch()` 调用后端 API，所有接口统一前缀 `/api/`：

```
GET  /api/auth/captcha          → 获取验证码
POST /api/auth/login            → 登录
GET  /api/forum/categories      → 板块分类
GET  /api/topics?fid=7&page=1   → 主题列表
GET  /api/thread?tid=123&page=1 → 帖子详情
POST /api/post/reply             → 回复帖子
...
```

后端负责将请求转换为 NGA 原始 API 格式，并处理编码和认证。

## 项目目录结构

```
open-nga-web/
├── package.json
├── tsconfig.json
├── tsconfig.client.json          # 前端 TS 编译配置
├── src/
│   ├── server/                    # 后端
│   │   ├── index.ts               # 入口，启动 HTTP 服务器
│   │   ├── router.ts              # 路由分发
│   │   ├── middleware/
│   │   │   ├── auth.ts            # 认证中间件（Cookie 注入）
│   │   │   ├── cors.ts            # CORS 头
│   │   │   ├── encoding.ts        # 请求/响应编码转换
│   │   │   └── static.ts          # 静态文件服务
│   │   ├── api/
│   │   │   ├── auth.ts            # 登录/验证码
│   │   │   ├── forum.ts           # 板块相关
│   │   │   ├── topic.ts           # 主题列表
│   │   │   ├── thread.ts          # 帖子详情
│   │   │   ├── post.ts            # 发帖/回复/编辑
│   │   │   ├── message.ts         # 私信
│   │   │   ├── user.ts            # 用户资料
│   │   │   ├── notification.ts    # 通知
│   │   │   └── misc.ts            # 签到/收藏/点赞等
│   │   ├── nga-client.ts          # NGA HTTP 客户端（核心）
│   │   └── session-store.ts       # 会话存储（管理多账号 Cookie）
│   │
│   ├── client/                    # 前端（TS 源码，esbuild 编译到 dist/）
│   │   ├── index.html             # 入口 HTML
│   │   ├── styles/
│   │   │   ├── base.css           # CSS 变量、重置、排版
│   │   │   ├── components.css     # 组件样式
│   │   │   └── layouts.css        # 布局样式
│   │   ├── lib/
│   │   │   ├── router.ts          # Hash 路由器
│   │   │   ├── store.ts           # 响应式状态管理
│   │   │   ├── api.ts             # 后端 API 调用封装
│   │   │   ├── cache.ts           # 前端数据缓存
│   │   │   └── component.ts       # Web Component 基类
│   │   ├── components/
│   │   │   ├── app-header.ts      # 顶部导航
│   │   │   ├── app-drawer.ts      # 侧边栏（板块列表）
│   │   │   ├── topic-card.ts      # 主题卡片
│   │   │   ├── post-floor.ts      # 楼层组件
│   │   │   ├── user-avatar.ts     # 用户头像
│   │   │   ├── pagination.ts      # 分页器
│   │   │   ├── loading.ts         # 加载状态
│   │   │   ├── toast.ts           # 提示消息
│   │   │   ├── editor.ts          # 富文本编辑器
│   │   │   ├── lightbox.ts        # 图片全屏查看
│   │   │   └── tab-bar.ts         # 标签切换栏
│   │   └── pages/
│   │       ├── login.ts           # 登录页
│   │       ├── home.ts            # 首页/板块列表
│   │       ├── topic-list.ts      # 主题列表页
│   │       ├── thread.ts          # 帖子详情页
│   │       ├── message.ts         # 私信页
│   │       ├── notification.ts    # 通知页
│   │       ├── profile.ts         # 用户资料页
│   │       ├── search.ts          # 搜索页
│   │       └── settings.ts        # 设置页（域名切换等）
│   │
│   └── shared/                    # 前后端共用
│       ├── types/                 # 类型定义
│       ├── parsers/               # 响应解析器
│       └── content-parser.ts      # BBCode/HTML 内容解析器
│
├── dist/                          # 编译输出
│   ├── server/                    # 后端编译产物（tsc）
│   └── client/                    # 前端编译产物（esbuild）
│       ├── index.html
│       ├── styles/
│       └── *.js                   # 编译后的 JS（ES Modules）
│
└── data/                          # 运行时数据
    └── sessions.json              # 会话持久化（可选）
```

## 构建与开发

```bash
# 开发（后端 tsx 直接运行 TS，前端 esbuild watch 自动编译）
npm run dev

# 构建（后端 tsc 编译，前端 esbuild 打包）
npm run build

# 生产运行
npm start
```

后端使用 `tsx` 运行 TypeScript，无需预编译。前端 TS 源码通过 esbuild 编译为 JS 输出到 `dist/client/`，浏览器加载编译后的 ES Modules。

### package.json 关键脚本

```json
{
  "scripts": {
    "dev": "concurrently \"tsx watch src/server/index.ts\" \"esbuild src/client/lib/app.ts --bundle --outdir=dist/client --format=esm --watch --sourcemap\"",
    "build:server": "tsc -p tsconfig.json",
    "build:client": "esbuild src/client/lib/app.ts --bundle --outdir=dist/client --format=esm --minify",
    "build": "npm run build:server && npm run build:client",
    "start": "node dist/server/index.js"
  },
  "devDependencies": {
    "esbuild": "^0.20",
    "tsx": "^4",
    "typescript": "^5",
    "concurrently": "^8",
    "@types/node": "^20"
  },
  "dependencies": {
    "iconv-lite": "^0.6"
  }
}
```

## 文档索引

| 文件 | 内容 |
|------|------|
| [01-server.md](01-server.md) | 后端：HTTP 服务器、路由、中间件、NGA 客户端 |
| [02-data-layer.md](02-data-layer.md) | 数据层：类型定义、响应解析、会话存储 |
| [03-content-parser.md](03-content-parser.md) | 内容解析：NGA BBCode/HTML 转 HTML |
| [04-ui-framework.md](04-ui-framework.md) | 前端框架：Web Components、路由、状态管理 |
| [05-api-mapping.md](05-api-mapping.md) | API 映射：后端接口设计及与 NGA API 的对应关系 |
| [06-pages.md](06-pages.md) | 页面模块：各页面组件结构与交互 |
