# 02 数据层

## 类型定义

所有类型集中放在 `src/shared/types/` 目录，前后端共用。

### 文件组织

```
src/shared/types/
├── user.ts           # User, ProfileData
├── forum.ts          # Category, Board, SubBoard
├── topic.ts          # ThreadPageInfo, TopicRaw
├── thread.ts         # ThreadData, ThreadRowInfo, Attachment
├── message.ts        # MessageListInfo, MessageArticle
├── notification.ts   # NotificationInfo, RecentReplyInfo
├── post.ts           # TopicPostBean (发帖信息)
└── api.ts            # 通用响应结构
```

### 通用 API 响应类型

```typescript
// src/shared/types/api.ts

/** NGA 原始响应外层（lite=js 和 __output=8 共用） */
export interface NgaRawResponse<T = any> {
  data: T;
  encode: string;
  time: number;
}

/** 通用 data 内嵌字段 */
export interface NgaCommonFields {
  __CU?: CurrentUser;
  __GLOBAL?: string;
  __F?: ForumInfo;
  __ROWS?: number;
}

export interface CurrentUser {
  uid: number;
  group_bit: number;
  admincheck: string;
  rvrc: number;
}

export interface ForumInfo {
  topped_topic?: string;
  sub_forums?: string;
  fid?: number;
  name?: string;
}

/** 统一后的前端响应格式 */
export interface ApiResponse<T = any> {
  ok: boolean;
  data?: T;
  error?: string;
}
```

### 设计要点

1. **区分 Raw 和 Clean 类型**：`TopicRaw` 是 NGA API 原始字段命名（snake_case），`ThreadPageInfo` 是清洗后的业务类型（camelCase）
2. **前后端共用**：放在 `src/shared/` 目录下，TypeScript path alias 或相对路径引用
3. **严格类型**：所有 API 响应都经过类型断言，避免运行时错误
4. **匿名用户名解码**：NGA 匿名用户 `#anony_XXXXXXXX` 需要解码为中文用户名
5. **from_client 字段**：标识发帖来源客户端（iOS/Android/Web 等）

### 匿名用户名解码

NGA 匿名用户名格式为 `#anony_` + 十六进制编码，需通过字符查找表解码：

```typescript
// src/shared/parsers/anonymouse.ts

const T1 = '在此大声对你那不认识的某种默认昵称致以诚挚的问候你个';
const T2 = '说不喜欢还是算了因为这就是一个用来匿名发言的功能不要问为什么';

/**
 * 解码匿名用户名
 * 例: #anony_0a1b → 说声不
 */
export function decodeAnonymousName(encoded: string): string {
  if (!encoded.startsWith('#anony_')) return encoded;
  const hex = encoded.slice(7);
  let result = '';
  for (let i = 0; i < hex.length; i += 2) {
    const byte = parseInt(hex.substr(i, 2), 16);
    const t1idx = byte >> 4;
    const t2idx = byte & 0x0f;
    if (t1idx < T1.length) result += T1[t1idx];
    if (t2idx < T2.length) result += T2[t2idx];
  }
  return result || '匿名';
}
```

所有解析器在处理 `author` 字段时应调用此函数。

### from_client 客户端标识

```typescript
// src/shared/parsers/client.ts

const CLIENT_MAP: Record<string, string> = {
  '1': 'iOS', '7': 'iOS', '101': 'iOS',
  '103': 'Windows Phone', '9': 'Windows Phone',
  '8': 'Android', '100': 'Android',
};

export function parseFromClient(code: string | number | undefined): string {
  if (!code) return '';
  const key = String(code).trim();
  return CLIENT_MAP[key] ?? '';
}
```

帖子楼层数据中包含 `from_client` 字段，需在解析器中转换并保留到前端展示。

## 响应解析器

每个 API 模块对应一个解析器，负责将 NGA 原始格式转换为统一业务类型。

### 解析器模式

```typescript
// src/shared/parsers/topic.ts
import type { NgaRawResponse, NgaCommonFields } from '../types/api';
import type { ThreadPageInfo, TopicListInfo } from '../types/topic';

export function parseTopicList(raw: NgaRawResponse<NgaCommonFields & {
  __T: Record<string, any>;
  __T__ROWS: number;
  __T__ROWS_PAGE: number;
  __R__ROWS_PAGE: number;
}>): TopicListInfo {
  const topics: ThreadPageInfo[] = [];

  // __T 是 key 为序号的 Map
  const tMap = raw.data.__T;
  for (const key of Object.keys(tMap)) {
    const t = tMap[key];
    topics.push(mapTopicRaw(t));
  }

  return {
    name: raw.data.__F?.name ?? '',
    threadPageList: topics,
    subBoardList: [],  // 从 __F.sub_forums 解析
    curTime: raw.time,
  };
}

function mapTopicRaw(raw: any): ThreadPageInfo {
  return {
    tid: raw.tid,
    fid: raw.fid,
    author: raw.author,
    authorId: Number(raw.authorid),  // 注意：API 返回 string
    lastPoster: raw.lastposter,
    replies: raw.replies,
    subject: raw.subject,
    titleFont: raw.titlefont,
    type: raw.type,
    postDate: raw.postdate,
  };
}

/**
 * 分页计算
 *
 * 主题列表：__T__ROWS = 总行数，__T__ROWS_PAGE = 每页主题数（通常 35）
 * 帖子详情：__R__ROWS_PAGE = 每页回复数（通常 20）
 */
export function calcPagination(totalRows: number, rowsPerPage: number, currentPage: number) {
  return {
    page: currentPage,
    totalPages: Math.ceil(totalRows / rowsPerPage),
    totalRows,
  };
}
```

