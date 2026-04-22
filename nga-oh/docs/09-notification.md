# 09 通知系统

## 获取全部通知

```
GET {domain}/nuke.php?__lib=noti&__output=8&__act=get_all
```

| 参数 | 说明 |
|------|------|
| `__lib` | `noti` |
| `__act` | `get_all` |
| `__output` | `8` |

### 响应

返回 JSON，包含通知列表和最近回复信息。

---

## 通知类型常量

| 类型值 | 含义 |
|--------|------|
| `1` | 主题被回复（TOPIC_REPLY） |
| `2` | 回复被回复（REPLY_REPLY） |
| `3` | 主题被评论（TOPIC_COMMENT） |
| `4` | 回复被评论（REPLY_COMMENT） |
| `7` | 主题中被 @（TOPIC_AT） |
| `8` | 回复中被 @（REPLY_AT） |
| `10` | 新私信（NEW_MESSAGE） |
| `11` | 私信回复（MESSAGE_REPLY） |

---

## 通知数据模型

```typescript
// NotificationInfo — 通知基类
interface NotificationInfo {
  type: number        // 通知类型
  userName: string    // 操作者用户名
  unread: boolean     // 是否未读
  timeStamp: string   // 时间戳
  userId: string      // 操作者用户 ID
}

// RecentReplyInfo — 回复通知（继承 NotificationInfo）
interface RecentReplyInfo extends NotificationInfo {
  title: string       // 主题标题
  pidStr: string      // 帖子 ID
  tidStr: string      // 主题 ID
}
```

---

## 清除全部通知

```
POST {domain}/nuke.php?__lib=noti&raw=3&__act=del
```

| 参数 | 说明 |
|------|------|
| `__lib` | `noti` |
| `__act` | `del` |
| `raw` | `3` |
