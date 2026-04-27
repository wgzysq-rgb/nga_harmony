# Open-NGA 私信模块 API 文档

> 模块: 私信 (Message)  
> 源码: `sp.phone.mvp.model.MessageDetailModel`, `sp.phone.mvp.model.MessagePostModel`  
> 参数: `sp.phone.param.MessagePostParam`  
> 任务: `sp.phone.task.MessagePostTask`  
> 解析: `sp.phone.mvp.model.convert.MessageConvertFactory`

---

## 1. 模块概述

私信模块包括：
1. 获取私信列表
2. 读取私信详情（会话消息）
3. 发送新私信 / 回复私信

---

## 2. API 接口详情

### 2.1 获取私信列表

> 注：私信列表由 MVVM 架构的 `MessageListModel` 管理，此处根据 URL 模式记录接口。

| 属性 | 值 |
|------|---|
| **用途** | 获取用户私信会话列表 |
| **HTTP方法** | GET |
| **端点** | `nuke.php` |
| **Retrofit方法** | `RetrofitService.get(Map)` |

#### 2.1.1 请求参数 (Query Parameters)

| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `__lib` | string | 是 | 固定值 `"message"` |
| `__act` | string | 是 | 固定值 `"message"` |
| `act` | string | 是 | 固定值 `"list"` |
| `page` | int | 是 | 页码 |
| `lite` | string | 是 | 固定值 `"js"` |

#### 2.1.2 请求URL示例

```
https://bbs.ngacn.cc/nuke.php?__lib=message&__act=message&page=1&lite=js
```

#### 2.1.3 响应

```json
{
  "data": {
    "0": {
      "消息ID1": {
        "mid": 123,
        "subject": "私信主题",
        "from_username": "发送者",
        "time": "1601530856",
        "lasttime": "1601531000",
        "posts": 5,
        "last_from_username": "最后回复者"
      },
      "消息ID2": { ... }
    },
    "__nextPage": 2,
    "__currentPage": 1,
    "__rowsPerPage": 20
  }
}
```

**响应字段** (MessageThreadPageInfo):

| 字段 | 类型 | 描述 |
|------|------|------|
| `mid` | int | 消息会话ID |
| `subject` | string | 私信主题 |
| `from_username` | string | 发送者用户名 |
| `time` | string | 创建时间戳 |
| `lasttime` | string | 最后回复时间戳 |
| `posts` | int | 该会话中的消息数量 |
| `last_from_username` | string | 最后回复者用户名 |

**分页字段** (MessageListInfo):

| 字段 | 类型 | 描述 |
|------|------|------|
| `__nextPage` | int | 下一页页码 |
| `__currentPage` | int | 当前页码 |
| `__rowsPerPage` | int | 每页条数 |

---

### 2.2 读取私信详情

| 属性 | 值 |
|------|---|
| **用途** | 读取指定私信会话的消息内容 |
| **HTTP方法** | GET |
| **端点** | `nuke.php` |
| **Retrofit方法** | `RetrofitService.get(Map)` |

#### 2.2.1 请求参数 (Query Parameters)

| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `__lib` | string | 是 | 固定值 `"message"` |
| `__act` | string | 是 | 固定值 `"message"` |
| `act` | string | 是 | 固定值 `"read"` |
| `page` | string | 是 | 页码 |
| `mid` | string | 是 | 消息会话ID |
| `lite` | string | 是 | 固定值 `"js"` |

**参数构造源码** (`MessageDetailModel.java:34-37, 42-43`):
```java
mParamMap.put("__lib", "message");
mParamMap.put("__act", "message");
mParamMap.put("act", "read");
mParamMap.put("lite", "js");
// 动态设置:
mParamMap.put("page", String.valueOf(page));
mParamMap.put("mid", String.valueOf(mid));
```

#### 2.2.2 请求URL示例

```
https://bbs.ngacn.cc/nuke.php?__lib=message&__act=message&act=read&page=1&mid=123&lite=js
```

#### 2.2.3 响应

