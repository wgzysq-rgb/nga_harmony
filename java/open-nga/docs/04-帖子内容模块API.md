# Open-NGA 帖子内容模块 API 文档

> 模块: 帖子内容 (ArticleList)  
> 源码: `sp.phone.mvp.model.ArticleListModel` (Kotlin)  
> 参数: `sp.phone.param.ArticleListParam`  
> 解析: `sp.phone.mvp.model.convert.ArticleConvertFactory`

---

## 1. 模块概述

帖子内容模块负责读取指定主题的帖子详情，包括所有回复、贴条(评论)、附件、投票、骰子、用户签名等信息。

---

## 2. API 接口详情

### 2.1 获取帖子内容

| 属性 | 值 |
|------|---|
| **用途** | 获取指定主题/回复的帖子详情 |
| **HTTP方法** | GET |
| **端点** | `{domain}/read.php` |
| **Retrofit方法** | `RetrofitService.get(url, headers)` |

#### 2.1.1 请求URL构造

**源码位置**: `ArticleListModel.kt:50-69`

```kotlin
fun getUrl(param: ArticleListParam): String {
    var url = getAvailableDomain() + "/read.php?" + "&page=" + page 
              + "&__output=8&noprefix&v2";
    if (tid != 0) url = url + "&tid=" + tid;
    if (pid != 0) url = url + "&pid=" + pid;
    if (authorId != 0) url = url + "&authorid=" + authorId;
    return url;
}
```

#### 2.1.2 请求参数 (Query Parameters)

| 参数名 | 类型 | 必填 | 默认值 | 描述 |
|--------|------|------|--------|------|
| `tid` | int | 条件必填* | - | 主题ID |
| `pid` | int | 条件必填* | - | 回复ID (跳转到指定回复) |
| `authorid` | int | 否 | 0 | 按作者ID筛选帖子 |
| `page` | int | 是 | - | 页码 |
| `__output` | string | 是 | `8` | 固定值，输出格式 |
| `noprefix` | - | 是 | - | 固定值，去除前缀 |
| `v2` | - | 是 | - | 固定值，V2版本格式 |

> *注: `tid` 和 `pid` 至少传一个。同时传入时，会跳转到 `pid` 所在的页面。

#### 2.1.3 请求URL示例

**获取主题ID=123456的第1页**:
```
https://bbs.ngacn.cc/read.php?&page=1&__output=8&noprefix&v2&tid=123456
```

**跳转到回复ID=789012**:
```
https://bbs.ngacn.cc/read.php?&page=1&__output=8&noprefix&v2&tid=123456&pid=789012
```

**只看某作者**:
```
https://bbs.ngacn.cc/read.php?&page=1&__output=8&noprefix&v2&tid=123456&authorid=100001
```

#### 2.1.4 响应

**Content-Type**: text/html (GBK编码)

响应为纯 JSON 数据（因请求URL包含 `noprefix` 参数，服务器不添加 `window.script_muti_get_var_store=` 前缀），经过 `ArticleConvertFactory` 解析后构建 `ThreadData` 对象。

**核心响应结构**:

```json
{
  "data": {
    "__ROWS": 20,
    "__R__ROWS": 20,
    "__T": {
      "主题信息对象(ThreadPageInfo)..."
    },
    "__R": {
      "0": {
        "pid": 123456,
        "tid": 789012,
        "fid": 650,
        "author": "作者名",
        "authorid": 100001,
        "content": "BBCode内容",
        "subject": "",
        "postdate": "1601530856",
        "lou": 5,
        "attachs": { ... },
        "comment": { ... },
        "vote": "投票数据",
        "from_client": "来源客户端"
      },
      "1": { ... }
    },
    "__U": {
      "100001": {
        "username": "作者名",
        "avatar": "头像URL",
        "yz": "验证状态",
        "mute_time": "禁言时间",
        "rvrc": "声望值",
        "signature": "签名内容",
        "postnum": "发帖数",
        "memberid": "用户组ID",
        "buffs": { ... }
      },
      "__GROUPS": {
        "用户组ID": { "0": "用户组名称" }
      }
    }
  }
}
```

#### 2.1.5 帖子行数据字段 (ThreadRowInfo)

**源码位置**: `sp.phone.http.bean.ThreadRowInfo`

##### 服务端直接返回的字段

