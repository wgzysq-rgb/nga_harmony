# 01 后端服务

## HTTP 服务器

使用 Node.js 原生 `http` 模块，不引入 Express/Koa 等框架，保持零依赖。

### 核心职责

```
请求进入
  │
  ├─ /api/*     → 路由分发 → 业务处理 → 返回 JSON
  ├─ /static/*  → 静态文件服务（HTML/CSS/JS/图片）
  └─ /          → 返回 index.html（SPA 入口）
```

### 服务器骨架

```typescript
// src/server/index.ts
import { createServer, IncomingMessage, ServerResponse } from 'node:http';
import { router } from './router';

const PORT = 3050;

createServer(async (req, res) => {
  try {
    await router(req, res);
  } catch (err) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Internal Server Error' }));
  }
}).listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
```

## 路由设计

### 路由器

```typescript
// src/server/router.ts
import { IncomingMessage, ServerResponse } from 'node:http';
import { serveStatic } from './middleware/static';
import { corsMiddleware } from './middleware/cors';

type RouteHandler = (req: IncomingMessage, res: ServerResponse, params: Record<string, string>) => Promise<void>;
type Route = { method: string; pattern: RegExp; handler: RouteHandler; paramNames: string[] };

const routes: Route[] = [];

function addRoute(method: string, path: string, handler: RouteHandler) {
  const paramNames: string[] = [];
  const pattern = path.replace(/:(\w+)/g, (_, name) => {
    paramNames.push(name);
    return '([^/]+)';
  });
  routes.push({ method, pattern: new RegExp(`^${pattern}$`), handler, paramNames });
}

export async function router(req: IncomingMessage, res: ServerResponse) {
  // CORS（OPTIONS 预检直接返回）
  if (corsMiddleware(req, res)) return;

  const url = new URL(req.url!, `http://localhost`);
  const path = url.pathname;
  const method = req.method!;

  // API 路由
  if (path.startsWith('/api/')) {
    for (const route of routes) {
      if (route.method !== method) continue;
      const match = path.match(route.pattern);
      if (match) {
        const params: Record<string, string> = {};
        route.paramNames.forEach((name, i) => { params[name] = match[i + 1]; });
        return route.handler(req, res, params);
      }
    }
    res.writeHead(404, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ error: 'Not Found' }));
  }

  // 静态文件 & SPA fallback
  return serveStatic(req, res);
}

// 路由注册 DSL
export { addRoute as GET };
export function POST(path: string, handler: RouteHandler) { addRoute('POST', path, handler); }
// 按需扩展 PUT, DELETE...
```

### 路由注册示例

```typescript
// src/server/api/topic.ts
import { GET } from '../router';
import { ngaClient } from '../nga-client';
import { parseTopicList } from '../../shared/parsers/topic';

GET('/api/topics', async (req, res, params) => {
  const url = new URL(req.url!, 'http://localhost');
  const fid = url.searchParams.get('fid');
  const page = url.searchParams.get('page') || '1';

  const raw = await ngaClient.get('/thread.php', {
    fid, page, lite: 'js', noprefix: ''
  });

  const data = parseTopicList(raw);
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
});
```

## 中间件

中间件采用 `next()` 链式调用模式：

```typescript
// src/server/middleware/types.ts
import { IncomingMessage, ServerResponse } from 'node:http';

export type Middleware = (
  req: IncomingMessage,
  res: ServerResponse,
  next: () => void
) => void;
```

### CORS 中间件

```typescript
// src/server/middleware/cors.ts
import { IncomingMessage, ServerResponse } from 'node:http';

/**
 * 设置 CORS 头，处理 OPTIONS 预检。
 * 返回 true 表示已处理（应中断后续逻辑）。
 */
export function corsMiddleware(req: IncomingMessage, res: ServerResponse): boolean {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return true;
  }
  return false;
}
```
```

### 认证中间件

