# 11 数据模型总汇

> 本文件汇总所有数据模型，使用 TypeScript 接口定义，方便任何技术栈参考。

---

## 核心实体关系

```
Category (板块分类)
├── CategorySub (子分类)
│   └── BoardContent (板块内容)
│
Board (板块)
├── SubBoard (子板块)
│
BoardCategory (板块分类容器)
├── Board[]
└── BoardCategory[] (嵌套)

TopicListInfo (主题列表页)
├── ThreadPageInfo[] (主题信息)
└── SubBoard[] (子板块列表)

ThreadData (帖子详情页)
├── ThreadPageInfo (主题元信息)
└── ThreadRowInfo[] (楼层列表)
    ├── Attachment[] (附件)
    ├── ThreadRowInfo[] (嵌套评论)
    └── DiceData (骰子)

MessageListInfo (私信列表)
└── MessageThreadInfo[] (会话)

MessageDetailInfo (私信详情)
└── MessageArticle[] (消息)

ProfileData (用户资料)
├── AdminForumsData[] (管理板块)
└── ReputationData[] (声望)

NotificationInfo (通知)
└── RecentReplyInfo (回复通知)

User (用户认证, Room Entity)

NoteInfo (用户笔记, Room Entity)
```

---

## 完整模型定义

### User — 用户/认证（Room Entity: `users` 表）

```typescript
interface User {
  userId: string          // 用户 ID（@PrimaryKey，Room 列名 uid）
  nickName: string        // 昵称（Room 列名 nick_name）
  cid: string             // 认证令牌（Room 列名 cid）
  avatarUrl: string       // 头像 URL（Room 列名 avatar_url）
}
```

### NoteInfo — 用户笔记（Room Entity: `notes` 表）

```typescript
interface NoteInfo {
  userId: string          // 用户 ID（@PrimaryKey，Room 列名 userId）
  nickName: string        // 昵称（Room 列名 nickName）
  note: string | null     // 笔记内容（Room 列名 note，可为空）
}
```

### ProfileData — 用户资料

```typescript
interface ProfileData {
  uid: string
  userName: string
  avatarUrl: string
  emailAddress: string
  phoneNumber: string
  frame: string           // 头像框
  memberGroup: string     // 会员组
  money: string           // 金钱
  postCount: string       // 发帖数
  registerDate: string    // 注册日期
  sign: string            // 签名
  muted: boolean
  mutedTime: string
  nuked: boolean
  ipLoc: string           // IP 属地
  adminForums: AdminForumsData[]
  reputationEntryList: ReputationData[]
}

interface AdminForumsData {
  fid: string
  forumName: string
}

interface ReputationData {
  name: string
  data: string
}
```

### Category / Board — 板块

```typescript
interface Category {
  id: string
  name: string
  sub: CategorySub[]
}

interface CategorySub {
  name: string
  content: BoardContent[]
}

interface BoardContent {
  fid: number
  stid: number
  name: string
  info: string
  nameS: string
  infoS: string
  head: string
  bit?: number            // API 返回但客户端未映射
}

interface Board {
  fid: number
  stid: number
  name: string
  boardHead: string
}

interface SubBoard extends Board {
  tidStr: string
  type: number
  checked: boolean
  description: string
  parentFidStr: string
}

interface BoardCategory {
  categoryName: string
  isBookmarkCategory: boolean
  boardList: Board[]
  subCategoryList: BoardCategory[]
}
```

### TopicListInfo — 主题列表

```typescript
interface TopicListInfo {
  name: string
  threadPageList: ThreadPageInfo[]
  subBoardList: SubBoard[]
  curTime: number
}

interface ThreadPageInfo {
  tid: number
  fid: number
  author: string
  authorId: number
  lastPoster: string
  replies: number
  subject: string
  titleFont: string
  type: number
  topicMisc: string
  page: number
  pid: number
  position: number
  isAnonymity: boolean
  postDate: number
  replyInfo: ReplyInfo
  board: string
  mirrorBoard: boolean
}

interface ReplyInfo {
  pidStr: string
  content: string
  subject: string
  postDate: string
  authorId: string
  tidStr: string
}
```

### TopicListBean — 主题列表原始 API 数据

