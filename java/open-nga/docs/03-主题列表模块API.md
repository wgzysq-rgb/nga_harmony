# Open-NGA 主题列表模块 API 文档

> 模块: 主题列表 (TopicList)  
> 源码: `sp.phone.mvp.model.TopicListModel`  
> 参数: `sp.phone.param.TopicListParam`  
> 解析: `sp.phone.mvp.model.convert.TopicConvertFactory`

---

## 1. 模块概述

主题列表模块负责获取论坛版面下的主题帖列表，支持多种筛选方式：按版面、按作者、按关键字搜索、收藏列表、推荐精华、24小时热帖等。

---

## 2. API 接口详情

### 2.1 获取主题列表

| 属性 | 值 |
|------|---|
| **用途** | 获取指定版面/条件的主题列表 |
| **HTTP方法** | GET |
| **端点** | `{domain}/thread.php` |
| **Retrofit方法** | `RetrofitService.get(url)` |

#### 2.1.1 请求URL构造逻辑

**源码位置**: `TopicListModel.java:220-266`

```java
private String getUrl(int page, TopicListParam requestInfo) {
    StringBuilder jsonUri = new StringBuilder(getAvailableDomain() + "/thread.php?");
    
    // 按作者筛选
    if (0 != requestInfo.authorId)
        jsonUri.append("authorid=").append(requestInfo.authorId).append("&");
    
    // 搜索帖子
    if (requestInfo.searchPost != 0)
        jsonUri.append("searchpost=").append(requestInfo.searchPost).append("&");
    
    // 收藏的主题
    if (requestInfo.favor != 0)
        jsonUri.append("favor=").append(requestInfo.favor).append("&");
    
    // 内容搜索
    if (requestInfo.content != 0)
        jsonUri.append("content=").append(requestInfo.content).append("&");
    
    // 按作者名搜索
    if (!StringUtils.isEmpty(requestInfo.author)) {
        try {
            if (requestInfo.author.endsWith("&searchpost=1")) {
                jsonUri.append("author=").append(URLEncoder.encode(
                        requestInfo.author.substring(0, requestInfo.author.length() - 13),
                        "GBK")).append("&searchpost=1&");
            } else {
                jsonUri.append("author=").append(URLEncoder.encode(requestInfo.author, "GBK")).append("&");
            }
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
    } else {
        // 按版面筛选 (stid优先于fid)
        if (requestInfo.stid != 0)
            jsonUri.append("stid=").append(requestInfo.stid).append("&");
        else if (0 != requestInfo.fid)
            jsonUri.append("fid=").append(requestInfo.fid).append("&");
        // 关键字搜索
        if (!StringUtils.isEmpty(requestInfo.key))
            jsonUri.append("key=").append(StringUtils.encodeUrl(requestInfo.key, "UTF-8")).append("&");
        // 版面组
        if (!StringUtils.isEmpty(requestInfo.fidGroup))
            jsonUri.append("fidgroup=").append(requestInfo.fidGroup).append("&");
    }
    
    // 分页 + 固定参数
    jsonUri.append("page=").append(page).append("&lite=js&noprefix");
    
    // 推荐精华
    if (requestInfo.recommend == 1)
        jsonUri.append("&recommend=1&order_by=postdatedesc&user=1");
    
    return jsonUri.toString();
}
```

#### 2.1.2 请求参数 (Query Parameters)

| 参数名 | 类型 | 必填 | 默认值 | 描述 |
|--------|------|------|--------|------|
| `fid` | int | 条件必填* | - | 版面ID (与stid互斥) |
| `stid` | int | 条件必填* | - | 子版面ID (优先于fid) |
| `authorid` | int | 否 | 0 | 按作者ID筛选 |
| `author` | string(GBK编码) | 否 | - | 按作者名搜索 (与fid/stid互斥) |
| `key` | string(UTF-8编码) | 否 | - | 搜索关键字 |
| `searchpost` | int | 否 | 0 | 搜索帖子标记 |
| `favor` | int | 否 | 0 | 1=显示收藏的主题 |
| `content` | int | 否 | 0 | 内容搜索标记 |
| `fidgroup` | string | 否 | - | 版面组 (user=全部用户版) |
| `page` | int | 是 | - | 页码 (从1开始) |
| `lite` | string | 是 | `js` | 固定值，返回JSON格式 |
| `noprefix` | - | 是 | - | 固定值，去除前缀 |
| `recommend` | int | 否 | - | 1=推荐精华加分主题 |
| `order_by` | string | 否 | - | 排序方式 (recommend=1时为 `postdatedesc`) |
| `user` | int | 否 | - | 用户标记 (recommend=1时为1) |

