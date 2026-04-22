# 05 帖子详情（楼层内容）

## 接口

```
GET {domain}/read.php?page={page}&__output=8&noprefix&v2&tid={tid}
GET {domain}/read.php?page={page}&__output=8&noprefix&v2&pid={pid}
GET {domain}/read.php?page={page}&__output=8&noprefix&v2&tid={tid}&authorid={authorid}
```

## 请求参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `tid` | int | 主题 ID（与 pid 二选一） |
| `pid` | int | 帖子 ID（定位到特定楼层） |
| `authorid` | int | 只看某作者 |
| `page` | int | 页码 |
| `__output` | string | 固定 `8`（JSON 格式） |
| `noprefix` | - | 去前缀 |
| `v2` | - | V2 接口 |
| `searchpost` | int | 搜索帖子内容标志 |
| `content` | string | 搜索内容关键词 |

> **注意**：此接口使用 `__output=8` 而非 `lite=js`，直接返回 JSON。

---

## 响应数据结构

```json
{
  "__ROWS": 50,
  "__F": { "275": "测试版面" },
  "rowList": [
    {
      "tid": 11915941,
      "fid": 275,
      "pid": 253178256,
      "author": "username",
      "authorid": 39454545,
      "subject": "标题",
      "content": "<HTML内容>",
      "postdate": "1511787523",
      "lou": 1,
      "isanonymous": false,
      "alterinfo": "",
      "attachs": { "0": {...} },
      "level": "12",
      "yz": "0",
      "js_escap_avatar": "https://...",
      "muteTime": "",
      "aurvrc": 10,
      "signature": "<签名HTML>",
      "comments": [...],
      "from_client": "android",
      "from_client_model": "",
      "vote": null,
      "score": 0,
      "score_2": 0
    }
  ],
  "threadInfo": {
    "tid": 11915941,
    "fid": 275,
    ...
  }
}
```

---

## 数据模型

```typescript
// ThreadData — 帖子页面数据
interface ThreadData {
  rowList: ThreadRowInfo[]       // 楼层列表
  threadInfo: ThreadPageInfo     // 主题元信息
  __F: Record<string, string>   // 板块信息 {"fid": "板块名"}
  __ROWS: number                // 总楼层数
  rowNum: number                // 当前行数
  rawData: string               // 原始 JSON 字符串
}

// ThreadRowInfo — 单条楼层/回复
interface ThreadRowInfo {
  // --- 基础标识 ---
  tid: number           // 主题 ID
  fid: number           // 板块 ID
  pid: number           // 帖子 ID
  lou: number           // 楼层号（0=楼主）
  authorid: number      // 作者 ID
  author: string        // 作者名

  // --- 内容 ---
  subject: string       // 标题
  content: string       // 内容（HTML 格式，含 NGA 自定义标签）
  vote: string          // 投票数据（JSON 字符串或 null）

  // --- 时间 ---
  postdate: string      // 发帖时间戳（秒）

  // --- 附件 ---
  attachs: Record<string, Attachment>  // 附件 Map

  // --- 用户信息 ---
  level: string         // 用户等级
  yz: string            // 用户状态（负数=被核爆/nuked）
  js_escap_avatar: string  // 头像 URL
  aurvrc: number        // 威望值
  signature: string     // 签名（HTML）
  muteTime: string      // 禁言到期时间
  isMuted: boolean      // 是否被禁言
  postCount: string     // 发帖数
  reputation: number    // 声望（浮点）
  memberGroup: string   // 会员组

  // --- 评论嵌套 ---
  comments: ThreadRowInfo[]  // 子评论（结构同楼层）
  hotReplies: string[]       // 热门回复

  // --- 来源 ---
  from_client: string        // 来源客户端
  from_client_model: string  // 来源设备型号

  // --- 其他 ---
  isanonymous: boolean    // 是否匿名
  alterinfo: string       // 编辑信息
  score: number           // 评分 1
  score_2: number         // 评分 2
  isInBlackList: boolean  // 是否在黑名单
  userNote: string        // 用户备注
  imageUrlList: string[]  // 内容中的图片 URL 列表
  formattedHtmlData: string // 格式化后的 HTML
}
```

---

## Attachment — 附件

```typescript
interface Attachment {
  aid: string              // 附件 ID
  attachurl: string        // 附件 URL（相对路径）
  url_utf8_org_name: string // 原始文件名（UTF-8）
  name: string             // 文件名
  ext: string              // 扩展名
  type: string             // 类型（image 等）
  size: number             // 文件大小（字节）
  thumb: string            // 缩略图 URL
  dscp: string             // 描述
  subid: number            // 子 ID
}
```

### 附件 URL 拼接

```
完整 URL = https://img.nga.178.com/attach/{attachurl}
```

---

## DiceData — 骰子数据

帖子内容中可能包含骰子数据：

```typescript
interface DiceData {
  txt: string        // 骰子描述文本
  authorId: number   // 掷骰者 ID
  tId: number        // 主题 ID
  pId: number        // 帖子 ID
  seedOffset: number // 种子偏移
  rndSeed: number    // 随机种子
  id: string         // 骰子 ID
  argsId: string     // 参数 ID
  seed: number       // 种子
}
```

---

## 内容解析说明

NGA 帖子内容使用自定义 BBCode/HTML 混合格式，需要特殊处理：

| NGA 标签 | 说明 |
|----------|------|
| `[quote]...[/quote]` | 引用 |
| `[pid=X,Y,Z]...[/pid]` | 帖子引用（含 tid/pid/page） |
| `[uid=X]...[/uid]` | 用户链接 |
| `[tid=X]...[/tid]` | 主题链接 |
| `[s:ac:XXX]` | 表情（NGA 自有表情代码） |
| `[img]./mon_XXX[/img]` | NGA 表情图片 |
| `[collapse]...[/collapse]` | 折叠内容 |
| `[dice]...[/dice]` | 骰子 |
| `[flash=video]...[/flash]` | 视频 |

原项目使用 `lib_core` 模块中的解码器将这些内容转换为 HTML 供 WebView 显示。新项目需要实现对应的内容解析器。
