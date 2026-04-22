# 05 API 映射

后端对外暴露干净的 RESTful JSON API，内部转换为 NGA 原始 API 调用。

## 接口总表

| 前端调用 | 后端路由 | NGA 原始 API |
|----------|---------|-------------|
| `GET /api/auth/captcha?id=` | 获取验证码（按需） | `GET /login_check_code.php?id=loginXXX&from=login` |
| `POST /api/auth/login` | 登录（两步） | `POST /nuke.php` (qrlogin_gen + login v2) |
| `GET /api/auth/me` | 当前用户 | 从 session 读取 |
| `POST /api/auth/logout` | 登出 | 清除 session |
| `GET /api/forum/categories` | 板块分类 | `GET /app_api.php?__lib=home&__act=category` |
| `GET /api/forum/search?key=` | 搜索板块 | `GET http://bbs.nga.cn/forum.php?__output=8&key={GBK编码key}` |
| `POST /api/forum/subscribe` | 订阅板块 | `POST https://bbs.ngacn.cc/nuke.php?__lib=user_option&__act=set&raw=3&type={type}&__output=8` (注意 type=1 时动作反转) |
| `GET /api/topics?fid=&page=` | 主题列表 | `GET /thread.php?lite=js&noprefix` |
| `GET /api/topics?favor=1&page=` | 收藏列表 | `GET /thread.php?favor=1&lite=js&noprefix` |
| `GET /api/topics?key=&page=` | 搜索主题 | `GET /thread.php?key={key}&lite=js&noprefix` |
| `GET /api/topics?authorid=&page=` | 用户主题 | `GET /thread.php?authorid={id}&lite=js&noprefix` |
| `GET /api/thread?tid=&page=` | 帖子详情 | `GET /read.php?__output=8&noprefix&v2` |
| `GET /api/post/auth?fid=&action=` | 发帖 auth | `POST /post.php?fid={fid}&action={action}&tid={tid}&lite=js` |
| `GET /api/post/topic-keys?fid=` | 主题分类标签 | `GET /nuke.php?__lib=topic_key&__act=get&fid={fid}&__output=8` |
| `POST /api/post/new` | 发新帖 | `POST /post.php` (GBK body) |
| `POST /api/post/reply` | 回复帖子 | `POST /post.php` (GBK body) |
| `POST /api/post/modify` | 编辑帖子 | `POST /post.php` (GBK body) |
| `POST /api/post/comment` | 评论楼层 | `POST /post.php` (GBK body) |
| `POST /api/upload/attach` | 上传附件 | `POST https://img8.nga.cn/attach.php` (multipart) |
| `GET /api/messages?page=` | 私信列表 | `GET /nuke.php?__lib=message&__act=message&act=list&page={page}&lite=js` |
| `GET /api/messages/:mid?page=` | 私信详情 | `GET /nuke.php?__lib=message&__act=message&act=read&page={page}&mid={mid}&lite=js` |
| `POST /api/messages/send` | 发送私信 | `POST /nuke.php?__lib=message&__act=message&lite=js&act=new` (GBK body: `to&mid&subject&content`) |
| `GET /api/user/:uid` | 用户资料 | `GET /nuke.php?__lib=ucp&__act=get&lite=js&uid={uid}` (需 `Referer: {domain}/nuke.php?func=ucp&lite=jsx&uid={uid}`) |
| `POST /api/user/sign` | 修改签名 | `POST /nuke.php?__lib=set_sign` (GBK body) |
| `GET /api/notifications` | 通知列表 | `GET /nuke.php?__lib=noti&__output=8&__act=get_all` |
| `POST /api/notifications/clear` | 清除通知 | `POST /nuke.php?__lib=noti&raw=3&__act=del` |
| `POST /api/checkin` | 签到 | `POST /nuke.php?__lib=check_in&__act=check_in&lite=js` |
| `POST /api/favorite/add` | 添加收藏 | `POST /nuke.php?__lib=topic_favor&lite=js&__act=topic_favor&action=add&tid={tid}` |
| `POST /api/favorite/remove` | 取消收藏 | `POST /nuke.php?__lib=topic_favor&__output=8&__act=topic_favor&action=del` (body: `tidarray={tid}_{pid}`) |
| `POST /api/vote` | 点赞/踩 | `POST /nuke.php?__lib=topic_recommend&__act=add&raw=3&__output=8` (body: `value={1|-1}&tid=&pid=`) |