> *注: `fid`/`stid` 与 `author` 互斥。当指定 `author` 时，不传 `fid`/`stid`。

#### 2.1.3 请求URL示例

**获取版面ID为650的主题列表第2页**:
```
https://bbs.ngacn.cc/thread.php?fid=650&page=2&lite=js&noprefix
```

**搜索作者"test"的主题**:
```
https://bbs.ngacn.cc/thread.php?author=test&page=1&lite=js&noprefix
```

**搜索关键字"关键词"**:
```
https://bbs.ngacn.cc/thread.php?fid=650&key=%E5%85%B3%E9%94%AE%E8%AF%8D&page=1&lite=js&noprefix
```

**收藏列表**:
```
https://bbs.ngacn.cc/thread.php?favor=1&page=1&lite=js&noprefix
```

**推荐精华**:
```
https://bbs.ngacn.cc/thread.php?fid=650&page=1&lite=js&noprefix&recommend=1&order_by=postdatedesc&user=1
```

**24小时热帖** (多页并发请求):
```
https://bbs.ngacn.cc/thread.php?fid=650&page=1&lite=js&noprefix
https://bbs.ngacn.cc/thread.php?fid=650&page=2&lite=js&noprefix
... (共请求 totalPage 页)
```

#### 2.1.4 响应

**Content-Type**: text/html (GBK编码，以 `window.script_muti_get_var_store=` 为前缀的JSON)

**响应JSON结构** (解析后):

```json
{
  "data": {
    "__CU": {
      "uid": 10350496,
      "group_bit": 622816,
      "admincheck": "",
      "rvrc": -10
    },
    "__GLOBAL": "./template/js/nga_global.xml",
    "__F": {
      "topped_topic": "",
      "sub_forums": "",
      "fid": 275,
      "name": "版面名称"
    },
    "__ROWS": "20",
    "__T__ROWS": 1,
    "__T__ROWS_PAGE": 35,
    "__R__ROWS_PAGE": 20,
    "__T": {
      "0": {
        "tid": 11915941,
        "fid": 275,
        "quote_from": 0,
        "quote_to": "",
        "topic_misc": "",
        "author": "xxxxxx",
        "authorid": "10350496",
        "subject": "客户端测试发帖",
        "type": 516,
        "postdate": 1498529634,
        "lastpost": 1499236460,
        "lastposter": "killmanasdfasdf",
        "replies": 13,
        "lastmodify": 1500443085,
        "recommend": 1,
        "titlefont": "",
        "admin_ui": 1,
        "tpcurl": "/read.php?tid=11915941&fav=c7cf9a59",
        "parent": {"0": "275", "2": "测试版面"},
        "topic_misc_var": {"3": -1459709, "1": 32},
        "__P": {
          "tid": 12937812,
          "pid": 253178256,
          "authorid": "39454545",
          "type": 512,
          "postdate": 1511787523,
          "subject": "",
          "content": "最新回复内容..."
        }
      }
    }
  },
  "encode": "gbk",
  "time": 1511446433
}
```

#### 2.1.5 响应字段说明

**__CU (当前用户信息)**:

| 字段 | 类型 | 描述 |
|------|------|------|
| `uid` | int | 当前登录用户ID |
| `group_bit` | int | 用户组位掩码 |
| `admincheck` | string | 管理员检查标记 |
| `rvrc` | int | 用户威望值 |

**__F (版面信息)**:

| 字段 | 类型 | 描述 |
|------|------|------|
| `topped_topic` | string | 置顶主题信息 |
| `sub_forums` | string | 子版面信息 |
| `fid` | int | 版面ID |
| `name` | string | 版面名称 |

**DataBean 顶层字段**:

| 字段 | 类型 | 描述 |
|------|------|------|
| `__GLOBAL` | string | 全局模板路径 |
| `__ROWS` | string | 行数 |
| `__T__ROWS` | int | 主题总行数 |
| `__T__ROWS_PAGE` | int | 每页主题数 |
| `__R__ROWS_PAGE` | int | 每页回复数 |

**__T.{tid} (主题信息)**:

