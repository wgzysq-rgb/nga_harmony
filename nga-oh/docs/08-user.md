# 08 用户资料

## 获取用户资料

```
GET {domain}/nuke.php?__lib=ucp&__act=get&lite=js&noprefix&uid={uid}
```

| 参数 | 说明 |
|------|------|
| `__lib` | `ucp` |
| `__act` | `get` |
| `uid` | 用户 ID |

### 请求头

```
Referer: {domain}/nuke.php?func=ucp&lite=jsx&uid={uid}
```

---

## 按用户名查看资料

```
GET {domain}/nuke.php?func=ucp&username={username}
```

> 此接口返回网页 HTML，非 JSON。

---

## 用户资料数据模型

```typescript
interface ProfileData {
  // --- 基本信息 ---
  uid: string           // 用户 ID
  userName: string      // 用户名
  avatarUrl: string     // 头像 URL
  ipLoc: string         // IP 属地

  // --- 联系方式 ---
  emailAddress: string  // 邮箱
  phoneNumber: string   // 手机号

  // --- 论坛数据 ---
  postCount: string     // 发帖数
  money: string         // 金钱
  frame: string         // 头像框
  memberGroup: string   // 会员组

  // --- 时间 ---
  registerDate: string  // 注册日期

  // --- 个性化 ---
  sign: string          // 签名

  // --- 状态 ---
  muted: boolean        // 是否被禁言
  mutedTime: string     // 禁言到期时间
  nuked: boolean        // 是否被核爆

  // --- 管理信息 ---
  adminForums: AdminForumsData[]     // 管理的板块列表
  reputationEntryList: ReputationData[] // 声望记录
}
```

---

## AdminForumsData — 管理的板块

```typescript
interface AdminForumsData {
  fid: string        // 板块 ID
  forumName: string  // 板块名称
}
```

## ReputationData — 声望记录

```typescript
interface ReputationData {
  name: string  // 声望来源
  data: string  // 声望数据/数值
}
```

---

## 修改签名

```
POST {domain}/nuke.php?
```

### 请求参数

| 字段 | 说明 |
|------|------|
| `__lib` | `set_sign` |
| `__act` | `set` |
| `raw` | `3` |
| `lite` | `js` |
| `charset` | `gbk` |
| `uid` | 用户 ID |
| `sign` | 签名内容 |

---

## 头像 URL 缓存

原项目在获取帖子内容时会缓存用户头像 URL（`UserManagerImpl.putAvatarUrl`），避免重复请求。

- 缓存位置：独立 SharedPreferences（key: `PREFERENCE_AVATAR`）
- 缓存格式：`userId → avatarUrl` 的键值对
- 头像 URL 格式：`https://img.nga.178.com/avatars/{avatarUrl}`

> 注意：头像 URL 也存储在 User 实体的 `avatarUrl` 字段中（Room 数据库 `avatar_url` 列），
> 但运行时的头像缓存使用独立的 SharedPreferences，两者相互补充。
