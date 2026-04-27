# Open-NGA 收藏/签到/通知/赞踩/签名/搜索/版面模块 API 文档

> 模块: 收藏/签到/通知/赞踩/签名/搜索版面/订阅子版面/用户档案  
> 源码目录: `sp.phone.task.*`

---

## 1. 收藏主题 (BookmarkTask)

**源码**: `sp.phone.task.BookmarkTask`

### 1.1 添加收藏

| 属性 | 值 |
|------|---|
| **HTTP方法** | POST |
| **端点** | `{domain}/nuke.php?__lib=topic_favor&lite=js&noprefix&__act=topic_favor&action=add&tid={tid}` |
| **Retrofit方法** | `RetrofitService.post(url)` |

#### 请求参数 (Query Parameters，拼接在URL中)

| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `__lib` | string | 是 | `"topic_favor"` |
| `__act` | string | 是 | `"topic_favor"` |
| `lite` | string | 是 | `"js"` |
| `noprefix` | - | 是 | 去除前缀 |
| `action` | string | 是 | `"add"` |
| `tid` | int | 是 | 主题ID |
| `pid` | int | 否 | 回复ID (收藏特定回复时添加) |

#### 请求URL示例

**收藏主题**:
```
https://bbs.ngacn.cc/nuke.php?__lib=topic_favor&lite=js&noprefix&__act=topic_favor&action=add&tid=123456
```

**收藏特定回复**:
```
https://bbs.ngacn.cc/nuke.php?__lib=topic_favor&lite=js&noprefix&__act=topic_favor&action=add&tid=123456&pid=789012
```

#### 响应

```json
{
  "data": {
    "0": "收藏成功/已收藏..."
  },
  "time": 1601530856
}
```

---

## 2. 签到 (CheckInTask)

**源码**: `sp.phone.task.CheckInTask`

### 2.1 每日签到

| 属性 | 值 |
|------|---|
| **HTTP方法** | POST |
| **端点** | `{domain}/nuke.php?__lib=check_in&__act=check_in&lite=js` |
| **Retrofit方法** | `RetrofitService.post(url)` |

#### 请求参数

无额外参数，所有参数在URL中。

#### 请求URL示例

```
https://bbs.ngacn.cc/nuke.php?__lib=check_in&__act=check_in&lite=js
```

#### 响应

```json
{
  "data": {
    "0": "签到成功" 或 "今天已经签到"
  },
  "time": 1601530856
}
```

**客户端处理**:
- 包含 `"签到成功"` → 提示签到成功，记录签到时间
- 包含 `"今天已经签到"` → 记录签到时间
- 每日只允许签到一次（客户端通过比较日期判断）

---

## 3. 通知 (ForumNotificationTask)

**源码**: `sp.phone.task.ForumNotificationTask`

### 3.1 获取所有通知

| 属性 | 值 |
|------|---|
| **HTTP方法** | GET |
| **端点** | `{domain}/nuke.php?__lib=noti&__output=8&__act=get_all` |
| **Retrofit方法** | `RetrofitService.get(url)` |

#### 请求参数

无额外参数。

#### 请求URL示例

```
https://bbs.ngacn.cc/nuke.php?__lib=noti&__output=8&__act=get_all
```

#### 响应

```json
{
  "data": {
    "0": {
      "0": [
        {
          "0": 1,           // 通知类型 (见通知类型常量)
          "1": "100001",    // 用户ID
          "2": "用户名",     // 用户名
          "5": "主题标题",   // 主题标题
          "6": "123456",    // 主题ID (tid)
          "7": "789012",    // 回复ID (pid) (部分类型)
          "8": "789012",    // 回复ID (pid) (备用)
          "9": "1601530856" // 时间戳
        }
      ],
      "1": [
        {
          "0": 10,          // 通知类型 (10=新私信, 11=私信回复)
          "2": "用户名"      // 用户名
        }
      ],
      "unread": 5            // 未读数量
    }
  }
}
```

