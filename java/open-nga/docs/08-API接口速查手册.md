# Open-NGA API 接口速查手册

> 基于源码: api/open-nga  
> 生成日期: 2026-04-17

---

## 1. 服务器域名

| 域名 | 用途 |
|------|------|
| `https://bbs.ngacn.cc` | 主站 (默认) |
| `https://nga.178.com` | 备用域名 |
| `http://bbs.nga.cn` | 搜索版面 |
| `http://bbs.ngacn.cc` | 订阅子版面 (HTTP) |
| `https://img8.nga.cn` | 附件上传 |
| `http://app.myauth.us` | 头像上传 |
| `http://img.nga.178.com` | 附件CDN |

---

## 2. 认证

**方式**: Cookie  
**格式**: `ngaPassportUid={uid}; ngaPassportCid={cid}`  
**注入**: OkHttp拦截器自动附加到所有请求

---

## 3. API 端点速查表

| # | 功能 | 方法 | 端点 | 参数 |
|---|------|------|------|------|
| 1 | 获取验证码 | GET | `/login_check_code.php?id={rid}/` | id=随机标识 |
| 2 | 用户登录 | POST | `/nuke.php?__lib=login&__act=login&raw=3` | multipart: name,type,password,rid,captcha等 |
| 3 | 获取主题列表 | GET | `/thread.php` | fid/stid,page,authorid,key,favor,recommend,lite=js,noprefix |
| 4 | 获取帖子内容 | GET | `/read.php` | tid,pid,authorid,page,__output=8,noprefix,v2 |
| 5 | 获取发帖预检 | POST | `/post.php` | fid,lite=js,action,tid,pid,stid |
| 6 | 获取主题分类 | GET | `/nuke.php` | __lib=topic_key,__act=get,fid,__output=8 |
| 7 | 上传附件 | POST | `https://img8.nga.cn/attach.php` | multipart: attachment_file1,fid,auth,func=upload等 |
| 8 | 发帖/回复 | POST | `/post.php` | form: step=2,post_content,action,tid,fid等(GBK编码) |
| 9 | 发表贴条 | POST | `/post.php` | form: post_content,tid,pid,fid,action=reply,comment=1等(GBK) |
| 10 | 获取私信列表 | GET | `/nuke.php` | __lib=message,__act=message,page,lite=js |
| 11 | 读取私信 | GET | `/nuke.php` | __lib=message,__act=message,act=read,page,mid,lite=js |
| 12 | 发送私信 | POST | `/nuke.php` | form: __lib=message,__act=message,act,to,mid,subject,content(GBK) |
| 13 | 收藏主题 | POST | `/nuke.php` | __lib=topic_favor,__act=topic_favor,action=add,tid,pid,lite=js,noprefix |
| 14 | 删除收藏 | POST | `/nuke.php` | __lib=topic_favor,__act=topic_favor,action=del,tidarray,page,__output=8 |
| 15 | 签到 | POST | `/nuke.php` | __lib=check_in,__act=check_in,lite=js |
| 16 | 获取通知 | GET | `/nuke.php` | __lib=noti,__output=8,__act=get_all |
| 17 | 清除通知 | POST | `/nuke.php` | __lib=noti,raw=3,__act=del |
| 18 | 赞/踩 | POST | `/nuke.php` | form: __lib=topic_recommend,__act=add,raw=3,__output=8,value,tid,pid |
| 19 | 修改签名 | POST | `/nuke.php` | form: __lib=set_sign,__act=set,raw=3,lite=js,charset=gbk,uid,sign |
| 20 | 搜索版面 | GET | `/forum.php` | __output=8,key(GBK编码) |
| 21 | 订阅子版面 | POST | `/nuke.php` | __lib=user_option,__act=set,raw=3,__output=8,type,fid,add/del |
| 22 | 获取用户档案 | GET | `/nuke.php` | __lib=ucp,__act=get,lite=js,noprefix,uid |
| 23 | 举报 | POST | `/nuke.php` | queryMap + fieldMap |
| 24 | 获取版面树 | GET | `/app_api.php` | __lib=home,__act=category |
| 25 | 上传头像 | POST | `http://app.myauth.us/api/attach.php` | multipart: fid=-7,func=upload等 |
| 26 | WebView桥接 | POST | `/nuke.php` | 由JS构造的参数 |