## 接口详细设计

### 认证模块 (v2)

> v1 已废弃，v2 为两步流程：先提交凭据，按需获取验证码。

#### 获取验证码（按需，非预加载）

```
GET /api/auth/captcha?id=loginXXXXXXXX

Response:
{
  "ok": true,
  "image": "data:image/png;base64,..." // Base64 图片
}
```

后端行为：
1. 使用前端传来的 captchaId（`loginXXX` 格式）
2. 请求 `GET https://bbs.nga.cn/login_check_code.php?id={captchaId}&from=login`
3. 将图片二进制转为 Base64 返回
4. 验证码为 **6 位**字母+数字混合

#### 登录（两步）

```
POST /api/auth/login
Content-Type: application/json

--- Step 1：提交凭据 ---
Request:
{
  "username": "xxx",
  "password": "xxx"
}

Response (需要验证码):
{
  "ok": false,
  "needCaptcha": true,
  "loginToken": "...",        // 临时登录会话 token
  "captchaId": "loginXXX",    // 验证码 ID
  "captchaImage": "data:image/png;base64,..."  // 验证码图片
}

Response (直接成功，无验证码):
{
  "ok": true,
  "token": "hex...",
  "user": { "uid": "123", "nickName": "xxx", "avatarUrl": "..." }
}

--- Step 2：提交验证码 ---
Request:
{
  "loginToken": "...",
  "captchaId": "loginXXX",
  "captcha": "ABCDEF"
}

Response (成功):
{
  "ok": true,
  "token": "hex...",
  "user": { "uid": "123", "nickName": "xxx", "avatarUrl": "..." }
}

Response (失败):
{
  "ok": false,
  "error": "验证码错误"
}
```

后端行为（Step 1）：
1. POST `nuke.php`，字段：`__lib=login, __output=1, __act=qrlogin_gen, __inchst=UTF-8`
2. 解析响应获取 `qrkey` 和 `hiddenkey`
3. POST `nuke.php`，字段：`__lib=login, __act=login, v2=1, app_id=5004, qrkey, hiddenkey, name, password, type=name`
4. 如果需要验证码：存储 `{qrkey, hiddenkey, username, password}` 到 `loginSessions` Map，生成 `loginToken`，获取验证码图片，返回给前端
5. 如果直接成功：创建 session，返回 token

后端行为（Step 2）：
1. 用 `loginToken` 从 `loginSessions` 取回临时会话
2. POST `nuke.php`，同 Step 1 字段 + `captcha` 和 `rid`
3. 如果成功：创建 session，返回 token
4. 如果失败：返回错误信息

### 主题列表

```
GET /api/topics?fid=7&page=1
GET /api/topics?stid=123&page=1
GET /api/topics?key=keyword&page=1
GET /api/topics?authorid=12345&page=1
GET /api/topics?favor=1&page=1
GET /api/topics?recommend=1&page=1

Response:
{
  "ok": true,
  "data": {
    "name": "板块名",
    "curTime": 1511446433,
    "pagination": { "page": 1, "totalPages": 10, "totalRows": 350 },
    "topics": [
      {
        "tid": 11915941,
        "fid": 275,
        "author": "xxx",
        "authorId": 10350496,
        "subject": "标题",
        "replies": 13,
        "postDate": 1498529634,
        "lastPoster": "xxx",
        "type": 516,
        "titleFont": "",
        "isAnonymity": false,
        "board": "测试版面"
      }
    ],
    "subBoards": [...]
  }
}
```

