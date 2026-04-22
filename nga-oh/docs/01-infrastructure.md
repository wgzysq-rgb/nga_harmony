# 01 网络基础设施

## 可用域名

应用支持多个域名，可配置切换：

| 域名 | 备注 |
|------|------|
| `https://bbs.ngacn.cc` | 默认 |
| `https://bbs.nga.cn` | 备用 |
| `https://nga.178.com` | 备用 |
| `https://nga.donews.com` | 备用 |
| `https://ngabbs.com` | 备用 |

## 请求头

每个 Retrofit 请求自动注入（OkHttp 拦截器）：

```
Cookie: ngaPassportUid={uid}; ngaPassportCid={cid}
User-Agent: {设备 WebView UA}
X-User-Agent: Nga_Official
```

旧式 HttpURLConnection 请求（发帖、私信等 Task）额外附加：

```
Accept-Charset: GBK
Content-Type: application/x-www-form-urlencoded
```

### OkHttp Interceptor 链

```
请求 → [认证拦截器] → [编码拦截器] → [调试拦截器] → 发出
```

1. **认证拦截器**：自动附加 Cookie、User-Agent、X-User-Agent
2. **编码拦截器**：POST 请求 body 含 `charset=gbk` 时自动转为 GBK 编码
3. **调试拦截器**：记录请求日志

### 网络层双轨架构

项目中存在两套网络请求机制：

| 机制 | 用于 | 特点 |
|------|------|------|
| **Retrofit + OkHttp** | `nuke.php`、`forum.php`、验证码、通知等 | 通过拦截器自动注入认证头 |
| **旧式 HttpURLConnection** | `post.php`（发帖/评论）、`nuke.php`（发私信）、头像上传、帖子加载、资料加载 | 手动拼接 Header 和 Body |

旧式 Task 类包括：`TopicPostTask`、`MessagePostTask`、`PostCommentTask`、`JsonThreadLoadTask`、`JsonProfileLoadTask`、`AvatarFileUploadTask`。

新项目重新实现时可统一为 Retrofit 或其他现代 HTTP 客户端。

## Cookie 格式

```
ngaPassportUid={userId}; ngaPassportCid={cid}
```

- `userId`：用户数字 ID
- `cid`：认证令牌（登录后获取）

Cookie 由 `UserManagerImpl` 管理，存储在 SharedPreferences，支持多账号切换。

## 响应格式

### JS 格式（`lite=js`）

```
window.script_muti_get_var_store={"data":{...},"encode":"gbk","time":1511446433}
```

需要去掉前缀 `window.script_muti_get_var_store=` 后解析 JSON。

### JSON 格式（`__output=8`）

直接返回 JSON，无需去前缀。

### 编码

- 默认响应编码：GBK
- 部分接口支持 `__inchst=UTF-8` 指定请求编码
- 响应可能包含 `/*error fill content*/` 错误标记，需清理
- `lite=js` 响应前缀固定为 `window.script_muti_get_var_store=`，解析时需去掉此后解析 JSON

### 错误响应

```json
{"error": {"0": "错误描述文本"}}
```

部分返回：
```json
{"error_code": 9}
```

## 通用响应数据结构

大多数 API 的响应外层结构：

```json
{
  "data": {
    "__CU": { "uid": 10350496, "group_bit": 622816, "admincheck": "", "rvrc": -10 },
    "__GLOBAL": "./template/js/nga_global.xml",
    "__F": { "topped_topic": "", "sub_forums": "", "fid": 275, "name": "..." },
    "__ROWS": 2,
    ...具体数据...
  },
  "encode": "gbk",
  "time": 1511446433
}
```

| 字段 | 说明 |
|------|------|
| `__CU` | 当前用户信息（uid、用户组、威望） |
| `__GLOBAL` | 全局模板路径 |
| `__F` | 当前板块信息 |
| `__ROWS` | 总行数/总数 |
| `encode` | 编码 |
| `time` | 服务器时间戳 |

## 图片/附件域名

| 用途 | URL |
|------|-----|
| 板块图标 | `http://img4.nga.178.com/ngabbs/nga_classic/f/app/{fid}.png` |
| 子版图标 | `https://img4.nga.178.com/proxy/cache_attach/ficon/{stid}v.png` |
| 头像/附件 | `img.nga.178.com` 域 |
| 附件上传 | `https://img8.nga.cn/attach.php?` |

## 请求超时

- 连接超时：默认（OkHttp 默认值）
- 读取超时：默认
- 上传文件场景：5 分钟
