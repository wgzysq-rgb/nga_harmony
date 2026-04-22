# 02 认证与登录

> NGA 登录已升级为 v2 协议（2026年4月观察），v1 接口已废弃。

## 登录流程概览 (v2)

v2 登录为两步流程：

1. **生成登录会话** — 获取 `qrkey` + `hiddenkey`
2. **提交凭据** — 发送用户名密码，如果服务端要求验证码则进入 Step 3
3. **提交验证码** — 获取并填写验证码后重新提交

```
客户端                         我们的后端                        NGA
  │                              │                              │
  │  POST /api/auth/login        │                              │
  │  { username, password }      │                              │
  │─────────────────────────────>│  POST qrlogin_gen            │
  │                              │─────────────────────────────>│
  │                              │<─────────────────────────────│
  │                              │  { qrkey, hiddenkey }        │
  │                              │                              │
  │                              │  POST login (v2)             │
  │                              │  { name, password, qrkey... }│
  │                              │─────────────────────────────>│
  │                              │<─────────────────────────────│
  │                              │  需要验证码 / 登录成功          │
  │                              │                              │
  │  { needCaptcha, image }      │                              │
  │<─────────────────────────────│                              │
  │                              │                              │
  │  POST /api/auth/login        │                              │
  │  { loginToken, captcha }     │                              │
  │─────────────────────────────>│  POST login (v2 + captcha)  │
  │                              │─────────────────────────────>│
  │                              │<─────────────────────────────│
  │  { ok, token, user }         │  Set-Cookie: uid, cid        │
  │<─────────────────────────────│                              │
```

---

## Step 1：生成登录会话

```
POST https://bbs.nga.cn/nuke.php
Content-Type: multipart/form-data
```

### 请求参数（Multipart Form）

| 字段 | 值 |
|------|------|
| `__lib` | `login` |
| `__output` | `1` |
| `__act` | `qrlogin_gen` |
| `__inchst` | `UTF-8` |

### 请求头

```
Referer: https://bbs.nga.cn/nuke/account_copy.html?login
Origin: https://bbs.nga.cn
User-Agent: Mozilla/5.0 ...
```

### 响应

```json
window.script_muti_get_var_store={"data":{"0":"qrkey_value,hiddenkey_value"},"time":...}
```

解析 `data["0"]`，按逗号分隔得到 `qrkey` 和 `hiddenkey`。

---

## Step 2：提交登录

```
POST https://bbs.nga.cn/nuke.php
Content-Type: multipart/form-data
```

### 请求参数（Multipart Form）

| 字段 | 值 | 说明 |
|------|------|------|
| `__lib` | `login` | |
| `__output` | `1` | |
| `__act` | `login` | |
| `__inchst` | `UTF-8` | |
| `v2` | `1` | v2 标志 |
| `app_id` | `5004` | |
| `device` | （空） | |
| `qrkey` | Step 1 返回值 | |
| `hiddenkey` | Step 1 返回值 | |
| `name` | 用户名 | |
| `password` | 密码 | |
| `type` | `name` | |

### 响应

**成功**：从响应 Set-Cookie 提取 `ngaPassportUid` 和 `ngaPassportCid`。

**需要验证码**：

```json
{"error":{"0":"未找到登录许可"},"time":...}
```

此时需要进入 Step 3 提交验证码。

---

## 验证码 (v2)

验证码仅在登录返回需要验证码的错误后才获取，**不要预加载**。

```
GET https://bbs.nga.cn/login_check_code.php?id=login{number}&from=login
```

### 请求头

```
Referer: https://bbs.nga.cn/nuke/account_copy.html?login
```

### 参数

| 参数 | 说明 |
|------|------|
| `id` | 格式 `login{number}`（如 `login46004510046725133`） |
| `from` | 固定 `login` |

### 响应

- Content-Type: `image/png`
- 二进制图片数据
- **6 位**字母+数字混合验证码（v1 为 4 位）

### 注意

- `id` 参数格式已从 v1 的 `_0.{random}` 变为 `login{number}`
- 必须包含 `from=login` 参数
- 无尾部斜杠（v1 有）

---

## Step 3：提交验证码

```
POST https://bbs.nga.cn/nuke.php
Content-Type: multipart/form-data
```

在 Step 2 的字段基础上增加：

| 字段 | 值 | 说明 |
|------|------|------|
| `captcha` | 验证码文本（大写） | 6 位 |
| `rid` | 验证码 ID | `loginXXX` 格式 |

### 响应

成功后从 Set-Cookie 提取 `ngaPassportUid` 和 `ngaPassportCid`。

---

## 认证状态

登录成功后，所有请求通过 Cookie 认证：

```
Cookie: ngaPassportUid={uid}; ngaPassportCid={cid}
```

### User 数据模型

```typescript
interface User {
  userId: string       // 用户 ID（@PrimaryKey）
  nickName: string     // 昵称
  cid: string          // 认证令牌
  avatarUrl: string    // 头像 URL
}
```

### 多账号支持

- 使用 Room 数据库存储多个用户
- 当前活跃用户存在 SharedPreferences
- 切换账号即更换请求 Cookie

---

## v1 → v2 变更摘要

| 项目 | v1（已废弃） | v2（当前） |
|------|------------|-----------|
| 会话生成 | 无 | `qrlogin_gen` 获取 qrkey + hiddenkey |
| 验证码时机 | 页面加载时预获取 | 登录失败后按需获取 |
| 验证码 ID 格式 | `_0.{random}` | `login{number}` |
| 验证码 URL 参数 | `id={captchaId}/` | `id={captchaId}&from=login` |
| 验证码长度 | 4 字符 | 6 字符 |
| 登录标志 | 无 | `v2=1`, `app_id=5004` |
| 请求体含密码 | 是（multipart 字段） | 是（同 v1） |