| 字段 | 类型 | 描述 |
|------|------|------|
| `tid` | int | 主题ID |
| `fid` | int | 版面ID |
| `quote_from` | int | 引用来源主题ID |
| `quote_to` | string | 引用目标 |
| `topic_misc` | string | 主题杂项信息 |
| `author` | string | 作者名 (匿名用户需解码) |
| `authorid` | string | 作者ID (匿名用户以 `#anony_` 开头) |
| `subject` | string | 主题标题 |
| `type` | int | 主题类型 (位掩码: 1024=锁定, 8192=附件, 32768=合集) |
| `postdate` | int | 发帖时间 (Unix时间戳) |
| `lastpost` | int | 最后回复时间 (Unix时间戳) |
| `lastposter` | string | 最后回复者 |
| `replies` | int | 回复数 |
| `lastmodify` | int | 最后修改时间 (Unix时间戳) |
| `recommend` | int | 推荐数 |
| `titlefont` | string | 标题字体样式 (位掩码: 1=红, 2=蓝, 4=绿, 8=橙, 16=银, 32=粗, 64=斜, 128=下划线) |
| `admin_ui` | int | 管理界面标记 |
| `tpcurl` | string | 主题URL |
| `parent` | Map\<string, string\> | 父版面信息 (如 `{"0":"275","2":"版面名"}`) |
| `topic_misc_var` | Map\<string, string\> | 其他变量 |
| `__P` | object | 最新回复预览 (PBean) |

**__T.{tid}.__P (最新回复预览)**:

| 字段 | 类型 | 描述 |
|------|------|------|
| `tid` | int | 主题ID |
| `pid` | int | 回复ID |
| `authorid` | string | 回复者ID |
| `type` | int | 回复类型 |
| `postdate` | int | 回复时间 (Unix时间戳) |
| `subject` | string | 回复标题 |
| `content` | string | 回复内容 (含BBCode) |

---

### 2.2 删除收藏主题

| 属性 | 值 |
|------|---|
| **用途** | 从收藏列表中移除主题 |
| **HTTP方法** | POST |
| **端点** | `nuke.php` |
| **Retrofit方法** | `RetrofitService.post(Map<String,String>)` |

#### 2.2.1 请求参数 (Form Fields)

| 字段名 | 类型 | 必填 | 描述 |
|--------|------|------|------|
| `__lib` | string | 是 | 固定值 `"topic_favor"` |
| `__act` | string | 是 | 固定值 `"topic_favor"` |
| `__output` | string | 是 | 固定值 `"8"` |
| `action` | string | 是 | 固定值 `"del"` |
| `page` | string | 是 | 页码 |
| `tidarray` | string | 是 | 主题ID数组 (格式: `{tid}` 或 `{tid}_{pid}`) |

#### 2.2.2 响应

成功时包含 `"操作成功"` 字符串。

---

## 3. TopicListParam 数据模型

**源码位置**: `sp.phone.param.TopicListParam`

| 字段 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `authorId` | int | 0 | 按作者ID筛选 |
| `searchPost` | int | 0 | 搜索帖子标记 |
| `favor` | int | 0 | 1=收藏列表 |
| `content` | int | 0 | 内容搜索标记 |
| `fid` | int | 0 | 版面ID |
| `key` | String | null | 搜索关键字 |
| `fidGroup` | String | null | 版面组 |
| `author` | String | null | 作者名 |
| `recommend` | int | 0 | 1=推荐精华 |
| `twentyfour` | int | 0 | 24小时热帖标记 |
| `title` | String | null | 版面标题 |
| `stid` | int | 0 | 子版面ID |
| `loadCache` | boolean | false | 是否加载缓存 |
| `boardHead` | String | null | 版面头部信息 |

---

## 4. 主题列表缓存机制

缓存存储路径: `{appFilesDir}/cache/`，每个主题一个子目录 `{tid}/{tid}.json`

- **读取**: 遍历缓存目录下所有子目录，读取 `{子目录名}/{子目录名}.json` 并解析为 `ThreadPageInfo`，汇总为 `TopicListInfo` 返回
- **删除**: 按主题 `tid` 删除整个子目录

---

## 5. URL参数组合逻辑表

| 场景 | authorId | author | fid/stid | key | favor | recommend | 附加参数 |
|------|----------|--------|----------|-----|-------|-----------|---------|
| 按版面浏览 | 0 | null | fid或stid | null | 0 | 0 | - |
| 按作者ID | >0 | null | 可选 | null | 0 | 0 | - |
| 按作者名搜索 | 0 | 有值 | 不传 | null | 0 | 0 | searchpost=1 |
| 关键字搜索 | 0 | null | fid | 有值 | 0 | 0 | - |
| 收藏列表 | 0 | null | 不传 | null | 1 | 0 | - |
| 推荐精华 | 0 | null | fid | null | 0 | 1 | order_by=postdatedesc&user=1 |
| 24小时热帖 | 0 | null | fid | null | 0 | 0 | 多页并发 |