**通知数据字段说明**:

**数组"0"** — 回复/评论/@通知 (RecentReplyInfo，继承自 NotificationInfo):

> **继承关系**: `RecentReplyInfo extends NotificationInfo`  
> 父类 NotificationInfo 字段: `userId`(String), `timeStamp`(String), `unread`(boolean), `type`(int), `userName`(String)  
> 子类新增字段: `title`(String), `pidStr`(String), `tidStr`(String)

| 索引 | 类型 | 描述 | 所属类 |
|------|------|------|--------|
| `0` | int | 通知类型 (1=主题回复, 2=回复回复, 3=主题评论, 4=回复评论, 7=主题@, 8=回复@) | NotificationInfo |
| `1` | string | 用户ID | NotificationInfo |
| `2` | string | 用户名 | NotificationInfo |
| `5` | string | 主题标题 | RecentReplyInfo |
| `6` | string | 主题ID (tid) | RecentReplyInfo |
| `7` | string | 回复ID (pid) (可选) | RecentReplyInfo |
| `8` | string | 回复ID (pid) (备用) | RecentReplyInfo |
| `9` | string | 时间戳 | NotificationInfo |

**数组"1"** — 私信通知 (NotificationInfo):

> NotificationInfo 完整字段: `type`(int), `userName`(String), `userId`(String), `timeStamp`(String), `unread`(boolean)

| 索引 | 类型 | 描述 | 所属类 |
|------|------|------|--------|
| `0` | int | 通知类型 (10=新私信, 11=私信回复) | NotificationInfo |
| `2` | string | 用户名 | NotificationInfo |

---

### 3.2 清除所有通知

| 属性 | 值 |
|------|---|
| **HTTP方法** | POST |
| **端点** | `{domain}/nuke.php?__lib=noti&raw=3&__act=del` |
| **Retrofit方法** | `RetrofitService.post(url)` |

#### 请求URL示例

```
https://bbs.ngacn.cc/nuke.php?__lib=noti&raw=3&__act=del
```

#### 响应

无特定解析，客户端仅记录日志。

---

## 4. 赞/踩 (LikeTask)

**源码**: `sp.phone.task.LikeTask`

### 4.1 对帖子赞或踩

| 属性 | 值 |
|------|---|
| **HTTP方法** | POST |
| **端点** | `nuke.php` |
| **Retrofit方法** | `RetrofitService.post(Map)` (表单POST) |

#### 请求参数 (Form Fields)

| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `__lib` | string | 是 | `"topic_recommend"` |
| `__act` | string | 是 | `"add"` |
| `raw` | string | 是 | `"3"` |
| `pid` | string | 是 | 回复ID (默认`"0"`) |
| `__output` | string | 是 | `"8"` |
| `value` | string | 是 | `"1"`=赞, `"-1"`=踩 |
| `tid` | string | 是 | 主题ID |

**参数构造源码** (`LikeTask.java:36-47`):
```java
mParamMap.put("__lib", "topic_recommend");
mParamMap.put("__act", "add");
mParamMap.put("raw", "3");
mParamMap.put("pid", "0");
mParamMap.put("__output", "8");
// 动态:
map.put("value", String.valueOf(like));  // 1 或 -1
map.put("tid", String.valueOf(tid));
map.put("pid", String.valueOf(pid));
```

#### 请求Body示例

**赞主题**:
```
__lib=topic_recommend&__act=add&raw=3&__output=8&value=1&tid=123456&pid=0
```

**踩回复**:
```
__lib=topic_recommend&__act=add&raw=3&__output=8&value=-1&tid=123456&pid=789012
```

#### 响应

```json
{
  "data": {
    "0": "操作结果消息 (如: 推荐成功/已经推荐过...)"
  }
}
```

---

## 5. 修改签名 (SignPostTask)

**源码**: `sp.phone.task.SignPostTask`

### 5.1 设置用户签名