```typescript
// src/server/middleware/auth.ts
import { IncomingMessage, ServerResponse } from 'node:http';
import { sessionStore } from '../session-store';

/**
 * 从请求中提取 session token，查找对应的 NGA Cookie。
 * 写入 req.ngaCookies 供后续 API 调用使用。
 */
export function authMiddleware(req: IncomingMessage): { uid: string; cid: string } | null {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return null;

  const session = sessionStore.get(token);
  if (!session) return null;

  return { uid: session.uid, cid: session.cid };
}
```

## NGA HTTP 客户端（核心）

这是后端最关键的模块，封装与 NGA 服务器的所有通信。

### 核心职责

1. 构建正确的请求 URL 和参数
2. 注入认证 Cookie
3. POST 请求的 GBK 编码
4. 响应的 GBK 解码
5. `lite=js` 响应去前缀
6. 统一错误处理

### 设计

```typescript
// src/server/nga-client.ts
import { request as httpsRequest } from 'node:https';
import { request as httpRequest } from 'node:http';
import { URL, URLSearchParams } from 'node:url';
import { TextEncoder, TextDecoder } from 'node:util';
import iconv from 'iconv-lite'; // 唯一外部依赖，处理 GBK

// GBK 编解码需要 iconv-lite
// npm install iconv-lite && npm install -D @types/iconv-lite

type HttpMethod = 'GET' | 'POST';

interface NgaRequestOptions {
  method?: HttpMethod;
  params?: Record<string, string | number | undefined>;
  body?: Record<string, string>;
  cookies?: { uid: string; cid: string };
  encodeBodyAsGbk?: boolean;  // POST body 是否用 GBK 编码
  isMultipart?: boolean;      // multipart/form-data
  extraHeaders?: Record<string, string>; // 额外请求头（如 Referer）
}

class NgaClient {
  private domains = [
    'https://bbs.nga.cn',
    'https://bbs.ngacn.cc',
    'https://nga.178.com',
  ];
  private activeDomainIndex = 0;

  private get activeDomain(): string {
    return this.domains[this.activeDomainIndex];
  }

  /**
   * 切换到下一个域名（当前域名不可达时调用）
   */
  rotateDomain(): void {
    this.activeDomainIndex = (this.activeDomainIndex + 1) % this.domains.length;
  }

  /**
   * 设置首选域名（来自用户配置）
   */
  setDomain(domain: string): void {
    const idx = this.domains.indexOf(domain);
    if (idx !== -1) {
      this.activeDomainIndex = idx;
    }
  }

  /**
   * 发起 NGA API 请求
   */
  async request(path: string, options: NgaRequestOptions = {}): Promise<any> {
    const {
      method = 'GET',
      params = {},
      body,
      cookies,
      encodeBodyAsGbk = false,
      baseUrl,
      isMultipart = false,
    } = options;

    const url = new URL(path, baseUrl ?? this.activeDomain);

    // 拼接 query params（过滤掉 undefined 值）
    Object.entries(params).forEach(([key, val]) => {
      if (val !== undefined && val !== '') {
        url.searchParams.set(key, String(val));
      }
    });

    // 构建请求头
    const headers: Record<string, string> = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'X-User-Agent': 'Nga_Official',
    };

    if (options.extraHeaders) {
      Object.assign(headers, options.extraHeaders);
    }

    if (cookies) {
      headers['Cookie'] = `ngaPassportUid=${cookies.uid}; ngaPassportCid=${cookies.cid}`;
    }

    // 构建请求 body
    let requestBody: Buffer | undefined;
    if (body) {
      if (isMultipart) {
        // multipart/form-data 构建
        const { buffer, contentType } = this.buildMultipart(body);
        headers['Content-Type'] = contentType;
        requestBody = buffer;
      } else {
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
        if (encodeBodyAsGbk) {
          // GBK 编码
          const encoded = new URLSearchParams();
          for (const [key, val] of Object.entries(body)) {
            encoded.set(key, val);
          }
          requestBody = iconv.encode(encoded.toString(), 'gbk');
          headers['Accept-Charset'] = 'GBK';
        } else {
          requestBody = Buffer.from(new URLSearchParams(body).toString());
        }
      }
      headers['Content-Length'] = String(requestBody.length);
    }

    // 发起 HTTP 请求
    const responseBuffer = await this.httpRequest(url, method, headers, requestBody);

    // 解码响应
    let text = iconv.decode(responseBuffer, 'gbk');

    // === JSON 预处理管道 ===

    // Step 1: 去除 lite=js 响应的 JS 包装
    text = text.replace('window.script_muti_get_var_store=', '');

    // Step 2: 去除 JS 注释标记
    text = text.replace(/\/\*\$js\$\*\//g, '');

    // Step 3: 清理错误标记
    text = text.replace(/\/\*error fill content\*\//g, '');

    // Step 4: 修复非标准 JSON —— 数字开头的字符串值未加引号
    text = text.replace(/"content":\+(\d+),/g, '"content":"+$1",');
    text = text.replace(/"subject":\+(\d+),/g, '"subject":"+$1",');
    text = text.replace(/"content":(0\d+),/g, '"content":"$1",');
    text = text.replace(/"subject":(0\d+),/g, '"subject":"$1",');
    text = text.replace(/"author":(0\d+),/g, '"author":"$1",');

    // Step 5: 转义 JSON 字符串值内的控制字符（tab/换行等）
    // NGA remark/content 字段包含制表符(\t)等控制字符，导致 JSON.parse 失败
    // 需逐字符扫描，在引号内将控制字符转义
    let inString = false;
    let escaped = false;
    let result = '';
    for (let i = 0; i < text.length; i++) {
      const ch = text[i];
      const code = text.charCodeAt(i);
      if (escaped) { result += ch; escaped = false; continue; }
      if (ch === '\\') { result += ch; escaped = true; continue; }
      if (ch === '"') { inString = !inString; result += ch; continue; }
      if (inString && code < 0x20) {
        if (code === 0x09) result += '\\t';
        else if (code === 0x0a) result += '\\n';
        else if (code === 0x0d) result += '\\r';
        else result += '\\u' + code.toString(16).padStart(4, '0');
        continue;
      }
      result += ch;
    }
    text = result;

    // 解析 JSON
    try {
      return JSON.parse(text);
    } catch {
      // 部分 API 返回非 JSON（如登录接口返回 HTML）
      return { rawText: text };
    }
  }

  private async httpRequest(
    url: URL, method: string, headers: Record<string, string>, body?: Buffer
  ): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const isHttps = url.protocol === 'https:';
      const requester = isHttps ? httpsRequest : httpRequest;

      const req = requester(url, { method, headers }, (res) => {
        const chunks: Buffer[] = [];
        res.on('data', (chunk) => chunks.push(chunk));
        res.on('end', () => resolve(Buffer.concat(chunks)));
        res.on('error', reject);
      });

      req.on('error', reject);
      if (body) req.write(body);
      req.end();
    });
  }

  private buildMultipart(fields: Record<string, string>): { buffer: Buffer; contentType: string } {
    const boundary = `----FormBoundary${Math.random().toString(36).slice(2)}`;
    const parts: Buffer[] = [];

    for (const [key, value] of Object.entries(fields)) {
      parts.push(Buffer.from(
        `--${boundary}\r\nContent-Disposition: form-data; name="${key}"\r\n\r\n${value}\r\n`
      ));
    }
    parts.push(Buffer.from(`--${boundary}--\r\n`));

    return {
      buffer: Buffer.concat(parts),
      contentType: `multipart/form-data; boundary=${boundary}`,
    };
  }

  // --- 便捷方法 ---

  get(path: string, params: Record<string, string | number | undefined>, cookies?: { uid: string; cid: string }) {
    return this.request(path, { method: 'GET', params, cookies });
  }

  post(path: string, body: Record<string, string>, cookies: { uid: string; cid: string }, gbk = true) {
    return this.request(path, { method: 'POST', body, cookies, encodeBodyAsGbk: gbk });
  }

  /**
   * 带 Referer 的请求（用户资料页需要）
   */
  getWithReferer(path: string, params: Record<string, string | number | undefined>, referer: string, cookies?: { uid: string; cid: string }) {
    return this.request(path, {
      method: 'GET', params, cookies,
      extraHeaders: { Referer: referer },
    });
  }
}

export const ngaClient = new NgaClient();
```