```typescript
interface TopicListBean {
  data: TopicListData
  encode: string
  time: number
}

interface TopicListData {
  __CU: CurrentUser
  __GLOBAL: string
  __F: ForumInfo
  __ROWS: string
  __T: Record<string, TopicRaw>
  __T__ROWS: number
  __T__ROWS_PAGE: number
  __R__ROWS_PAGE: number
}

interface CurrentUser {
  uid: number
  group_bit: number
  admincheck: string
  rvrc: number
}

interface ForumInfo {
  topped_topic: string
  sub_forums: string
  fid?: number
  name?: string
}

interface TopicRaw {
  tid: number
  fid: number
  quote_from: number
  quote_to: string
  topic_misc: string
  author: string
  authorid: string
  subject: string
  type: number
  postdate: number
  lastpost: number
  lastposter: string
  replies: number
  lastmodify: number
  recommend: number
  titlefont: string
  admin_ui: number
  tpcurl: string
  parent: Record<string, string>
  topic_misc_var: Record<string, number>
  __P: TopicQuoteInfo
}

interface TopicQuoteInfo {
  tid: number
  pid: number
  authorid: string
  type: number
  postdate: number
  subject: string
  content: string
}
```

### ThreadData — 帖子详情

```typescript
interface ThreadData {
  rowList: ThreadRowInfo[]
  threadInfo: ThreadPageInfo
  __F: Record<string, string>
  __ROWS: number
  rowNum: number
  rawData: string
}
```

### ThreadRowInfo — 楼层/回复

```typescript
interface ThreadRowInfo {
  tid: number
  fid: number
  pid: number
  lou: number
  authorid: number
  author: string
  subject: string
  content: string
  vote: string
  postdate: string
  attachs: Record<string, Attachment>
  level: string
  yz: string
  js_escap_avatar: string
  muteTime: string
  aurvrc: number
  signature: string
  comments: ThreadRowInfo[]
  hotReplies: string[]
  from_client: string
  from_client_model: string
  isanonymous: boolean
  alterinfo: string
  score: number
  score_2: number
  isInBlackList: boolean
  userNote: string
  imageUrlList: string[]
  formattedHtmlData: string
  isMuted: boolean
  postCount: string
  reputation: number
  memberGroup: string
}
```

### Attachment — 附件

```typescript
interface Attachment {
  aid: string
  attachurl: string
  url_utf8_org_name: string
  name: string
  ext: string
  type: string
  size: number
  thumb: string
  dscp: string
  subid: number
}
```

### DiceData — 骰子

```typescript
interface DiceData {
  txt: string
  authorId: number
  tId: number
  pId: number
  seedOffset: number
  rndSeed: number          // 注意：Java 类型为 double
  id: string
  argsId: string
  seed: number             // 注意：Java 类型为 double
}
```

### Message — 私信

```typescript
interface MessageListInfo {
  rowsPerPage: number
  nextPage: number
  currentPage: number
  messageEntryList: MessageThreadInfo[]
}

interface MessageThreadInfo {
  mid: number
  subject: string
  time: string
  lasttime: string
  posts: number
  from_username: string
  last_from_username: string
}

interface MessageDetailInfo {
  nextPage: number
  currentPage: number
  alluser: string
  title: string
  messageEntryList: MessageArticle[]
}

interface MessageArticle {
  subject: string
  time: string
  content: string
  from: string
  lou: number
  js_escap_avatar: string
  author: string
  yz: string
  mute_time: string
  signature: string
  formated_html_data: string
}
```

### Notification — 通知

```typescript
interface NotificationInfo {
  type: number
  userName: string
  unread: boolean
  timeStamp: string
  userId: string
}

interface RecentReplyInfo extends NotificationInfo {
  title: string
  pidStr: string
  tidStr: string
}
```

### TopicPostBean — 发帖信息

```typescript
interface TopicPostBean {
  data: TopicPostData
  encode: string
  time: number
  debug: any              // 调试信息
}

interface TopicPostData {
  action: string
  fid: number
  auth: string               // 附件上传验证码
  if_moderator: number
  tid: string
  __CU: CurrentUser
  __GLOBAL: string
  __F: ForumPostInfo
  attach_url: string
}

interface ForumPostInfo {
  bit_data: number
  fid: number
  name: string
}
```

### MissionDetailData — 任务

```typescript
interface MissionDetailData {
  id: number
  name: string
  info: string
  detail: string
  stat: string
  isSucceeded: boolean    // Java 字段名: issuccessed（注意拼写）
}
```

### ForumSearchResult — 板块搜索结果

```typescript
interface ForumSearchResult {
  code: number
  msg: string
  result: ForumCategory[]
}

interface ForumCategory {
  id: string
  name: string
  groups: ForumGroup[]
}

interface ForumGroup {
  id: string
  name: string
  forums: ForumItem[]
}

interface ForumItem {
  id: number
  name: string
  stid: number
}
```