| 属性 | 值 |
|------|---|
| **HTTP方法** | POST |
| **端点** | `nuke.php` |
| **Retrofit方法** | `RetrofitService.post(Map)` (表单POST) |

#### 请求参数 (Form Fields)

| 参数名 | 类型 | 必填 | 编码 | 描述 |
|--------|------|------|------|------|
| `__lib` | string | 是 | - | `"set_sign"` |
| `__act` | string | 是 | - | `"set"` |
| `raw` | string | 是 | - | `"3"` |
| `lite` | string | 是 | - | `"js"` |
| `charset` | string | 是 | - | `"gbk"` |
| `uid` | string | 是 | - | 用户ID |
| `sign` | string | 是 | GBK URL编码 | 签名内容 |

**参数构造源码** (`SignPostTask.java:31-49`):
```java
mParamMap.put("__lib", "set_sign");
mParamMap.put("__act", "set");
mParamMap.put("raw", "3");
mParamMap.put("lite", "js");
mParamMap.put("charset", "gbk");
// 动态:
mParamMap.put("uid", postParam.getUid());
mParamMap.put("sign", URLEncoder.encode(sign, "gbk"));
```

#### 响应

成功时包含 `"操作成功"` 字符串。

---

## 6. 搜索版面 (SearchBoardTask)

**源码**: `sp.phone.task.SearchBoardTask`

### 6.1 按名称搜索版面

| 属性 | 值 |
|------|---|
| **HTTP方法** | GET |
| **端点** | `http://bbs.nga.cn/forum.php` |
| **Retrofit方法** | `RetrofitService.get(url)` |

> 注意: 此接口使用 `http://bbs.nga.cn` 域名，而非默认域名。

#### 请求参数 (Query Parameters)

| 参数名 | 类型 | 必填 | 编码 | 描述 |
|--------|------|------|------|------|
| `__output` | string | 是 | - | `"8"` |
| `key` | string | 是 | GBK URL编码 | 版面名称关键字 |

#### 请求URL示例

```
http://bbs.nga.cn/forum.php?&__output=8&key=%B0%E6%C3%E6
```

#### 响应

```json
{
  "data": {
    "0": {
      "fid": 650,
      "name": "版面名称"
    }
  }
}
```

---

## 7. 订阅/取消子版面 (SubscribeSubBoardTask)

**源码**: `sp.phone.task.SubscribeSubBoardTask`

### 7.1 订阅子版面

| 属性 | 值 |
|------|---|
| **HTTP方法** | POST |
| **端点** | `http://bbs.ngacn.cc/nuke.php?__lib=user_option&__act=set&raw=3` |
| **Retrofit方法** | `RetrofitService.post(url)` |

#### 请求参数 (Query Parameters，拼接在URL中)

| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `__lib` | string | 是 | `"user_option"` |
| `__act` | string | 是 | `"set"` |
| `raw` | string | 是 | `"3"` |
| `type` | string | 是 | 子版面类型 (SubBoard.type) |
| `__output` | string | 是 | `"8"` |
| `fid` | string | 是 | 父版面ID (SubBoard.parentFidStr) |
| `{action}` | string | 是 | `"add"` 或 `"del"` (键名为操作名，值为子版面fid) |

**URL构造逻辑** (`SubscribeSubBoardTask.java:81-93`):
```java
String action = getAction(type, isSubscribe);
String parentFid = subBoard.getParentFidStr();
String fid = type == 1 ? subBoard.getTidStr() : String.valueOf(subBoard.getFid());

// type=1 时操作反转: 订阅=del, 取消=add
// 其他type: 订阅=add, 取消=del
String url = String.format(
    "http://bbs.ngacn.cc/nuke.php?__lib=user_option&__act=set&raw=3&type=%s&__output=8&fid=%s&%s=%s",
    type, parentFid, action, fid);
```

#### 请求URL示例

**订阅子版面** (type=2, action=add):
```
http://bbs.ngacn.cc/nuke.php?__lib=user_option&__act=set&raw=3&type=2&__output=8&fid=650&add=123
```