### 解析器清单

| 解析器 | 文件 | 职责 |
|--------|------|------|
| `parseTopicList` | `parsers/topic.ts` | 主题列表：遍历 `__T` Map，映射字段 |
| `parseThreadData` | `parsers/thread.ts` | 帖子详情：解析 rowList，处理附件、评论嵌套 |
| `parseMessageList` | `parsers/message.ts` | 私信列表 |
| `parseMessageDetail` | `parsers/message.ts` | 私信详情 |
| `parseNotification` | `parsers/notification.ts` | 通知：区分回复通知/AT 通知/私信通知 |
| `parseForumCategories` | `parsers/forum.ts` | 板块分类树 |
| `parsePostAuth` | `parsers/post.ts` | 发帖 auth 码提取 |
| `parseError` | `parsers/error.ts` | 统一错误提取（`error.0` / `error_code`） |
| `decodeAnonymousName` | `parsers/anonymouse.ts` | 匿名用户名 `#anony_XX` → 中文 |
| `parseFromClient` | `parsers/client.ts` | `from_client` 数字码 → 客户端名称 |
| `calcPagination` | `parsers/topic.ts` | 分页计算：总页数 = ceil(总行数 / 每页行数) |

### 错误解析

NGA 有两种错误格式，需统一处理：

```typescript
// src/shared/parsers/error.ts
export function parseNgaError(data: any): string | null {
  if (data.error) {
    // {"error": {"0": "错误描述"}}
    return typeof data.error === 'string' ? data.error : (data.error['0'] ?? '未知错误');
  }
  if (data.error_code) {
    const codes: Record<number, string> = {
      9: '附件过大',
      // ...更多错误码
    };
    return codes[data.error_code] ?? `错误码: ${data.error_code}`;
  }
  return null;
}
```

## 黑名单过滤策略

黑名单数据存储在前端 `localStorage`，由前端请求时附带黑名单用户 ID 列表，后端在解析响应时过滤。

### 过滤执行位置

```
┌────────────────────────────────────────────────────────────────┐
│ 前端                                                            │
│ 1. 登录后从 localStorage 读取黑名单 userId 列表                   │
│ 2. 每次 API 请求在 header 中附带：X-Blacklist: uid1,uid2,...     │
│ 3. 对后端未完全过滤的场景做兜底（如新加入黑名单的缓存数据）         │
├────────────────────────────────────────────────────────────────┤
│ 后端                                                            │
│ 1. 从请求头 X-Blacklist 解析黑名单集合                           │
│ 2. 主题列表解析器：跳过黑名单用户的主题                           │
│ 3. 帖子详情解析器：跳过黑名单用户的楼层                           │
│ 4. 过滤后调整 __T__ROWS 等计数字段                               │
└────────────────────────────────────────────────────────────────┘
```

### 实现

```typescript
// src/server/middleware/auth.ts 中提取黑名单
export function extractBlacklist(req: IncomingMessage): Set<string> {
  const header = req.headers['x-blacklist'] as string | undefined;
  if (!header) return new Set();
  return new Set(header.split(',').map(s => s.trim()).filter(Boolean));
}

// src/shared/parsers/topic.ts 中过滤
export function parseTopicList(raw: any, blacklist: Set<string> = new Set()): TopicListInfo {
  const topics: ThreadPageInfo[] = [];
  const tMap = raw.data.__T;
  for (const key of Object.keys(tMap)) {
    const t = tMap[key];
    if (blacklist.has(String(t.authorid))) continue; // 跳过黑名单用户
    topics.push(mapTopicRaw(t));
  }
  // ...
}
```

## 前端数据缓存

### 策略

论坛应用以读为主，前端可以适度缓存减少请求：

```
┌─────────────────────────────────────┐
│  内存缓存（Map, 会话级）              │
│  - 板块分类树（低频变化）              │
│  - 用户头像 URL（避免重复请求）        │
│  - 当前用户信息                       │
├─────────────────────────────────────┤
│  localStorage（持久化）               │
│  - Session Token                     │
│  - 黑名单 JSON                       │
│  - 收藏的板块列表                     │
│  - 用户偏好设置（主题、字号等）        │
└─────────────────────────────────────┘
```

### 缓存 API 封装

```typescript
// src/client/lib/cache.ts
const memoryCache = new Map<string, { data: any; expireAt: number }>();

export function setCache(key: string, data: any, ttlMs = 5 * 60 * 1000): void {
  memoryCache.set(key, { data, expireAt: Date.now() + ttlMs });
}

export function getCache<T>(key: string): T | null {
  const entry = memoryCache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expireAt) {
    memoryCache.delete(key);
    return null;
  }
  return entry.data as T;
}
```

不使用 Service Worker 或 IndexedDB —— 对于论坛客户端来说过度设计。简单的内存 Map + localStorage 足够。
