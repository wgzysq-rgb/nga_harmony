# 04 前端框架

使用 Web Components + ES Modules 构建，零框架依赖。前端 TS 源码通过 esbuild 编译为 JS。

## 前端构建

前端 `.ts` 文件不直接被浏览器加载，而是通过 esbuild 编译输出到 `dist/client/`：

```bash
# 开发模式（watch 自动编译）
esbuild src/client/lib/app.ts --bundle --outdir=dist/client --format=esm --watch --sourcemap

# 生产构建（压缩）
esbuild src/client/lib/app.ts --bundle --outdir=dist/client --format=esm --minify
```

esbuild 的 `--bundle` 会自动处理 import 依赖，将所有前端 TS 模块打包为单个或多个 JS 文件。

## 路由

使用 Hash 路由（`#/path`），无需服务器端配置。

### 路由器

```typescript
// src/client/lib/router.ts

type RouteHandler = (params: Record<string, string>) => void;

interface Route {
  pattern: RegExp;
  handler: RouteHandler;
  paramNames: string[];
}

class Router {
  private routes: Route[] = [];
  private currentCleanup: (() => void) | null = null;

  /** 注册路由 */
  on(path: string, handler: RouteHandler): void {
    const paramNames: string[] = [];
    const pattern = path.replace(/:(\w+)/g, (_, name) => {
      paramNames.push(name);
      return '([^/]+)';
    });
    this.routes.push({ pattern: new RegExp(`^${pattern}$`), handler, paramNames });
  }

  /** 启动路由监听 */
  start(): void {
    window.addEventListener('hashchange', () => this.resolve());
    this.resolve(); // 初始路由
  }

  /** 编程式导航 */
  navigate(path: string): void {
    window.location.hash = path;
  }

  /** 解析当前 hash 并执行匹配路由 */
  private resolve(): void {
    // 清理上一页
    if (this.currentCleanup) {
      this.currentCleanup();
      this.currentCleanup = null;
    }

    const hash = window.location.hash.slice(1) || '/';
    for (const route of this.routes) {
      const match = hash.match(route.pattern);
      if (match) {
        const params: Record<string, string> = {};
        route.paramNames.forEach((name, i) => { params[name] = decodeURIComponent(match[i + 1]); });

        // handler 返回清理函数（可选）
        const result = route.handler(params);
        if (typeof result === 'function') {
          this.currentCleanup = result;
        }
        return;
      }
    }
  }
}

export const router = new Router();
```

### 路由注册

```typescript
// src/client/app.ts
import { router } from './lib/router';
import { renderLoginPage } from './pages/login';
import { renderHomePage } from './pages/home';
import { renderTopicListPage } from './pages/topic-list';
import { renderThreadPage } from './pages/thread';

router.on('/login', renderLoginPage);
router.on('/', renderHomePage);
router.on('/forum/:fid', renderTopicListPage);
router.on('/forum/:fid/stid/:stid', renderTopicListPage);
router.on('/thread/:tid', renderThreadPage);
router.on('/thread/:tid/page/:page', renderThreadPage);
router.on('/thread/:tid/pid/:pid', renderThreadPage);
router.on('/profile/:uid', renderProfilePage);
router.on('/messages', renderMessagePage);
router.on('/notifications', renderNotificationPage);
router.on('/search', renderSearchPage);
router.on('/favorites', () => renderTopicListPage({ favor: '1' }));

router.start();
```

## 状态管理

轻量响应式状态，基于 Proxy。

### Store

```typescript
// src/client/lib/store.ts

type Listener = () => void;

export function createStore<T extends object>(initial: T): {
  state: T;
  subscribe(fn: Listener): () => void;  // 返回 unsubscribe 函数
  notify(): void;                         // 手动触发（用于修改非 Proxy 感知的场景）
} {
  const listeners = new Set<Listener>();

  const proxy = new Proxy(initial, {
    set(target, prop, value) {
      (target as any)[prop] = value;
      listeners.forEach(fn => fn());
      return true;
    }
  });

  return {
    state: proxy,
    subscribe(fn: Listener) {
      listeners.add(fn);
      return () => listeners.delete(fn);
    },
    notify() {
      listeners.forEach(fn => fn());
    }
  };
}
```