| 字段 | 类型 | 描述 |
|------|------|------|
| `tid` | int | 主题ID |
| `fid` | int | 版面ID |
| `pid` | int | 回复ID |
| `author` | string | 作者名 (匿名用户会被后续流程解密替换) |
| `authorid` | int | 作者ID |
| `content` | string | 帖子内容 (BBCode格式，需经lib_core转换为HTML) |
| `subject` | string | 主题标题 |
| `postdate` | string | 发帖时间 (Unix时间戳字符串) |
| `lou` | int | 楼层号 (0=楼主) |
| `attachs` | Map\<String,Attachment\> | 附件列表 |
| `comment` | object | 贴条(评论)对象，内含以索引为key的回复数据 |
| `vote` | string | 投票数据 |
| `from_client` | string | 发帖来源客户端标识 |
| `alterinfo` | string | 编辑信息 (如 "edited by ...") |
| `score` | int | 评分 |
| `score_2` | int | 评分2 |
| `level` | string | 用户等级 (由__U填充) |
| `yz` | string | 验证状态 (由__U填充) |
| `muteTime` | string | 禁言截止时间 (由__U填充) |
| `aurvrc` | int | 声望值 (由__U填充) |
| `reputation` | float | 威望值 (由__U中rvrc/10计算) |
| `memberGroup` | string | 用户组名称 (由__U中__GROUPS填充) |
| `signature` | string | 用户签名 (由__U填充) |
| `js_escap_avatar` | string | 头像URL (由__U中avatar填充) |
| `isanonymous` | boolean | 是否匿名用户 |
| `isInBlackList` | boolean | 是否在黑名单中 (本地计算) |
| `userNote` | string | 用户备注 (本地获取) |
| `from_client_model` | string | 客户端平台识别结果 (android/ios/wp/unknown，由from_client解析) |
| `muted` | boolean | 是否被禁言 (由__U中buffs检测) |
| `postCount` | string | 发帖数量 (由__U中postnum填充) |
| `hotReplies` | list | 热门回复 (从字段"17"解析) |
| `formattedHtmlData` | string | 转换后的HTML内容 (本地转换) |
| `imageUrlList` | List\<String\> | 图片URL列表 (本地收集) |

#### 2.1.6 附件数据结构 (Attachment)

**源码位置**: `sp.phone.http.bean.Attachment`

| 字段 | 类型 | 描述 |
|------|------|------|
| `aid` | string | 附件ID |
| `attachurl` | string | 附件URL (相对路径，需拼接 `img.nga.178.com`) |
| `thumb` | string | 缩略图URL |
| `url_utf8_org_name` | string | 附件原始文件名 (UTF-8编码) |
| `dscp` | string | 附件描述 |
| `size` | int | 附件大小 |
| `ext` | string | 附件扩展名 |
| `name` | string | 附件名称 |
| `type` | string | 附件类型 |
| `subid` | int | 子ID |

---

## 3. ThreadData 数据结构

**源码位置**: `sp.phone.http.bean.ThreadData`

`ArticleConvertFactory` 解析后的最终数据对象。

| 字段 | 类型 | 描述 |
|------|------|------|
| `rowList` | List\<ThreadRowInfo\> | 当前页帖子列表 |
| `threadInfo` | ThreadPageInfo | 主题信息 |
| `__F` | Map\<String, String\> | 论坛配置信息 |
| `__ROWS` | int | 总行数 (服务端返回) |
| `rowNum` | int | 实际解析行数 (当前页帖子数) |
| `rawData` | String | 从服务端获取的原始JSON数据 |

---

## 4. ThreadPageInfo 数据结构

**源码位置**: `sp.phone.mvp.model.entity.ThreadPageInfo`

从响应中 `__T` 字段解析的主题元信息。

| 字段 | 类型 | 描述 |
|------|------|------|
| `tid` | int | 主题ID |
| `author` | String | 主题作者名 |
| `fid` | int | 版面ID |
| `authorId` | int | 主题作者ID |
| `lastPoster` | String | 最后回复者 |
| `replies` | int | 回复数 |
| `subject` | String | 主题标题 |
| `titleFont` | String | 标题字体样式 |
| `type` | int | 主题类型 |
| `topicMisc` | String | 主题附加信息 |
| `page` | int | 当前页码 |
| `pid` | int | 跳转目标回复ID |
| `position` | int | 跳转目标位置 |
| `isAnonymity` | boolean | 是否匿名主题 |
| `postDate` | int | 发帖时间 (Unix时间戳) |
| `replyInfo` | ReplyInfo | 跳转回复信息 |
| `board` | String | 所属版面名称 |
| `mirrorBoard` | boolean | 是否是版面镜像 (board=="版面镜像"时为true) |

