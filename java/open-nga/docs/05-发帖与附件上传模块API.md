# Open-NGA 发帖与附件上传模块 API 文档

> 模块: 发帖 (TopicPost) + 附件上传 + 贴条评论  
> 源码: `sp.phone.mvp.model.TopicPostModel`  
> 参数: `sp.phone.param.PostParam`  
> 任务: `sp.phone.task.TopicPostTask`, `sp.phone.task.PostCommentTask`

---

## 1. 模块概述

发帖模块包括以下功能：
1. 获取发帖预检信息（附件验证码 auth）
2. 获取主题分类列表
3. 上传附件（图片）
4. 发表新主题/回复
5. 发表贴条（评论）

---

## 2. API 接口详情

### 2.1 获取发帖预检信息

| 属性 | 值 |
|------|---|
| **用途** | 获取发帖前的验证信息（auth验证码，用于上传附件） |
| **HTTP方法** | POST |
| **端点** | `{domain}/post.php` |
| **Retrofit方法** | `RetrofitService.post(url)` |

#### 2.1.1 请求参数 (Query Parameters，拼接在URL中)

| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `fid` | int | 是 | 版面ID |
| `lite` | string | 是 | 固定值 `"js"` |
| `action` | string | 否 | 操作类型 (new/reply/modify 等) |
| `pid` | int | 否 | 回复ID (回复/修改时使用) |
| `tid` | int | 否 | 主题ID (回复/修改时使用) |
| `stid` | int | 否 | 子版面ID |

#### 2.1.2 请求URL构造

**源码位置**: `TopicPostModel.java:72-90`

```java
StringBuilder builder = new StringBuilder(mHostUrl); // {domain}/post.php?
builder.append("fid=").append(postParam.getPostFid()).append("&lite=js");
if (postParam.getPostAction() != null)
    builder.append("&action=").append(postParam.getPostAction());
if (postParam.getPostPid() != null)
    builder.append("&pid=").append(postParam.getPostPid());
if (postParam.getPostTid() != null)
    builder.append("&tid=").append(postParam.getPostTid());
if (postParam.getStid() != null)
    builder.append("&stid=").append(postParam.getStid());
```

#### 2.1.3 请求URL示例

**发新主题**:
```
https://bbs.ngacn.cc/post.php?fid=650&lite=js&action=new
```

**回复主题**:
```
https://bbs.ngacn.cc/post.php?fid=650&lite=js&action=reply&tid=123456
```

**修改回复**:
```
https://bbs.ngacn.cc/post.php?fid=650&lite=js&action=modify&tid=123456&pid=789012
```

#### 2.1.4 响应 (TopicPostBean)

```json
{
  "data": {
    "action": "new",
    "fid": 650,
    "auth": "附件验证码字符串",
    "if_moderator": 0,
    "tid": null,
    "__CU": {
      "uid": 100001,
      "group_bit": 0,
      "admincheck": "",
      "rvrc": 0
    },
    "__GLOBAL": "全局参数",
    "__F": {
      "bit_data": 0,
      "fid": 650,
      "name": "版面名称"
    },
    "attach_url": "附件上传URL"
  },
  "encode": "GBK",
  "time": 1601530856,
  "debug": null
}
```

**关键字段**:

| 字段路径 | 类型 | 描述 |
|---------|------|------|
| `data.auth` | string | **附件验证码** (上传附件时必须携带) |
| `data.action` | string | 操作类型 |
| `data.fid` | int | 版面ID |
| `data.if_moderator` | int | 是否版主 (0/1) |
| `data.tid` | string | 主题ID (回复时存在) |
| `data.attach_url` | string | 附件上传基础URL |
| `data.__CU.uid` | int | 当前用户ID |
| `data.__F.name` | string | 版面名称 |
| `debug` | Object | 调试信息 (通常为 null) |

---

### 2.2 获取主题分类

| 属性 | 值 |
|------|---|
| **用途** | 获取版面下的主题分类列表 |
| **HTTP方法** | GET |
| **端点** | `nuke.php` |
| **Retrofit方法** | `RetrofitService.get(Map)` |

#### 2.2.1 请求参数 (Query Parameters)

| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `__lib` | string | 是 | 固定值 `"topic_key"` |
| `__act` | string | 是 | 固定值 `"get"` |
| `fid` | string | 是 | 版面ID |
| `__output` | string | 是 | 固定值 `"8"` |

#### 2.2.2 请求URL示例

```
https://bbs.ngacn.cc/nuke.php?__lib=topic_key&__act=get&fid=650&__output=8
```

#### 2.2.3 响应

```json
{
  "data": {
    "0": {
      "0": { "0": "分类名称1" },
      "1": { "0": "分类名称2" },
      "2": { "0": "分类名称3" }
    }
  }
}
```

客户端解析为 `List<String>` 分类名称列表。

---

