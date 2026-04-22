# 03 板块相关

## 获取全部分类板块

```
GET {domain}/app_api.php?__lib=home&__act=category
```

### 响应数据结构

```json
[
  {
    "id": "wow",
    "name": "魔兽世界",
    "sub": [
      {
        "name": "魔兽世界",
        "content": [
          {
            "fid": 7,
            "name": "艾泽拉斯议事厅",
            "info": "魔兽主讨论区",
            "nameS": "议事厅",
            "infoS": "高阶讨论",
            "stid": 0,
            "head": null,
            "bit": 1
          }
        ]
      },
      {
        "name": "职业讨论区",
        "content": [...]
      }
    ]
  }
]
```

### 数据模型

```typescript
// CategoryBean
interface Category {
  id: string            // 分类 ID（如 "wow"）
  name: string          // 分类名称
  sub: CategorySub[]    // 子分类列表
}

interface CategorySub {
  name: string            // 子分类名
  content: BoardContent[] // 板块列表
}

interface BoardContent {
  fid: number       // 板块 ID
  stid: number      // 子板块 ID（0 表示非子板块）
  name: string      // 板块全名
  info: string      // 板块描述
  nameS: string     // 板块简称
  infoS: string     // 简短描述
  head: string      // 板块头部 HTML
  bit?: number      // 位标记（API 返回，但客户端 Java 代码未映射此字段）
}
```

> **注意**：原项目中此数据也有本地 JSON 缓存（`assets/json/category.json`），不依赖网络。

---

## 搜索板块

```
GET http://bbs.nga.cn/forum.php?__output=8&key={keyword}
```

> **注意**：此接口在原代码中域名**硬编码**为 `http://bbs.nga.cn`，不使用动态域名。

| 参数 | 编码 | 说明 |
|------|------|------|
| `key` | GBK | 搜索关键词 |
| `__output` | - | 固定 `8` |

### 响应

```json
{
  "code": 0,
  "msg": "",
  "result": [
    {
      "id": "wow",
      "name": "魔兽世界",
      "groups": [
        {
          "id": "...",
          "name": "...",
          "forums": [
            {
              "id": 7,
              "name": "艾泽拉斯议事厅",
              "stid": 0
            }
          ]
        }
      ]
    }
  ]
}
```

### 数据模型

```typescript
interface ForumSearchResult {
  code: number
  msg: string
  result: ForumCategory[]
}

interface ForumCategory {
  id: string
  name: string
  groups: ForumGroup[]
}

interface ForumGroup {
  id: string
  name: string
  forums: ForumItem[]
}

interface ForumItem {
  id: number
  name: string
  stid: number
}
```

---

## 板块订阅/取消订阅

```
POST http://bbs.ngacn.cc/nuke.php?__lib=user_option&__act=set&raw=3&type={type}&__output=8&fid={fid}&{action}={fid}
```

> **注意**：此接口在原代码中域名**硬编码**为 `http://bbs.ngacn.cc`，不使用动态域名。

| 参数 | 说明 |
|------|------|
| `__lib` | `user_option` |
| `__act` | `set` |
| `raw` | `3` |
| `type` | 订阅类型 |
| `__output` | `8` |
| `fid` | 父板块 ID |
| `action` | `add`（订阅）或 `del`（取消） |
| `{action}值` | 子板块 fid |

---

## 板块图标 URL

```
# 普通板块
http://img4.nga.178.com/ngabbs/nga_classic/f/app/{fid}.png

# 子板块
https://img4.nga.178.com/proxy/cache_attach/ficon/{stid}v.png
```

---

## 本地板块数据模型

```typescript
// Board — 板块
interface Board {
  fid: number        // 板块 ID
  stid: number       // 子板块 ID
  name: string       // 板块名
  boardHead: string  // 板块头部
}

// SubBoard — 子板块（继承 Board）
interface SubBoard extends Board {
  tidStr: string      // 关联主题 ID
  type: number        // 类型
  checked: boolean    // 是否选中
  description: string // 描述
  parentFidStr: string // 父板块 ID
}

// BoardCategory — 板块分类
interface BoardCategory {
  categoryName: string       // 分类名
  isBookmarkCategory: boolean // 是否为收藏分类
  boardList: Board[]          // 板块列表
  subCategoryList: BoardCategory[] // 子分类
}
```