### ReplyInfo 内嵌结构

| 字段 | 类型 | 描述 |
|------|------|------|
| `pidStr` | String | 回复ID字符串 |
| `content` | String | 回复内容 |
| `subject` | String | 回复标题 |
| `postDate` | String | 回复时间 |
| `authorId` | String | 回复作者ID |
| `tidStr` | String | 主题ID字符串 |

---

## 5. ArticleListParam 数据模型

**源码位置**: `sp.phone.param.ArticleListParam`

| 字段 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `pid` | int | 0 | 回复ID (跳转到指定回复) |
| `tid` | int | 0 | 主题ID |
| `authorId` | int | 0 | 只看此作者 |
| `page` | int | 0 | 页码 |
| `searchPost` | int | 0 | 搜索帖子标记 |
| `title` | String | null | 主题标题 |
| `content` | String | null | 内容 |
| `topicInfo` | String | null | 主题描述信息 (JSON, 用于缓存) |
| `loadCache` | boolean | false | 是否加载缓存 |

---

## 6. 帖子缓存机制

- **缓存路径**: `{appFilesDir}/cache/{tid}/{page}.json`
- **描述文件**: `{appFilesDir}/cache/{tid}/{tid}.json` (存储 topicInfo)
- **写入**: `ArticleListModel.cachePage()` 将原始JSON写入文件
- **读取**: `ArticleListModel.loadCachePage()` 从文件读取并解析

---

## 7. 数据转换流程

```
服务器响应 (GBK JSON，无前缀，因请求包含noprefix参数)
    │
    ▼
JsonStringConvertFactory (GBK解码为String)
    │
    ▼
ArticleConvertFactory.parseJsonThreadPage(js)
    │
    ├── 移除 "/*error fill content*/" 及之后的内容
    ├── 正则修复畸形JSON (移除 /*$js$*/、修复content/subject/author的数值类型错误、移除异常alterinfo)
    ├── 解析JSON，提取外层 "data" 对象
    ├── 从data中读取 __ROWS、__R__ROWS、__U(用户信息Map)、__T(主题信息)、__R(回复列表)
    │
    ▼
对每条回复 (convertJsObjToList):
    │
    ├── FastJSON反序列化为ThreadRowInfo基础字段
    ├── buildRowHotReplay: 从字段"17"解析热门回复PID列表
    ├── buildRowComment: 从字段"comment"解析贴条(评论)，递归调用convertJsObjToList
    ├── buildRowClientInfo: 解析from_client，识别客户端平台 (android/ios/wp/unknown)
    ├── buildRowUserInfo: 从__U中按authorid查找用户信息
    │   ├── 匿名用户名解密 (username以#anony_开头时，通过查表还原为汉字昵称)
    │   ├── 填充头像、验证状态、禁言时间、签名、声望
    │   ├── 计算威望 (rvrc/10)
    │   ├── 获取用户组名称 (从__U.__GROUPS)
    │   ├── 检查黑名单 (本地查询)
    │   ├── 获取用户备注 (本地查询)
    │   └── 检测禁言状态 (从buffs中检测指定buff ID)
    ├── buildRowVote: 提取投票数据
    ├── buildRowContent: BBCode转HTML
    │   ├── 处理内容为空时用subject替代
    │   ├── WP客户端内容反转义
    │   ├── 构建HtmlData (含附件、评论、签名等)
    │   ├── HtmlConvertFactory.convert() 转换BBCode为HTML
    │   ├── 处理骰子标签 [dice]...[/dice]
    │   └── 收集图片URL列表
    │
    ▼
ThreadData 对象
    ├── rowList: List<ThreadRowInfo>  (帖子列表)
    ├── threadInfo: ThreadPageInfo    (主题信息)
    ├── __F: Map<String, String>      (论坛配置)
    ├── __ROWS: int                   (总行数)
    ├── rowNum: int                   (当前页实际行数)
    └── rawData: String               (原始JSON)
```