**取消订阅子版面** (type=2, action=del):
```
http://bbs.ngacn.cc/nuke.php?__lib=user_option&__act=set&raw=3&type=2&__output=8&fid=650&del=123
```

> **type=1 时的操作反转**: 订阅操作使用 `action=del`，取消订阅使用 `action=add`（与其他type相反）。

#### 响应

成功时包含 `"成功"` 字符串。

---

## 8. 获取用户档案 (JsonProfileLoadTask)

**源码**: `sp.phone.task.JsonProfileLoadTask`

### 8.1 获取用户资料

| 属性 | 值 |
|------|---|
| **HTTP方法** | GET |
| **端点** | `{domain}/nuke.php?__lib=ucp&__act=get&lite=js&noprefix` |
| **Retrofit方法** | `RetrofitService.get(url, headers)` |

#### 请求参数 (Query Parameters)

| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `__lib` | string | 是 | `"ucp"` |
| `__act` | string | 是 | `"get"` |
| `lite` | string | 是 | `"js"` |
| `noprefix` | - | 是 | 去除前缀 |
| `{额外参数}` | string | 否 | 如 `uid=100001` 查看他人档案 |

#### 请求头

```
Referer: {domain}/nuke.php?func=ucp&lite=jsx&{额外参数}
```

#### 请求URL示例

```
https://bbs.ngacn.cc/nuke.php?__lib=ucp&__act=get&lite=js&noprefix&uid=100001
```

#### 响应 (ProfileData)

```json
{
  "data": {
    "0": {
      "money": "金币数",
      "fame": "声望",
      "posts": "发帖数",
      "email": "邮箱",
      "phone": "手机",
      "username": "用户名",
      "uid": "用户ID",
      "group": "用户组",
      "ipLoc": "IP属地",
      "verified": -1,
      "regdate": "注册日期(Unix时间戳)",
      "sign": "签名内容",
      "avatar": "头像URL",
      "muteTime": "禁言截止时间",
      "buffs": {
        "0": "禁言buff描述"
      },
      "reputation": {
        "0": { "0": "威望类型", "1": "威望值" }
      },
      "adminForums": {
        "版面ID": "版面名称"
      }
    }
  }
}
```

**ProfileData 字段**:

| 字段 | 类型 | 描述 |
|------|------|------|
| `money` | String | 金币数量 |
| `fame` | String | 声望 |
| `frame` | String | 头像边框 (JSON字段名"fame") |
| `postCount` | String | 发帖数 |
| `emailAddress` | String | 邮箱 |
| `phoneNumber` | String | 手机号 |
| `userName` | String | 用户名 |
| `uid` | String | 用户ID |
| `memberGroup` | String | 用户组 |
| `ipLoc` | String | IP属地 |
| `registerDate` | String | 注册日期 (已转换格式) |
| `sign` | String | 签名 |
| `avatarUrl` | String | 头像URL |
| `nuked` | boolean | 是否被Nuked (verified==-1) |
| `muted` | boolean | 是否被禁言 |
| `mutedTime` | String | 禁言截止时间 |
| `reputationEntryList` | List\<ReputationData\> | 威望列表 |
| `adminForums` | List\<AdminForumsData\> | 管理的版面列表 |

---

## 9. 举报 (ReportTask)

**源码**: `sp.phone.task.ReportTask`

### 9.1 举报帖子

| 属性 | 值 |
|------|---|
| **HTTP方法** | POST |
| **端点** | `nuke.php` |
| **Retrofit方法** | `RetrofitService.post(queryMap, fieldMap)` |

#### 请求参数

分为 queryMap 和 fieldMap 两部分，具体参数由调用方构造。

**响应** (ResultBean):

```json
// 成功
{
  "data": { "0": "操作成功" },
  "time": 1601530856
}

// 失败
{
  "error": { "0": "你在217秒后方可举报" },
  "time": 1601530856
}
```

---

## 10. 获取所有版面列表 (GetAllForumsTask)

