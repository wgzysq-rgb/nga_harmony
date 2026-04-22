# 04 主题列表

## 接口

```
GET {domain}/thread.php?{params}&page={page}&lite=js&noprefix
```

## 请求参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `fid` | int | 板块 ID（与 stid 二选一） |
| `stid` | int | 子板块 ID（与 fid 二选一） |
| `page` | int | 页码 |
| `lite` | string | 固定 `js` |
| `noprefix` | - | 去掉 JS 前缀 |
| `key` | string | 搜索关键词（UTF-8 编码） |
| `author` | string | 按作者名筛选（GBK 编码） |
| `authorid` | int | 按作者 ID 筛选 |
| `searchpost` | int | 搜索帖子内容标志 |
| `favor` | int | 收藏列表标志（`1` = 收藏列表） |
| `content` | int | 内容搜索标志 |
| `fidgroup` | string | 板块组 |
| `recommend` | int | 推荐排序（`1` = 按时间降序） |
| `twentyfour` | int | 24 小时热门主题筛选 |
| `content` | int | 内容搜索标志（与 `key` 配合搜索帖子内容） |

### 推荐排序参数组合

```
&recommend=1&order_by=postdatedesc&user=1
```

### URL 构建逻辑

```
优先级：author > stid > fid
如果有 author，忽略 fid/stid
如果有 key，附加关键词搜索
favor=1 时返回收藏列表
```

---

## 响应数据结构

```json
{
  "data": {
    "__CU": { "uid": 10350496, "group_bit": 622816, "admincheck": "", "rvrc": -10 },
    "__GLOBAL": "./template/js/nga_global.xml",
    "__F": {
      "topped_topic": "",
      "sub_forums": "",
      "fid": 275,
      "name": "测试版面"
    },
    "__ROWS": 2,
    "__T": {
      "0": {
        "tid": 11915941,
        "fid": 275,
        "quote_from": 0,
        "quote_to": "",
        "topic_misc": "",
        "author": "xxxxxx",
        "authorid": 10350496,
        "subject": "客户端测试发帖",
        "type": 516,
        "postdate": 1498529634,
        "lastpost": 1499236460,
        "lastposter": "killmanasdfasdf",
        "replies": 13,
        "lastmodify": 1500443085,
        "recommend": 1,
        "titlefont": "",
        "admin_ui": 1,
        "tpcurl": "/read.php?tid=11915941&fav=c7cf9a59",
        "parent": { "0": "275", "2": "测试版面" },
        "topic_misc_var": { "3": -1459709, "1": 32 }
      },
      "1": { ... }
    },
    "__T__ROWS": 1,
    "__T__ROWS_PAGE": 35,
    "__R__ROWS_PAGE": 20
  },
  "encode": "gbk",
  "time": 1511446433
}
```

| 字段 | 说明 |
|------|------|
| `__T` | 主题列表 Map，key 为序号 |
| `__T__ROWS` | 主题总数 |
| `__T__ROWS_PAGE` | 每页主题数（默认 35） |
| `__R__ROWS_PAGE` | 每页回复数（默认 20） |
| `__F` | 板块信息 |
| `__CU` | 当前用户信息 |

---

## 数据模型

```typescript
// TopicListInfo — 主题列表页
interface TopicListInfo {
  name: string
  threadPageList: ThreadPageInfo[]
  subBoardList: SubBoard[]
  curTime: number
}

// ThreadPageInfo — 主题信息（用于列表展示）
interface ThreadPageInfo {
  tid: number          // 主题 ID
  fid: number          // 板块 ID
  author: string       // 作者名
  authorId: number     // 作者 ID
  lastPoster: string   // 最后回复者
  replies: number      // 回复数
  subject: string      // 主题标题
  titleFont: string    // 标题样式（位掩码）
  type: number         // 主题类型（位掩码）
  topicMisc: string    // 杂项信息
  page: number         // 当前页
  pid: number          // 关联帖子 ID
  position: number     // 位置
  isAnonymity: boolean // 是否匿名
  postDate: number     // 发帖时间戳
  replyInfo: ReplyInfo // 回复引用信息
  board: string        // 所属板块名
  mirrorBoard: boolean // 是否为版面镜像
}

// ReplyInfo — 回复引用
interface ReplyInfo {
  pidStr: string
  content: string
  subject: string
  postDate: string
  authorId: string
  tidStr: string
}

// TopicListBean.DataBean.TBean — 原始 API 主题数据
interface TopicRaw {
  tid: number
  fid: number
  quote_from: number   // 引用来源
  quote_to: string     // 引用目标
  topic_misc: string   // 杂项
  author: string       // 作者名
  authorid: string     // 作者 ID（注意是 string）
  subject: string      // 标题
  type: number         // 类型掩码
  postdate: number     // 发帖时间戳
  lastpost: number     // 最后回复时间戳
  lastposter: string   // 最后回复者
  replies: number      // 回复数
  lastmodify: number   // 最后修改时间戳
  recommend: number    // 推荐数
  titlefont: string    // 标题字体样式
  admin_ui: number     // 管理 UI 标志
  tpcurl: string       // 帖子链接
  parent: Record<string, string>  // 父板块信息 {"0": "275", "2": "测试版面"}
  topic_misc_var: Record<string, number>
  __P: TopicQuoteInfo  // 引用预览
}

// TopicQuoteInfo — 引用预览
interface TopicQuoteInfo {
  tid: number
  pid: number
  authorid: string
  type: number
  postdate: number
  subject: string
  content: string      // 引用的内容 HTML
}
```

---

## type 字段位掩码（ApiConstants）

| 掩码 | 值 | 含义 |
|------|------|------|
| `MASK_TYPE_LOCK` | 1024 | 主题被锁定 |
| `MASK_TYPE_ATTACHMENT` | 8192 | 含附件 |
| `MASK_TYPE_ASSEMBLE` | 32768 | 合集 |

## titlefont 字段位掩码

| 掩码 | 值 | 含义 |
|------|------|------|
| `MASK_FONT_RED` | 1 | 红色 |
| `MASK_FONT_BLUE` | 2 | 蓝色 |
| `MASK_FONT_GREEN` | 4 | 绿色 |
| `MASK_FONT_ORANGE` | 8 | 橙色 |
| `MASK_FONT_SILVER` | 16 | 银色 |
| `MASK_FONT_BOLD` | 32 | 加粗 |
| `MASK_FONT_ITALIC` | 64 | 斜体 |
| `MASK_FONT_UNDERLINE` | 128 | 下划线 |

---

## 缓存机制

原项目支持主题列表缓存：
- 缓存路径：`{filesDir}/cache/{tid}/{tid}.json`
- 缓存内容为 ThreadPageInfo 的 JSON
- 支持离线读取
