# NGA-OH Project Rules

## 项目概述

NGA 论坛第三方客户端。架构：React SPA 前端 → Node.js 原生 HTTP Server(端口3050) → 代理转发到 bbs.nga.cn。
Server 作为代理层，拦截所有 NGA 请求/响应，经 `src/shared/parsers/` 解析后返回结构化 JSON 给前端。

关键数据流：
```
浏览器 fetch('/api/*') → router.ts → handler → ngaClient → NGA(GB18030 JSON)
                                                              ↓
                                                         ngaRaw (NGA原始JSON)
                                                              ↓
                                                    shared/parsers/* (解析转换)
                                                              ↓
                                                    jsonRes({ ok, data }) → 浏览器
```

## Snapshot 诊断系统

Server 自动记录每条 API 请求的完整快照，持久化到 `data/snapshots/YYYY-MM-DD.jsonl`（JSONL 格式，每行一条记录）。

每条 snapshot 包含：
- `id`: 唯一标识（也在响应 header `X-Snap-Id` 中返回给浏览器）
- `ts`: ISO 时间戳
- `api`: 客户端请求路径（如 `/api/topics`）
- `reqParams`: 客户端传入的查询参数
- `ngaUrl`: 实际请求 NGA 的路径（如 `/thread.php`）
- `ngaParams`: 发给 NGA 的参数
- `ngaRaw`: NGA 返回的原始 JSON（parser 的输入）
- `responseToClient`: 最终返回给前端的数据（handler 映射后的输出）
- `duration`: 耗时 ms
- `hasError`: 是否有错误
- `errorMsg`: 错误信息

### 用户报告异常时的诊断流程

#### Step 1: 定位 snapshot

```bash
# 1. 如果用户能从浏览器 Network 面板提供 X-Snap-Id，直接精确查找：
rg '"id":"<snapId>"' data/snapshots/

# 2. 否则按时间+API类型搜索最近的记录：
rg '/api/topics' data/snapshots/ | tail -5           # topic 列表
rg '/api/thread' data/snapshots/ | tail -5           # 帖子详情
rg '"hasError":true' data/snapshots/ | tail -10      # 所有错误记录

# 3. 按时间段搜索（ISO 时间前缀匹配）：
rg '2026-04-17T14:2' data/snapshots/2026-04-17.jsonl | tail -10
```

#### Step 2: 分析 snapshot 数据

找到异常 snapshot 后，对比三个关键字段：

1. **`ngaRaw`**（NGA 原始返回）→ 这是 parser 的输入。检查 NGA 实际返回了什么字段。
2. **`responseToClient.data`**（返回给前端的数据）→ 这是最终输出。检查是否丢失/错误映射了字段。
3. **`ngaRaw` vs `responseToClient.data`** 的差异 → 定位是 parser 丢数据还是 handler 映射错误。

常见问题模式：
- `ngaRaw.data.__T[x].author` 有值但 `responseToClient.data.threadPageList[x].author` 为空 → parser 映射错误
- `ngaRaw.data.__R[x].content` 含未解析的 `[xxx]` 标签 → `content-parser.ts` 遗漏了该 BBCode 标签
- `ngaRaw` 为 null 且 `hasError:true` → NGA 请求本身失败（网络/域名/认证问题）

#### Step 3: 用 snapshot 数据复现问题

snapshot 中的 `ngaRaw` 就是 parser 的真实输入。直接用它跑 parser 验证：

```typescript
// tests/verify-snapshot.ts（临时验证脚本）
import { readFileSync } from 'node:fs';

const snap = JSON.parse(
  readFileSync('data/snapshots/YYYY-MM-DD.jsonl', 'utf-8')
    .split('\n')
    .find(line => line.includes('"id":"<snapId>"'))!
);

// 用 parser 重新解析 ngaRaw
import { parseTopicList } from '../src/shared/parsers/topic.js';
import { parseThreadData } from '../src/shared/parsers/thread.js';
import { parseNgaContent } from '../src/shared/content-parser.js';

// 根据 api 类型选择对应 parser
let result;
if (snap.api.includes('topic')) {
  result = parseTopicList(snap.ngaRaw);
  console.log(JSON.stringify(result, null, 2));
}
if (snap.api.includes('thread')) {
  result = parseThreadData(snap.ngaRaw);
  console.log(JSON.stringify(result, null, 2));
}

// 对比 snap.responseToClient 看差异
```

运行：`cd tests && npx tsx verify-snapshot.ts`

#### Step 4: 修复后验证

修复 parser/handler 代码后，用同一条 snapshot 的 ngaRaw 重新跑 parser，确认输出正确。

#### Step 5: 保留为回归 fixture（可选）

有价值的 snapshot 可以保存到 `tests/fixtures/` 下，用现有测试框架 `tests/runner.ts` 编写回归测试。

## 环境变量控制

- `SNAPSHOT=0` 或 `SNAPSHOT=false`：关闭 snapshot 记录
- 不设置或设置为其他值：默认开启

## 存储策略

- 每天一个 JSONL 文件：`data/snapshots/YYYY-MM-DD.jsonl`
- 单文件超过 50MB 后停止写入当天文件
- 自动清理 7 天前的文件
- `data/snapshots/` 已在 .gitignore 中（跟随 `data/` 规则）

## 重要文件索引

| 文件 | 作用 |
|------|------|
| `src/server/lib/snapshot.ts` | snapshot 核心模块：ALS、写入、清理 |
| `src/server/router.ts` | 请求入口：创建 ALS store、拦截响应、触发写入 |
| `src/server/nga-client.ts` | NGA 请求层：通过 `snapFill()` 将 ngaRaw 填入 ALS store |
| `src/shared/parsers/*.ts` | 解析器：从 NGA 原始 JSON 提取结构化数据 |
| `src/shared/content-parser.ts` | BBCode → HTML 转换器 |
| `src/server/api/*.ts` | API handler：组装最终返回给前端的数据 |
| `data/snapshots/` | snapshot 持久化目录 |
| `data/parse-errors/` | JSON 解析失败时的原始数据转储（已有机制，与 snapshot 独立） |