### 全局 Store

```typescript
// src/client/lib/app-store.ts
import { createStore } from './store';

export const appStore = createStore({
  // 认证
  token: localStorage.getItem('nga_token') ?? '',
  currentUser: null as { uid: string; nickName: string; avatarUrl: string } | null,

  // UI 状态
  loading: false,
  drawerOpen: false,

  // 缓存
  cachedCategories: null as any[] | null,
  blackList: JSON.parse(localStorage.getItem('nga_blacklist') ?? '[]') as { userId: string; nickName: string }[],
});

// 自动持久化 token
appStore.subscribe(() => {
  if (appStore.state.token) {
    localStorage.setItem('nga_token', appStore.state.token);
  } else {
    localStorage.removeItem('nga_token');
  }
});
```

## Web Component 基类

```typescript
// src/client/lib/component.ts

/**
 * Web Component 基类，提供模板渲染和事件绑定
 */
export abstract class Component extends HTMLElement {
  protected root: ShadowRoot;

  constructor() {
    super();
    this.root = this.attachShadow({ mode: 'open' });
  }

  /** 子类实现：返回 CSS 字符串 */
  protected styles(): string { return ''; }

  /** 子类实现：返回 HTML 字符串 */
  protected render(): string { return ''; }

  /** 刷新 DOM */
  protected update(): void {
    this.root.innerHTML = `<style>${this.styles()}</style>${this.render()}`;
    this.bindEvents();
  }

  /** 子类可覆盖：绑定事件 */
  protected bindEvents(): void {}

  /** 生命周期：元素被插入 DOM */
  connectedCallback(): void {
    this.update();
  }

  /** 辅助：代理事件委托 */
  protected delegate(selector: string, event: string, handler: (el: HTMLElement, e: Event) => void): void {
    this.root.addEventListener(event, (e) => {
      const target = (e.target as Element).closest(selector);
      if (target) handler(target as HTMLElement, e);
    });
  }
}
```

### 组件示例

