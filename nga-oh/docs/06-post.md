# 06 发帖、回复、编辑与附件上传

## 获取发帖信息（auth 码）

发帖/回复/编辑前需先获取 auth 验证码，用于附件上传。

```
POST {domain}/post.php?fid={fid}&lite=js&action={action}&pid={pid}&tid={tid}&stid={stid}
```

> **注意**：此接口使用 POST 方法但**无请求体**（空 body），参数全部在 URL query string 中。

| 参数 | 说明 |
|------|------|
| `fid` | 板块 ID |
| `action` | `new`（发帖）/ `reply`（回复）/ `modify`（编辑） |
| `pid` | 帖子 ID（回复/编辑时） |
| `tid` | 主题 ID（回复/编辑时） |
| `stid` | 子板块 ID |
| `lite` | `js` |

### 响应

```json
{
  "data": {
    "action": "reply",
    "fid": 275,
    "auth": "xxxxxxxx",         // ← 附件上传必需的验证码
    "if_moderator": 0,
    "tid": "11915941",
    "__CU": {...},
    "__GLOBAL": "...",
    "__F": {...},
    "attach_url": "..."
  },
  "encode": "gbk",
  "time": 1511446433
}
```

---

## 获取主题分类标签

```
GET {domain}/nuke.php?__lib=topic_key&__act=get&fid={fid}&__output=8
```

### 响应

```json
{
  "data": {
    "0": {
      "0": "分类名称1",
      "1": "分类名称2"
    }
  }
}
```

---

## 发帖/回复/编辑

```
POST {domain}/post.php?
```

### 请求参数（Form Body）

| 字段 | 说明 |
|------|------|
| `step` | 固定 `2` |
| `action` | `new` / `reply` / `modify` |
| `fid` | 板块 ID |
| `tid` | 主题 ID（回复/编辑时） |
| `pid` | 帖子 ID（编辑时） |
| `stid` | 子板块 ID |
| `post_subject` | 主题标题（发帖时） |
| `post_content` | 帖子内容 |
| `anony` | `1` 匿名，`0` 实名 |
| `attachments` | 附件标识（上传后返回） |
| `attachments_check` | 附件校验码（上传后返回） |

> **注意**：POST body 使用 GBK 编码（`charset=gbk`）。

---

## 发表评论（针对楼层的回复）

```
POST {domain}/post.php
```

### 请求参数

| 字段 | 说明 |
|------|------|
| `post_content` | 评论内容 |
| `tid` | 主题 ID |
| `pid` | 被评论的楼层 ID |
| `fid` | 板块 ID |
| `nojump` | `1` |
| `step` | `2` |
| `action` | `reply` |
| `comment` | `1`（标识为评论） |
| `lite` | `htmljs` |
| `anony` | `0` 或 `1` |

---

## 附件上传

```
POST https://img8.nga.cn/attach.php?
```

### 请求格式

`multipart/form-data`

### 请求字段

| 字段 | 说明 |
|------|------|
| `attachment_file1` | 文件二进制数据（image/jpeg） |
| `attachment_file1_url_utf8_name` | 文件名 |
| `attachment_file1_img` | `1` |
| `attachment_file1_auto_size` | 自动缩图（空字符串） |
| `attachment_file1_watermark` | 水印位置（tl/tr/bl/br，空=无水印） |
| `attachment_file1_dscp` | 描述 |
| `fid` | 板块 ID |
| `auth` | 发帖信息接口获取的 auth 码 |
| `func` | `upload` |
| `v2` | `1` |
| `lite` | `js` |
| `origin_domain` | `bbs.ngacn.cc`（附件上传硬编码此值；头像上传使用动态域名） |

### 响应

```json
{
  "data": {
    "attachments": "xxxx",        // 附件标识
    "attachments_check": "xxxx",  // 附件校验码
    "url": "/mon_202501/xxx.jpg"  // 附件路径
  }
}
```

### 错误码

| error_code | 说明 |
|------------|------|
| `9` | 附件过大（>1MB 时需压缩重试） |

---

## 头像上传

```
POST http://app.myauth.us/api/attach.php?
```

### 请求格式

`multipart/form-data`，字段与附件上传类似，但 `fid` 固定为 `-7`。

### 头像上传接口（nuke.php）

```
POST {domain}/nuke.php?__lib=ucp&__act=save_avatar&lite=js&noprefix
```
