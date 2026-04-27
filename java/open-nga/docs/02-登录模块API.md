# Open-NGA 登录模块 API 文档

> 模块: 登录认证  
> 源码目录: `sp.phone.mvp.model.LoginModel`  
> 源码目录: `sp.phone.mvp.contract.LoginContract`  
> 源码目录: `sp.phone.param.LoginParam`

---

## 1. 模块概述

登录模块负责两件事：
1. 加载验证码图片
2. 提交用户名/密码/验证码进行登录

> **重要**: 验证码请求和登录请求使用不同的 RetrofitService 实例。验证码通过 `RetrofitHelper.getAuthCodeService()` 获取实例，登录通过 `RetrofitHelper.getDefault()` 获取实例。两者可能具有不同的 OkHttp 拦截器配置。

登录成功后，服务器返回的 Cookie 中包含 `ngaPassportUid`、`ngaPassportCid` 和 `ngaPassportUrlencodedUname`，由客户端解析并持久化存储。

---

## 2. API 接口详情

### 2.1 获取验证码图片

| 属性 | 值 |
|------|---|
| **用途** | 获取登录验证码图片 |
| **HTTP方法** | GET |
| **端点** | `https://bbs.ngacn.cc/login_check_code.php` |
| **Retrofit方法** | `RetrofitService.getAuthCodeImage(url)` |

#### 2.1.1 请求参数 (Query Parameters)

| 参数名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `id` | string | 是 | 随机生成的Cookie标识符，格式为 `_{Math.random()}` |

#### 2.1.2 请求头

```
Referer: https://bbs.ngacn.cc/nuke.php?__lib=login&__act=login_ui
Cookie: (由OkHttpClient拦截器自动注入，此处为空)
User-Agent: (WebView默认UA)
X-User-Agent: Nga_Official
```

#### 2.1.3 请求URL构造

```java
// LoginModel.java:37-38
String cookie = "_" + Math.random();
String url = "https://bbs.ngacn.cc/login_check_code.php?id=" + cookie + "/";
```

**完整URL示例**:
```
https://bbs.ngacn.cc/login_check_code.php?id=_0.123456789/
```

#### 2.1.4 响应

| 属性 | 值 |
|------|---|
| **Content-Type** | image/png |
| **响应体** | 验证码图片二进制数据 |

**客户端处理**:
1. 读取 ResponseBody 字节流
2. Base64 编码为字符串
3. 构造 Data URL: `data:image/png;base64,{base64String}`
4. 保存 `id` 参数值作为 `authCodeCookie`，登录时需要传回

#### 2.1.5 返回数据结构 (客户端构造)

```java
LoginParam {
    authCodeCookie = "_0.123456789"    // 验证码请求ID，登录时作为rid参数
    dataUrl = "data:image/png;base64,..." // Base64编码的验证码图片
}
```

---

### 2.2 用户登录

| 属性 | 值 |
|------|---|
| **用途** | 用户名密码登录 |
| **HTTP方法** | POST |
| **端点** | `https://bbs.ngacn.cc/nuke.php` |
| **Content-Type** | multipart/form-data |
| **Retrofit方法** | `RetrofitService.login(MultipartBody)` |

#### 2.2.1 请求头

```
Referer: https://bbs.ngacn.cc/nuke/p2.htm?login
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryklQov1cm1BhZqEM4
```

> 注意: 登录请求的 `Referer` 和 `Content-Type` 通过 RetrofitService 的 `@Headers` 注解硬编码。

#### 2.2.2 请求参数 (Multipart Form Data)

| 字段名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `name` | string | 是 | 用户名 |
| `type` | string | 是 | 固定值 `"name"` |
| `password` | string | 是 | 用户密码 (明文) |
| `rid` | string | 是 | 验证码请求ID (来自获取验证码时的 `id` 参数) |
| `captcha` | string | 是 | 验证码内容 (大写) |
| `__lib` | string | 是 | 固定值 `"login"` |
| `__act` | string | 是 | 固定值 `"login"` |
| `__output` | string | 是 | 固定值 `"1"` |
| `__inchst` | string | 是 | 固定值 `"UTF-8"` |
| `raw` | string | 是 | 固定值 `"3"` |
| `qrkey` | string | 是 | 固定值 `""` (空字符串) |

**参数构造源码** (LoginModel.java:70-81):
```java
fieldMap.put("name", loginParam.getUserName());
fieldMap.put("type", "name");
fieldMap.put("password", loginParam.getPassword());
fieldMap.put("rid", loginParam.getAuthCodeCookie());
fieldMap.put("captcha", loginParam.getAuthCode().toUpperCase());
fieldMap.put("__lib", "login");
fieldMap.put("__act", "login");
fieldMap.put("__output", "1");
fieldMap.put("__inchst", "UTF-8");
fieldMap.put("raw", "3");
fieldMap.put("qrkey", "");
```

#### 2.2.3 响应

**Content-Type**: text/html (GBK编码)

**所有响应（无论成功或失败）**:
客户端对所有响应统一执行 `ActivityUtils.showToast(s)` 以 Toast 形式展示原始响应内容。原有的 JSON 错误解析逻辑（检查 `error` 字段）已被注释掉，当前不区分成功与错误响应。

**历史错误格式（已注释）**:
```json
{
  "error": {
    "0": "错误信息描述"
  }
}
```

#### 2.2.4 Cookie 解析

登录成功后，需要从响应的 Set-Cookie 头中解析：
- `ngaPassportUid`: 用户ID
- `ngaPassportCid`: 会话凭证
- `ngaPassportUrlencodedUname`: 用户名（需经过双重 GBK URL 解码）

这三个值由 `LoginContract.Presenter.parseCookie()` 方法从 Cookie 字符串中提取。解析时将 Cookie 字符串按 `;` 分割，逐项匹配键名提取值。其中 `ngaPassportUrlencodedUname` 的值需要执行两次 `URLDecoder.decode(value, "gbk")` 才能获得正确的用户名。

---

## 3. LoginParam 数据模型

**源码位置**: `sp.phone.param.LoginParam`

| 字段 | 类型 | 描述 |
|------|------|------|
| `userName` | String | 用户名 |
| `password` | String | 密码 |
| `authCode` | String | 验证码输入值 |
| `mAuthCodeCookie` | String | 验证码请求ID (rid参数) |
| `uid` | String | 登录成功后的用户ID |
| `cid` | String | 登录成功后的会话凭证 |
| `action` | String | 操作类型 |
| `mAuthCode` | String | 验证码（冗余字段，无 getter/setter） |
| `mDataUrl` | String | 验证码图片的Data URL (base64) |

---

## 4. 时序图

```
客户端                          NGA服务器
  │                               │
  │ ① GET /login_check_code.php   │
  │    ?id=_0.123456789/          │
  │ ──────────────────────────────>│
  │                               │
  │ ② 200 OK (image/png)          │
  │ <──────────────────────────────│
  │                               │
  │ [显示验证码图片]               │
  │ [用户输入用户名/密码/验证码]   │
  │                               │
  │ ③ POST /nuke.php              │
  │    Content-Type: multipart    │
  │    Body: name, password,      │
  │          rid, captcha,        │
  │          __lib, __act, raw,   │
  │          ...                  │
  │ ──────────────────────────────>│
  │                               │
  │ ④ 200 OK (HTML)               │
  │    Set-Cookie: ngaPassportUid │
  │    Set-Cookie: ngaPassportCid │
  │ <──────────────────────────────│
  │                               │
  │ [解析Cookie, 存储用户信息]    │
```