### 2.3 上传附件（图片）

| 属性 | 值 |
|------|---|
| **用途** | 上传图片附件到服务器 |
| **HTTP方法** | POST |
| **端点** | `https://img8.nga.cn/attach.php?` |
| **Content-Type** | multipart/form-data |
| **Retrofit方法** | `RetrofitService.uploadFile(url, MultipartBody)` |

#### 2.3.1 请求参数 (Multipart Form Data)

| 字段名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `attachment_file1` | file | 是 | 图片文件 (二进制) |
| `attachment_file1_url_utf8_name` | string | 是 | 文件UTF-8名称 |
| `fid` | string | 是 | 版面ID |
| `auth` | string | 是 | 附件验证码 (从预检接口获取) |
| `func` | string | 是 | 固定值 `"upload"` |
| `v2` | string | 是 | 固定值 `"1"` |
| `lite` | string | 是 | 固定值 `"js"` |
| `attachment_file1_auto_size` | string | 否 | 自动缩图 (空=不缩图) |
| `attachment_file1_watermark` | string | 否 | 水印位置 (tl/tr/bl/br，空=无水印) |
| `attachment_file1_dscp` | string | 否 | 附件描述 |
| `attachment_file1_img` | string | 是 | 固定值 `"1"` |
| `origin_domain` | string | 是 | 固定值 `"bbs.ngacn.cc"` |

**参数构造源码** (`TopicPostModel.java:248-266`):
```java
builder.addPart(MultipartBody.Part.createFormData(
    "attachment_file1", fileName, 
    RequestBody.create(MediaType.parse("image/jpeg"), bytes)))
.addFormDataPart("attachment_file1_url_utf8_name", new String(fileName.getBytes(), "UTF-8"))
.addFormDataPart("fid", String.valueOf(postParam.getPostFid()))
.addFormDataPart("auth", postParam.getAuthCode())
.addFormDataPart("func", "upload")
.addFormDataPart("v2", "1")
.addFormDataPart("lite", "js")
.addFormDataPart("attachment_file1_auto_size", "")
.addFormDataPart("attachment_file1_watermark", "")
.addFormDataPart("attachment_file1_dscp", "")
.addFormDataPart("attachment_file1_img", "1")
.addFormDataPart("origin_domain", "bbs.ngacn.cc");
```

#### 2.3.2 响应

```json
{
  "data": {
    "attachments": "附件标识字符串",
    "attachments_check": "附件验证字符串",
    "url": "附件预览URL"
  }
}
```

**错误响应** (附件过大):
```json
{
  "error_code": 9
}
```

**客户端处理**:
- `error_code=9` 时自动压缩图片后重新上传
- 成功后将 `attachments` 和 `attachments_check` 追加到 PostParam

---

### 2.4 发表帖子（新主题/回复）

| 属性 | 值 |
|------|---|
| **用途** | 发表新主题或回复 |
| **HTTP方法** | POST |
| **端点** | `{domain}/post.php` |
| **Content-Type** | application/x-www-form-urlencoded |
| **实现** | `HttpPostClient` (原生HttpURLConnection) |

#### 2.4.1 请求参数 (Form Body，URL编码)

| 参数名 | 类型 | 必填 | 编码 | 描述 |
|--------|------|------|------|------|
| `step` | string | 是 | - | 固定值 `"2"` |
| `post_content` | string | 是 | GBK | 帖子内容 (BBCode格式，GBK URL编码) |
| `tid` | string | 条件 | - | 主题ID (回复时必填) |
| `pid` | string | 条件 | - | 回复ID (修改时必填) |
| `action` | string | 是 | - | 操作类型: `new`=新主题, `reply`=回复, `modify`=修改 |
| `post_subject` | string | 条件 | GBK | 主题标题 (新主题时必填，GBK URL编码) |
| `fid` | int | 是 | - | 版面ID |
| `anony` | string | 否 | - | 匿名标记: `"1"`=匿名 |
| `attachments` | string | 否 | - | 附件标识 (多个用tab分隔) |
| `attachments_check` | string | 否 | - | 附件验证字符串 (多个用tab分隔) |
| `stid` | string | 否 | - | 子版面ID |

**参数构造源码** (`PostParam.toString()`):
```java
StringBuilder builder = new StringBuilder("step=2");
builder.append("&post_content=").append(encodeUrl(mPostContent, "GBK"));
if (mPostPid != null) builder.append("&pid=").append(mPostPid);
if (mPostTid != null) builder.append("&tid=").append(mPostTid);
if (mPostAction != null) builder.append("&action=").append(mPostAction);
if (mPostSubject != null) builder.append("&post_subject=").append(encodeUrl(mPostSubject, "GBK"));
if (mPostFid != 0) builder.append("&fid=").append(mPostFid);
if (mAnonymous) builder.append("&anony=1");
if (mAttachments != null)
    builder.append("&attachments=").append(mAttachments)
           .append("&attachments_check=").append(mAttachmentsCheck);
if (mStid != null) builder.append("&stid=").append(mStid);
```

