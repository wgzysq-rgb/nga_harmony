# 10 杂项接口

## 每日签到

```
POST {domain}/nuke.php?__lib=check_in&__act=check_in&lite=js
```

| 参数 | 说明 |
|------|------|
| `__lib` | `check_in` |
| `__act` | `check_in` |
| `lite` | `js` |

---

## 收藏主题

### 添加收藏

```
POST {domain}/nuke.php?__lib=topic_favor&lite=js&noprefix&__act=topic_favor&action=add&tid={tid}
```

支持附加 `pid` 参数定位到特定楼层：

```
POST {domain}/nuke.php?__lib=topic_favor&lite=js&noprefix&__act=topic_favor&action=add&tid={tid}&pid={pid}
```

### 取消收藏

```
POST {domain}/nuke.php?__lib=topic_favor&__act=topic_favor&__output=8&action=del&page={page}&tidarray={tid}
```

| 参数 | 说明 |
|------|------|
| `action` | `del` |
| `tidarray` | 主题 ID，格式 `{tid}` 或 `{tid}_{pid}` |
| `page` | 页码 |

### 查看收藏列表

```
GET {domain}/thread.php?favor=1&page={page}&lite=js&noprefix
```

---

## 点赞 / 踩

```
POST {domain}/nuke.php?
```

### 请求参数

| 字段 | 说明 |
|------|------|
| `__lib` | `topic_recommend` |
| `__act` | `add` |
| `raw` | `3` |
| `__output` | `8` |
| `value` | `1`（赞）或 `-1`（踩） |
| `tid` | 主题 ID |
| `pid` | 帖子 ID |

---

## 搜索帖子

搜索是在主题列表接口中通过参数实现的：

### 按关键词搜索

```
GET {domain}/thread.php?key={keyword}&page={page}&lite=js&noprefix
```

关键词使用 UTF-8 编码。

### 按板块内搜索

```
GET {domain}/thread.php?fid={fid}&key={keyword}&page={page}&lite=js&noprefix
```

### 按作者搜索

```
GET {domain}/thread.php?author={authorName}&page={page}&lite=js&noprefix
```

作者名使用 GBK 编码。附加 `searchpost=1` 可搜索帖子内容。

### 按作者 ID 搜索

```
GET {domain}/thread.php?authorid={authorId}&page={page}&lite=js&noprefix
```

---

## 搜索板块

```
GET http://bbs.nga.cn/forum.php?__output=8&key={keyword}
```

> **注意**：此接口域名硬编码为 `http://bbs.nga.cn`，不使用动态域名。

关键词使用 GBK 编码。响应结构见 [03-forum.md](03-forum.md)。

---

## 举报

```
POST {domain}/nuke.php?
```

通过 queryMap + fieldMap 组合发送举报信息。

---

## 任务系统

```typescript
// MissionDetailData — 任务详情
interface MissionDetailData {
  id: number          // 任务 ID
  name: string        // 任务名
  info: string        // 任务信息
  detail: string      // 任务详情
  stat: string        // 任务状态
  isSucceeded: boolean // 是否完成（Java 字段名: issuccessed）
}
```

---

## 黑名单

> **注意**：黑名单功能在原项目中是**纯本地管理**的，不涉及服务器 API。

- 存储在 SharedPreferences 中（key: `BLACK_LIST`）
- 格式为 `List<User>` 的 JSON 序列化（包含 userId 和 nickName），**不是**逗号分隔的 ID 字符串
- 由 `UserManagerImpl` 管理（`addToBlackList` / `removeFromBlackList` / `getBlackList`）
- 支持导入/导出（v1.2.1 新增）
- 帖子展示时在 `TopicConvertFactory` 中根据黑名单过滤

---

## JSON 解析层（ConvertFactory）

原项目中 JSON 到业务对象的转换由以下 Factory 类处理：

| 类 | 职责 |
|-----|------|
| `ArticleConvertFactory` | 帖子详情解析（楼层、附件、评论、骰子、HTML 内容构建） |
| `TopicConvertFactory` | 主题列表解析（含黑名单过滤、关键词过滤、排序） |
| `MessageConvertFactory` | 私信列表/详情解析 |
| `ForumNotificationFactory` | 通知列表/最近回复解析 |
| `ErrorConvertFactory` | 错误消息提取（JSON 错误 + 异常） |

新项目需实现对应的 JSON 解析逻辑。

---

## 获取全量板块

```
GET {domain}/app_api.php?__lib=home&__act=category
```

由 `GetAllForumsTask` 发起，响应结构同 [03-forum.md](03-forum.md) 中的分类板块接口。