```typescript
// src/client/components/topic-card.ts
import { Component } from '../lib/component';
import type { ThreadPageInfo } from '../../../shared/types/topic';

export class TopicCard extends Component {
  private topic!: ThreadPageInfo;

  set data(topic: ThreadPageInfo) {
    this.topic = topic;
    this.update();
  }

  protected styles(): string {
    return `
      :host { display: block; }
      .card { padding: 12px 16px; border-bottom: 1px solid #e0e0e0; cursor: pointer; }
      .card:hover { background: #f5f5f5; }
      .subject { font-size: 15px; font-weight: 500; }
      .meta { font-size: 12px; color: #888; margin-top: 4px; }
      .replies { color: #ff6600; }
    `;
  }

  protected render(): string {
    if (!this.topic) return '';
    const t = this.topic;
    return `
      <div class="card">
        <div class="subject">${this.esc(t.subject)}</div>
        <div class="meta">
          ${this.esc(t.author)} · ${this.timeAgo(t.postDate)} ·
          <span class="replies">${t.replies}回复</span>
        </div>
      </div>
    `;
  }

  protected bindEvents(): void {
    this.delegate('.card', 'click', () => {
      window.location.hash = `/thread/${this.topic.tid}`;
    });
  }

  private esc(s: string): string {
    const d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
  }

  private timeAgo(ts: number): string {
    const diff = (Date.now() / 1000 - ts) | 0;
    if (diff < 60) return '刚刚';
    if (diff < 3600) return `${(diff / 60) | 0}分钟前`;
    if (diff < 86400) return `${(diff / 3600) | 0}小时前`;
    return `${(diff / 86400) | 0}天前`;
  }
}

customElements.define('nga-topic-card', TopicCard);
```

### 使用组件

```typescript
// 在页面中使用
const card = document.createElement('nga-topic-card');
card.data = topicInfo;
container.appendChild(card);
```

## 后端 API 调用封装

```typescript
// src/client/lib/api.ts
import { appStore } from './app-store';

const BASE = '/api';

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    ...(options.headers as Record<string, string> ?? {}),
  };

  if (appStore.state.token) {
    headers['Authorization'] = `Bearer ${appStore.state.token}`;
  }

  // 附带黑名单列表供后端过滤
  if (appStore.state.blackList.length > 0) {
    headers['X-Blacklist'] = appStore.state.blackList.map(u => u.userId).join(',');
  }

  const res = await fetch(`${BASE}${path}`, { ...options, headers });

  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: 'Network Error' }));
    throw new Error(err.error ?? `HTTP ${res.status}`);
  }

  return res.json();
}

export const api = {
  get: <T>(path: string) => request<T>(path),

  post: <T>(path: string, body: Record<string, string>) =>
    request<T>(path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    }),
};
```

## 页面渲染模式

每个页面函数接收路由参数，负责：
1. 清空 `<main>` 容器
2. 创建 DOM 结构
3. 调用 API 获取数据
4. 渲染组件
5. 返回清理函数（可选）

```typescript
// src/client/pages/topic-list.ts
export function renderTopicListPage(params: Record<string, string>): () => void {
  const main = document.getElementById('app-main')!;
  const fid = params.fid;
  const page = params.page ?? '1';

  main.innerHTML = `
    <div class="topic-list-page">
      <nga-app-header title="${params.name ?? '板块'}"></nga-app-header>
      <div class="topic-list" id="topic-container">
        <nga-loading></nga-loading>
      </div>
      <nga-pagination></nga-pagination>
    </div>
  `;

  let aborted = false;

  (async () => {
    try {
      const data = await api.get(`/topics?fid=${fid}&page=${page}`);
      if (aborted) return;

      const container = document.getElementById('topic-container')!;
      container.innerHTML = '';

      for (const topic of data.topics) {
        const card = document.createElement('nga-topic-card');
        card.data = topic;
        container.appendChild(card);
      }
    } catch (err) {
      if (!aborted) {
        document.getElementById('topic-container')!.innerHTML =
          `<nga-toast type="error">${err.message}</nga-toast>`;
      }
    }
  })();

  // 清理函数：导航离开时中止请求
  return () => { aborted = true; };
}
```

## HTML 入口

```html
<!-- src/client/index.html -->
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Open NGA</title>
  <link rel="stylesheet" href="/styles/base.css">
  <link rel="stylesheet" href="/styles/components.css">
  <link rel="stylesheet" href="/styles/layouts.css">
</head>
<body>
  <nga-app-drawer></nga-app-drawer>
  <div class="app-container">
    <main id="app-main"></main>
  </div>

  <!-- 加载 esbuild 编译后的 JS bundle -->
  <script type="module" src="/app.js"></script>
</body>
</html>
```

> 注意：开发时 esbuild watch 模式会将 `src/client/lib/app.ts` 及其所有依赖编译输出到 `dist/client/app.js`。
> HTML 中的路径 `/app.js` 由静态文件服务从 `dist/client/` 目录提供。

## CSS 架构

### CSS 变量（主题系统基础）

```css
/* src/client/styles/base.css */
:root {
  /* 颜色 */
  --color-primary: #2196f3;
  --color-primary-dark: #1976d2;
  --color-bg: #ffffff;
  --color-bg-secondary: #f5f5f5;
  --color-text: #333333;
  --color-text-secondary: #888888;
  --color-border: #e0e0e0;
  --color-error: #f44336;
  --color-warning: #ff9800;
  --color-success: #4caf50;

  /* 排版 */
  --font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --font-size-sm: 12px;
  --font-size-base: 14px;
  --font-size-lg: 16px;

  /* 间距 */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;

  /* 暗色主题变量覆盖 */
  --shadow-card: 0 1px 3px rgba(0,0,0,0.12);
}

/* 暗色主题 */
[data-theme="dark"] {
  --color-primary: #64b5f6;
  --color-bg: #1a1a1a;
  --color-bg-secondary: #2a2a2a;
  --color-text: #e0e0e0;
  --color-text-secondary: #999;
  --color-border: #333;
}
```

### 全局重置

```css
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: var(--font-family);
  font-size: var(--font-size-base);
  color: var(--color-text);
  background: var(--color-bg);
}
a { color: var(--color-primary); text-decoration: none; }
a:hover { text-decoration: underline; }
img { max-width: 100%; height: auto; }
```