```json
{
  "data": {
    "0": {
      "消息条目ID": {
        "subject": "主题",
        "content": "消息内容",
        "from": "发送者ID",
        "time": "1601530856",
        "lou": 1,
        "js_escap_avatar": "头像URL",
        "author": "发送者名",
        "yz": "0",
        "mute_time": "",
        "signature": "签名",
        "formated_html_data": ""
      }
    },
    "__nextPage": 2,
    "__currentPage": 1,
    "__TROWS": 100
  }
}
```

**MessageArticlePageInfo 字段**:

| 字段 | 类型 | 描述 |
|------|------|------|
| `subject` | string | 消息主题 |
| `content` | string | 消息内容 |
| `from` | string | 发送者ID |
| `time` | string | 时间戳 |
| `lou` | int | 楼层号 |
| `js_escap_avatar` | string | 头像URL |
| `author` | string | 发送者用户名 |
| `yz` | string | 用户状态 (负数表示已注销) |
| `mute_time` | string | 禁言时间 |
| `signature` | string | 用户签名 |
| `formated_html_data` | string | 格式化HTML数据 |

**MessageDetailInfo 字段**:

| 字段 | 类型 | 描述 |
|------|------|------|
| `__nextPage` | int | 下一页页码 |
| `__currentPage` | int | 当前页码 |
| `__alluser` | string | 会话所有参与者 |
| `__title` | string | 会话标题 |

---

### 2.3 发送私信

| 属性 | 值 |
|------|---|
| **用途** | 发送新私信或回复私信 |
| **HTTP方法** | POST |
| **端点** | `{domain}/nuke.php` |
| **Content-Type** | application/x-www-form-urlencoded |
| **实现** | `HttpPostClient` (原生HttpURLConnection) |

#### 2.3.1 请求参数 (Form Body，URL编码)

| 参数名 | 类型 | 必填 | 编码 | 描述 |
|--------|------|------|------|------|
| `__lib` | string | 是 | - | 固定值 `"message"` |
| `__act` | string | 是 | - | 固定值 `"message"` |
| `lite` | string | 是 | - | 固定值 `"js"` |
| `act` | string | 是 | - | 操作: `"new"`=新私信, `"reply"`=回复 |
| `to` | string | 条件 | GBK | 收件人 (多个用逗号分隔，GBK URL编码) |
| `mid` | int | 条件 | - | 消息会话ID (回复时必填) |
| `subject` | string | 是 | GBK | 私信主题 (GBK URL编码) |
| `content` | string | 是 | GBK | 私信内容 (GBK URL编码) |

**参数构造源码** (`MessagePostParam.toString()`):
```java
builder.append("__lib=message&__act=message&lite=js&act=")
    .append(mAction)           // "new" 或其他
    .append("&to=")
    .append(encodeUrl(recipient, "GBK"))  // 收件人，逗号分隔
    .append("&mid=")
    .append(mMid)               // 消息会话ID
    .append("&subject=")
    .append(encodeUrl(mPostSubject, "GBK"))
    .append("&content=")
    .append(encodeUrl(mPostContent, "GBK"));
```

#### 2.3.2 请求Body示例

**发送新私信**:
```
__lib=message&__act=message&lite=js&act=new&to=%D5%C5%C8%FD&mid=0&subject=%D6%F7%CC%E2&content=%C4%DA%C8%DD
```

**回复私信**:
```
__lib=message&__act=message&lite=js&act=reply&to=%D5%C5%C8%FD&mid=123&subject=Re%3A%D6%F7%CC%E2&content=%BB%D8%B8%B4%C4%DA%C8%DD
```

#### 2.3.3 响应

**Content-Type**: text/html (GBK编码)

**成功响应**:
```json
{
  "data": {
    "0": "发送完毕 ..."
  }
}
```

**错误响应**:
```json
{
  "error": {
    "0": "错误信息"
  }
}
```

**成功标识字符串**:
- `"发送完毕 ..."`
- `" @提醒每24小时不能超过50个"`
- `"操作成功"`

---

## 3. MessagePostParam 数据模型

**源码位置**: `sp.phone.param.MessagePostParam`

| 字段 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `mAction` | String | `"new"` | 操作类型 (new/reply) |
| `mMid` | int | - | 消息会话ID |
| `mPostSubject` | String | - | 私信主题 |
| `mPostContent` | String | - | 私信内容 |
| `mRecipient` | String | - | 收件人 (中英文逗号均支持，自动转换为英文逗号) |