### 外部依赖

| 包 | 用途 | 必要性 |
|---|---|---|
| `iconv-lite` | GBK 编解码 | **必须**（Node.js 原生不支持 GBK） |
| `tsx` | 开发时直接运行 TS | 开发依赖 |
| `esbuild` | 前端 TS→JS 编译 | 开发依赖 |

后端运行时仅一个外部依赖（`iconv-lite`），其余全部使用 Node.js 内置模块。

## 会话存储

```typescript
// src/server/session-store.ts
import { randomBytes } from 'node:crypto';

interface Session {
  uid: string;
  cid: string;
  nickName: string;
  avatarUrl: string;
  createdAt: number;
}

class SessionStore {
  private sessions = new Map<string, Session>();

  /**
   * 登录成功后创建会话，返回 token 供前端存储
   */
  create(uid: string, cid: string, nickName: string, avatarUrl: string): string {
    const token = randomBytes(32).toString('hex');
    this.sessions.set(token, { uid, cid, nickName, avatarUrl, createdAt: Date.now() });
    return token;
  }

  get(token: string): Session | null {
    return this.sessions.get(token) ?? null;
  }

  destroy(token: string): void {
    this.sessions.delete(token);
  }

  /** 清理过期会话（可定时调用） */
  cleanup(maxAge = 7 * 24 * 3600 * 1000): void {
    const now = Date.now();
    for (const [token, session] of this.sessions) {
      if (now - session.createdAt > maxAge) {
        this.sessions.delete(token);
      }
    }
  }
}

export const sessionStore = new SessionStore();
```