**源码**: `sp.phone.task.GetAllForumsTask`

### 10.1 获取版面分类树

| 属性 | 值 |
|------|---|
| **HTTP方法** | GET |
| **端点** | `{domain}/app_api.php?__lib=home&__act=category` |
| **实现** | `HttpUtil.getHtml()` (原生HttpURLConnection) |

> 注意: 使用独立的 `HttpUtil.getHtml()` 方法，而非 Retrofit。

#### 请求参数

无额外参数，全部在URL中。

#### 请求URL示例

```
https://bbs.ngacn.cc/app_api.php?__lib=home&__act=category
```

#### 响应 (ForumsListModel)

```json
{
  "code": 0,
  "msg": "success",
  "result": [
    {
      "id": "分类ID",
      "name": "分类名称",
      "groups": [
        {
          "id": "组ID",
          "name": "组名称",
          "forums": [
            {
              "id": 650,
              "name": "版面名称",
              "stid": 0
            }
          ]
        }
      ]
    }
  ]
}
```

**数据层级**: `Result[]` → `Group[]` → `Forum[]`

| 层级 | 字段 | 类型 | 描述 |
|------|------|------|------|
| Result | `id` | String | 分类ID |
| Result | `name` | String | 分类名称 |
| Group | `id` | String | 组ID |
| Group | `name` | String | 组名称 |
| Forum | `id` | int | 版面ID |
| Forum | `name` | String | 版面名称 |
| Forum | `stid` | int | 子版面ID (0表示无子版面) |

---

## 11. 上传头像 (AvatarFileUploadTask)

**源码**: `sp.phone.task.AvatarFileUploadTask`

### 11.1 上传头像图片

| 属性 | 值 |
|------|---|
| **HTTP方法** | POST |
| **端点** | `http://app.myauth.us/api/attach.php?` |
| **Content-Type** | multipart/form-data |

> 注意: 使用独立的上传服务器域名，且为 HTTP 协议。

#### 请求参数 (Multipart Form Data)

| 字段名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `v2` | string | 是 | `"1"` |
| `attachment_file1_watermark` | string | 是 | 水印 (空) |
| `attachment_file1_dscp` | string | 是 | 描述 (空) |
| `attachment_file1_url_utf8_name` | string | 是 | 文件名 |
| `fid` | string | 是 | 固定值 `"-7"` |
| `func` | string | 是 | `"upload"` |
| `attachment_file1_img` | string | 是 | `"1"` |
| `origin_domain` | string | 是 | NGA域名 |
| `lite` | string | 是 | `"js"` |
| `attachment_file1` | file | 是 | 头像图片文件 |

**图片限制**: 宽度 ≤ 255px, 高度 ≤ 180px，超出自动压缩。

#### 响应

```json
{
  "error": false,
  "errorinfo": "",
  "data": "头像URL"
}
```

**错误响应**:
```json
{
  "error": true,
  "errorinfo": "错误信息"
}
```

---

## 12. WebView JavaScript桥接 (ProxyBridge)

**源码**: `sp.phone.proxy.ProxyBridge`

### 12.1 投票等WebView内操作

| 属性 | 值 |
|------|---|
| **触发** | JavaScript调用 `postURL(url)` |
| **HTTP方法** | POST |
| **端点** | `{domain}/nuke.php?{params}` |

WebView中的投票等操作通过 JavaScript 接口 `ProxyBridge.postURL(url)` 代理发送POST请求。参数由 WebView 中的 JavaScript 构造。

> **注意**: 参数同时通过 URL query string 和 POST body 传递。源码中 `url = host + "nuke.php?" + params[0]` 构造完整URL，同时 `c.post_body(params[0])` 将相同参数作为POST body发送（`ProxyBridge.java:63-69`）。

**请求URL示例**:
```
https://bbs.ngacn.cc/nuke.php?投票参数...
```

**响应**: JSON格式，解析 `data.0` 或 `error.0` 字段。