后端行为：
1. 根据参数构建 NGA URL（`thread.php?lite=js&noprefix`）
2. 调用 NGA API
3. 遍历 `data.__T` Map，映射为 `topics` 数组
4. 从 `__T__ROWS` 和 `__T__ROWS_PAGE` 计算分页
5. 应用黑名单过滤

### 帖子详情

```
GET /api/thread?tid=11915941&page=1
GET /api/thread?tid=11915941&authorid=12345
GET /api/thread?pid=253178256

Response:
{
  "ok": true,
  "data": {
    "threadInfo": { "tid": 11915941, "subject": "标题", ... },
    "forumName": "测试版面",
    "totalRows": 50,
    "pagination": { "page": 1, "totalPages": 3 },
    "posts": [
      {
        "pid": 253178256,
        "lou": 0,
        "author": "xxx",
        "authorid": 12345,
        "content": "<已解析的HTML>",
        "postdate": "1511787523",
        "avatar": "https://...",
        "level": "12",
        "signature": "<签名HTML>",
        "attachs": [...],
        "comments": [...],
        "isanonymous": false,
        "score": 0
      }
    ]
  }
}
```

后端行为：
1. 请求 `read.php?__output=8&noprefix&v2`
2. 解析 `rowList`，对每个楼层的 `content` 调用 `parseNgaContent()`
3. 解析 `attachs` Map，补全附件 URL
4. 处理评论嵌套（`comments` 数组）
5. 过滤黑名单用户

### 发帖/回复（两步流程）

发帖/回复需要先获取 auth 码，再提交内容。

#### Step 1: 获取 auth 码

```
POST /api/post/auth
Content-Type: application/json

Request:
{
  "fid": "275",
  "action": "reply",      // reply / new / modify
  "tid": "11915941",       // 可选，reply/modify 时需要
  "stid": ""               // 可选，子板块 ID
}

Response:
{
  "ok": true,
  "data": { "auth": "xxxx" }    // auth 码，用于附件上传
}
```

后端行为：请求 `POST {domain}/post.php?fid={fid}&action={action}&tid={tid}&lite=js`

#### Step 2: 提交帖子

```
POST /api/post/reply
Content-Type: application/json

Request:
{
  "tid": "11915941",
  "fid": "275",
  "content": "回复内容",
  "anony": 0,
  "attachments": "xxx",        // 可选
  "attachmentsCheck": "xxx",   // 可选
  "stid": ""                   // 可选，子板块 ID
}

Response:
{
  "ok": true,
  "data": { "tid": "11915941", "pid": "新帖子ID" }
}
```

后端行为：
1. 构建 GBK 编码 body，包含字段：
   - `step=2`
   - `post_content={content}`
   - `tid={tid}`
   - `fid={fid}`
   - `action=reply`
   - `anony={0|1}`
   - `attachments={attachments}`
   - `attachments_check={attachmentsCheck}`
   - `stid={stid}`（可选）
2. 请求 `POST {domain}/post.php` with GBK body
3. 解析响应确认成功

#### 评论楼层（特殊参数）

```
POST /api/post/comment
Content-Type: application/json

Request:
{
  "tid": "11915941",
  "pid": "253178256",       // 目标楼层 pid
  "fid": "275",
  "content": "评论内容",
  "anony": 0
}
```

后端行为：与回复不同，评论使用特殊参数：
- `comment=1`
- `lite=htmljs`（不是 `lite=js`）
- `nojump=1`

#### 上传附件

```
POST /api/upload/attach
Content-Type: multipart/form-data

Request fields:
  attachment_file1: (binary file)
  attachment_file1_url_utf8_name: (original filename)
  fid: (board ID)
  auth: (从 Step 1 获取的 auth 码)
  func: "upload"
  v2: "1"
  lite: "js"
  attachment_file1_auto_size: ""
  attachment_file1_watermark: ""
  attachment_file1_dscp: ""
  attachment_file1_img: "1"
  origin_domain: "bbs.ngacn.cc"

Response:
{
  "ok": true,
  "data": {
    "attachments": "xxx",
    "attachmentsCheck": "xxx"
  }
}
```