### 多账号支持

前端可存储多个 token（localStorage），切换时更换 `Authorization` 头即可。后端 `SessionStore` 以 Map 维护所有活跃会话。

### 持久化方案（可选扩展）

当前使用内存 Map，重启后丢失。如需持久化：
- 将 session 写入 JSON 文件（`data/sessions.json`）
- 或使用 SQLite（`better-sqlite3`）

登录频率低，内存存储在单用户场景下完全够用。

## 静态文件服务

```typescript
// src/server/middleware/static.ts
import { IncomingMessage, ServerResponse } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { join, extname } from 'node:path';

const STATIC_DIR = join(import.meta.dirname, '../../../dist/client');

const MIME_TYPES: Record<string, string> = {
  '.html': 'text/html; charset=utf-8',
  '.css':  'text/css; charset=utf-8',
  '.js':   'text/javascript; charset=utf-8',
  '.json': 'application/json',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.svg':  'image/svg+xml',
  '.ico':  'image/x-icon',
};

export async function serveStatic(req: IncomingMessage, res: ServerResponse) {
  const url = new URL(req.url!, 'http://localhost');
  let filePath = join(STATIC_DIR, url.pathname === '/' ? 'index.html' : url.pathname);

  try {
    const fileStat = await stat(filePath);
    if (fileStat.isDirectory()) {
      filePath = join(filePath, 'index.html');
    }
    const content = await readFile(filePath);
    const mime = MIME_TYPES[extname(filePath)] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': mime });
    res.end(content);
  } catch {
    // SPA fallback: 所有未匹配路径返回 index.html
    const indexContent = await readFile(join(STATIC_DIR, 'index.html'));
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(indexContent);
  }
}
```
