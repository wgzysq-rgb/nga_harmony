# NGA 论坛 API 接口与数据模型分析 — 总览

> 基于 open-nga Android 客户端源码逆向分析，用于指导新项目（不同系统/技术栈）的开发。

---

## 文档索引

| 文件 | 内容 |
|------|------|
| [01-infrastructure.md](01-infrastructure.md) | 网络基础设施：域名、HTTP 客户端、认证、编码、请求/响应格式 |
| [02-auth.md](02-auth.md) | 登录、验证码、Cookie 认证机制 |
| [03-forum.md](03-forum.md) | 板块列表、板块搜索、板块订阅 |
| [04-topic-list.md](04-topic-list.md) | 主题列表查询（按板块/作者/收藏/搜索/推荐） |
| [05-article.md](05-article.md) | 帖子详情（楼层内容、附件、评论嵌套） |
| [06-post.md](06-post.md) | 发帖、回复、编辑、评论、附件上传 |
| [07-message.md](07-message.md) | 私信列表、详情、发送 |
| [08-user.md](08-user.md) | 用户资料、头像、签名 |
| [09-notification.md](09-notification.md) | 通知获取与清除 |
| [10-misc.md](10-misc.md) | 签到、收藏、点赞/踩、搜索等杂项接口 |
| [11-data-models.md](11-data-models.md) | 全部数据模型字段定义 |

---

## 技术栈（原项目）

- **网络层**：Retrofit 2 + OkHttp 3 + 旧式 HttpURLConnection（双轨）
- **异步**：RxJava 2
- **解析**：FastJSON
- **架构**：MVP + MVVM 混合
- **本地存储**：Room（User、NoteInfo）+ SharedPreferences
- **编码**：GBK / UTF-8 双编码

## API 设计模式

NGA 的 API 并非标准 RESTful，而是基于 PHP 的统一入口路由：

| 入口文件 | 职责 |
|----------|------|
| `thread.php` | 主题列表查询 |
| `read.php` | 帖子内容读取 |
| `post.php` | 发帖/回复/编辑 |
| `nuke.php` | 通用操作路由（通过 `__lib`/`__act` 分派） |
| `app_api.php` | 移动端专用（板块分类） |
| `forum.php` | 板块搜索 |
| `attach.php` | 附件/头像上传 |

### 通用参数

| 参数 | 说明 |
|------|------|
| `lite=js` | 返回 JS 格式（`window.script_muti_get_var_store={...}`） |
| `__output=8` | 返回 JSON 格式 |
| `noprefix` | 去掉 JS 前缀 |
| `raw=3` | 原始格式 |
| `page=N` | 分页页码 |

### 数据闭环说明

通过这套 API 可以实现完整论坛功能闭环：

```
登录认证 → 板块浏览 → 主题列表 → 帖子阅读 → 发帖/回复
   ↑                                              ↓
   ←←←←← 通知/私信/收藏/签到/点赞 ←←←←←←←←←←←←←←←←←
```