---

## 4. 通用请求头

```
Cookie: ngaPassportUid={uid}; ngaPassportCid={cid}
User-Agent: {WebView默认UserAgent}
X-User-Agent: Nga_Official
Accept-Charset: GBK  (HttpPostClient/HttpUtil原生客户端使用，非Retrofit拦截器注入)
```

**登录请求特有头**:
```
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ...
Referer: https://bbs.ngacn.cc/nuke.php?__lib=login&__act=login_ui
Origin: https://bbs.ngacn.cc
```

---

## 5. 编码规则

| 场景 | 编码 |
|------|------|
| 响应解码 | GBK (JsonStringConvertFactory处理) |
| POST请求体 (发帖/私信/评论) | GBK URL编码 |
| 搜索关键字 (thread.php) | UTF-8 URL编码 |
| 搜索版面名 (forum.php) | GBK URL编码 |
| 登录请求 | Multipart (字段值为原始字符串) |

---

## 6. 通用响应格式

**前缀**: `window.script_muti_get_var_store=` (需移除)

**成功**:
```json
{ "data": { "0": "结果消息" }, "time": 1601530856 }
```

**失败**:
```json
{ "error": { "0": "错误消息" }, "time": 1601530856 }
```

**特殊**: 登录和发帖返回 HTML 页面，非 JSON。

---

## 7. 通知类型枚举

| 值 | 描述 |
|---|------|
| 1 | 主题被回复 |
| 2 | 回复被回复 |
| 3 | 主题被评论(贴条) |
| 4 | 回复被评论(贴条) |
| 7 | 在主题中被@ |
| 8 | 在回复中被@ |
| 10 | 新私信 |
| 11 | 私信被回复 |

---

## 8. 常用操作类型值

| action值 | 描述 |
|----------|------|
| `new` | 发新主题/新私信 |
| `reply` | 回复主题/回复私信/发贴条(comment=1) |
| `modify` | 修改帖子 |
| `add` | 添加收藏/赞/订阅 |
| `del` | 删除收藏/取消订阅/清除通知 |
| `read` | 读取私信 |
| `get` | 获取数据(分类/档案) |
| `set` | 设置数据(签名/子版面订阅) |

**func参数值**:

| func值 | 描述 |
|--------|------|
| `upload` | 上传文件 |

---

## 9. 参数名速查

### 通用控制参数

| 参数 | 值 | 描述 |
|------|---|------|
| `lite` | `js` | 返回JSON格式 |
| `__output` | `8` | 输出格式版本 |
| `noprefix` | - | 去除window.script_muti_get_var_store前缀 |
| `raw` | `3` | 原始数据模式 |
| `v2` | - | V2版本API |
| `__inchst` | `UTF-8` | 输入字符集 |
| `charset` | `gbk` | 请求字符集 |
| `__lib` | - | 库标识（nuke.php 接口必传） |
| `__act` | - | 动作标识（nuke.php 接口必传） |
| `func` | `upload` | 功能标识 |
| `step` | `2` | 步骤标识（发帖时固定值2） |
| `comment` | `1` | 评论标记（贴条时固定值1） |
| `nojump` | `1` | 不跳转标记（贴条时固定值1） |

### 核心标识参数

| 参数 | 描述 |
|------|------|
| `fid` | 版面ID |
| `stid` | 子版面ID |
| `tid` | 主题ID |
| `pid` | 回复ID |
| `mid` | 私信会话ID |
| `uid` | 用户ID |
| `authorid` | 作者ID |
| `action` | 操作类型 |
| `fidgroup` | 版面组 |
| `favor` | 收藏标记 |
| `recommend` | 推荐精华标记 |
| `searchpost` | 搜索帖子标记 |
| `page` | 页码 |

### 内容参数

| 参数 | 编码 | 描述 |
|------|------|------|
| `post_content` | GBK | 帖子内容(BBCode) |
| `post_subject` | GBK | 主题标题 |
| `content` | GBK | 私信内容 |
| `subject` | GBK | 私信主题 |
| `sign` | GBK | 签名 |
| `key` | UTF-8/GBK | 搜索关键字 |
| `author` | GBK | 作者名 |
| `to` | GBK | 私信收件人 |
| `tidarray` | - | 主题ID数组（删除收藏时使用） |