#### 2.4.2 请求Body示例

**发新主题**:
```
step=2&post_content=%B2%E2%CA%D4%C4%DA%C8%DD&action=new&post_subject=%B2%E2%CA%D4%B1%EA%CC%E2&fid=650
```

**回复主题**:
```
step=2&post_content=%B2%E2%CA%D4%BB%D8%B8%B4&action=reply&tid=123456&fid=650
```

**匿名回复带附件**:
```
step=2&post_content=%C4%DA%C8%DD&action=reply&tid=123456&fid=650&anony=1&attachments=xxx&attachments_check=yyy
```

#### 2.4.3 响应

**Content-Type**: text/html (GBK编码)

**成功响应** (HTML格式):
```html
<span class='sub'>&gt;</span>发贴完毕<br/>
```

**成功标识字符串**:
- `"发贴完毕"`
- `"@提醒每24小时不能超过50个"`

**失败**: 返回HTML错误页面，客户端从中提取 `<span class='sub'>&gt;</span>` 和 `<br/>` 之间的错误消息。

---

### 2.5 发表贴条（评论）

| 属性 | 值 |
|------|---|
| **用途** | 对帖子发表评论(贴条) |
| **HTTP方法** | POST |
| **端点** | `{domain}/post.php` |
| **Content-Type** | application/x-www-form-urlencoded |
| **实现** | `HttpPostClient` (原生HttpURLConnection) |

#### 2.5.1 请求参数 (Form Body)

| 参数名 | 类型 | 必填 | 编码 | 描述 |
|--------|------|------|------|------|
| `post_content` | string | 是 | GBK | 评论内容 (GBK URL编码) |
| `tid` | int | 是 | - | 主题ID |
| `pid` | int | 是 | - | 回复ID (被评论的帖子) |
| `fid` | int | 是 | - | 版面ID |
| `nojump` | string | 是 | - | 固定值 `"1"` |
| `step` | string | 是 | - | 固定值 `"2"` |
| `action` | string | 是 | - | 固定值 `"reply"` |
| `comment` | string | 是 | - | 固定值 `"1"` (标记为评论) |
| `lite` | string | 是 | - | 固定值 `"htmljs"` |
| `anony` | string | 否 | - | `"1"`=匿名 |

**参数构造源码** (`PostCommentTask.buildBody()`):
```java
sb.append("post_content=").append(encodeUrl(comment, "GBK"));
sb.append("&tid=").append(tid);
sb.append("&pid=").append(pid);
sb.append("&fid=").append(fid);
sb.append("&nojump=1");
sb.append("&step=2");
sb.append("&action=reply");
sb.append("&comment=1");
sb.append("&lite=htmljs");
if (anonymode == 1) sb.append("&anony=1");
```

#### 2.5.2 响应

**Content-Type**: text/html (GBK编码)

实际服务器返回 HTML 页面，JSON 数据嵌入在 `window.script_muti_get_var_store=` 与 `</script>` 之间。客户端需先提取该段 JSON 再解析。

**成功响应** (HTML 内嵌 JSON):
```json
{
  "data": {
    "__MESSAGE": {
      "1": "发贴完毕",
      "3": 200
    }
  }
}
```

当 `__MESSAGE.3 == 200` 且消息包含 "发贴完毕" 时，判定为成功。

---

## 3. PostParam 数据模型

**源码位置**: `sp.phone.param.PostParam`

| 字段 | 类型 | 描述 |
|------|------|------|
| `mPostContent` | String | 帖子内容 (BBCode) |
| `mPostSubject` | String | 主题标题 |
| `mPostAction` | String | 操作类型 (new/reply/modify) |
| `mPostFid` | int | 版面ID |
| `mPostTid` | String | 主题ID |
| `mPostPid` | String | 回复ID |
| `mStid` | String | 子版面ID |
| `mAnonymous` | boolean | 是否匿名 |
| `mAuthCode` | String | 附件验证码 |
| `mAttachments` | StringBuilder | 附件标识列表 (每次追加前先追加URL编码的Tab字符 `%09`) |
| `mAttachmentsCheck` | StringBuilder | 附件验证列表 (每次追加前先追加URL编码的Tab字符 `%09`) |

---

## 4. 完整发帖流程

```
1. 获取预检信息
   POST {domain}/post.php?fid=650&lite=js&action=new
   → 获得 auth (附件验证码)

2. [可选] 上传附件
   POST https://img8.nga.cn/attach.php? (multipart)
   → 获得 attachments + attachments_check

3. 提交帖子
   POST {domain}/post.php (form-urlencoded)
   Body: step=2&post_content=...&action=new&fid=650
   → "发贴完毕"
```
