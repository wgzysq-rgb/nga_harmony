# 07 私信

## 私信列表

```
GET {domain}/nuke.php?__lib=message&__act=message&act=list&page={page}&lite=js
```

| 参数 | 说明 |
|------|------|
| `__lib` | `message` |
| `__act` | `message` |
| `act` | `list` |
| `page` | 页码 |
| `lite` | `js` |

### 响应数据模型

```typescript
// MessageListInfo — 私信列表
interface MessageListInfo {
  rowsPerPage: number                     // 每页条数
  nextPage: number                        // 下一页页码
  currentPage: number                     // 当前页码
  messageEntryList: MessageThreadInfo[]   // 私信会话列表
}

// MessageThreadInfo — 私信会话
interface MessageThreadInfo {
  mid: number              // 会话 ID
  subject: string          // 主题
  time: string             // 创建时间
  lasttime: string         // 最后消息时间
  posts: number            // 消息数
  from_username: string    // 发起者用户名
  last_from_username: string // 最后发送者用户名
}
```

---

## 私信详情

```
GET {domain}/nuke.php?__lib=message&__act=message&act=read&page={page}&mid={mid}&lite=js
```

| 参数 | 说明 |
|------|------|
| `mid` | 会话 ID |
| `page` | 页码 |

### 响应数据模型

```typescript
// MessageDetailInfo — 私信详情
interface MessageDetailInfo {
  nextPage: number                      // 下一页
  currentPage: number                   // 当前页
  alluser: string                       // 所有参与者
  title: string                         // 会话标题
  messageEntryList: MessageArticle[]    // 消息列表
}

// MessageArticle — 单条私信
interface MessageArticle {
  subject: string           // 主题
  time: string              // 时间
  content: string           // 内容
  from: string              // 发送者标识
  lou: number               // 楼层号
  js_escap_avatar: string   // 头像 URL
  author: string            // 作者名
  yz: string                // 用户状态
  mute_time: string         // 禁言时间
  signature: string         // 签名
  formated_html_data: string // 格式化 HTML
}
```

---

## 发送私信

```
POST {domain}/nuke.php?
```

### 请求参数

| 字段 | 说明 |
|------|------|
| `__lib` | `message` |
| `__act` | `message` |
| `lite` | `js` |
| `act` | 操作类型（默认 `new`，回复时可为其他值） |
| `to` | 收件人用户名（中文逗号自动替换为英文逗号，GBK 编码） |
| `mid` | 会话 ID（回复已有会话时传递） |
| `subject` | 主题（GBK 编码） |
| `content` | 内容（GBK 编码） |

> POST body 使用 GBK 编码。