后端行为：请求 `POST https://img8.nga.cn/attach.php`（固定域名，multipart/form-data）

### 私信

```
GET /api/messages?page=1

Response:
{
  "ok": true,
  "data": {
    "pagination": { "page": 1, "nextPage": 2 },
    "messages": [
      {
        "mid": 123,
        "subject": "主题",
        "time": "1511787523",
        "lasttime": "1511788000",
        "posts": 5,
        "fromUsername": "xxx",
        "lastFromUsername": "yyy"
      }
    ]
  }
}
```

#### 发送私信

```
POST /api/messages/send
Content-Type: application/json

Request:
{
  "to": "username",       // 目标用户名
  "mid": "",              // 可选，回复已有私信时传 mid
  "subject": "主题",       // 可选，新建时需要
  "content": "内容"
}
```

后端行为：
1. 构建 GBK 编码 body：`to={username}&mid={mid}&subject={subject}&content={content}`
2. 请求 `POST {domain}/nuke.php?__lib=message&__act=message&lite=js&act=new`

## 请求/响应转换规则

| NGA 特性 | 后端处理 |
|----------|---------|
| `lite=js` 前缀 | 自动去除 `window.script_muti_get_var_store=` |
| JS 注释标记 | 自动去除 `/*$js$*/` |
| 非标准 JSON | 修复数字开头字符串值的引号问题（见 01-server.md JSON 预处理管道） |
| GBK 编码 | 后端使用 `iconv-lite` 编解码，前端只接触 UTF-8 |
| Cookie 认证 | 后端从 session 查找 Cookie，前端传 Bearer token |
| `__T` Map 格式 | 转为数组 `topics[]` |
| `attachs` Map 格式 | 转为数组 `attachs[]` |
| `__T__ROWS_PAGE` 分页 | `totalPages = ceil(__T__ROWS / __T__ROWS_PAGE)` |
| NGA HTML 内容 | 后端调用 `parseNgaContent()` 转为安全 HTML |
| 错误格式 | 统一为 `{ ok: false, error: "消息" }` |
| `authorid` string 类型 | 转为 number |
| 时间戳（秒） | 原样返回，前端格式化 |
| 匿名用户名 `#anony_XX` | 解码为中文用户名 |
| `from_client` 数字码 | 转为客户端名称（iOS/Android 等） |
| 用户资料页 | 需要附加 `Referer` 请求头 |
| 板块搜索 | 关键词需 GBK 编码，域名固定 `bbs.nga.cn` |
| 板块订阅 | `type=1` 的板块动作反转（add=取消，del=订阅） |
| 图片缩略图后缀 | 剥离 `.thumb_s.jpg` 等后缀获取原图 |
| 黑名单过滤 | 前端传 `X-Blacklist` header，后端在解析时过滤 |

## 域名切换与故障降级

NGA 有多个域名，经常出现某个不可用的情况。后端 `NgaClient` 维护域名列表和当前活跃域名：

```typescript
domains = ['https://bbs.nga.cn', 'https://bbs.ngacn.cc', 'https://nga.178.com']
```

- 用户可在设置页切换首选域名
- 请求失败时自动尝试下一个域名（`rotateDomain()`）
- 部分接口固定域名：
  - 登录/验证码：固定 `https://bbs.nga.cn`（原 `bbs.ngacn.cc` SSL 证书已过期，302→`bbs.nga.cn`）
  - 板块搜索：固定 `http://bbs.nga.cn`
  - 附件上传：固定 `https://img8.nga.cn`

## 板块分类数据源策略

板块分类数据来自线上 API，但需本地缓存兜底：

1. **首次加载**：`GET /app_api.php?__lib=home&__act=category` 获取全量分类
2. **缓存到前端**：存入 localStorage，设置 TTL（24小时）
3. **后续加载**：优先使用缓存，过期后重新请求
4. **离线兜底**：可内嵌一份 `category.json` 静态文件作为 fallback

前端 `api.get('/forum/categories')` 封装中自动处理缓存逻辑（参见 `02-data-layer.md` 缓存 API 封装）。
