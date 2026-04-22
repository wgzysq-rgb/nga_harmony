# 03 内容解析器

NGA 帖子内容使用自定义 BBCode/HTML 混合格式，需要一个专门的内容解析器将其转换为可渲染的 HTML。

## 需要处理的 NGA 自定义标签

| 标签 | 示例 | 转换目标 |
|------|------|----------|
| `[quote]...[/quote]` | 引用块 | `<blockquote>` |
| `[pid=X,Y,Z]text[/pid]` | 帖子引用 | `<a href="#/thread?tid=Y&pid=X">text</a>` |
| `[uid=X]text[/uid]` | 用户链接 | `<a href="#/profile?uid=X">text</a>` |
| `[tid=X]text[/tid]` | 主题链接 | `<a href="#/thread?tid=X">text</a>` |
| `[s:ac:XXX]` | NGA 表情代码 | `<img src="表情URL">` |
| `[img]./mon_XXX[/img]` | 表情图片 | `<img src="https://img.nga.178.com/mon_XXX">` |
| `[collapse=title]...[/collapse]` | 折叠内容 | `<details><summary>title</summary>...</details>` |
| `[dice]...[/dice]` | 骰子 | 样式化展示 |
| `[flash=video]URL[/flash]` | 视频 | `<video>` 标签 |
| `[flash=audio]URL[/flash]` | 音频 | `<audio>` 标签 |
| `[flash]URL[/flash]` | Flash（旧） | 降级为链接 |
| `[b]...[/b]` | 加粗 | `<strong>` |
| `[i]...[/i]` | 斜体 | `<em>` |
| `[u]...[/u]` | 下划线 | `<u>` |
| `[del]...[/del]` | 删除线 | `<del>` |
| `[url=X]text[/url]` | 超链接 | `<a href="X">text</a>` |
| `[color=X]...[/color]` | 颜色 | `<span style="color:X">` |
| `[size=X]...[/size]` | 字号 | `<span style="font-size:X">` |
| `[font=X]...[/font]` | 字体 | `<span style="font-family:X">` |
| `[list]...[/list]` | 列表 | `<ul>/<ol>` |
| `[align=X]...[/align]` | 对齐 | `<div style="text-align:X">` |
| `[tid=X&page=1]text[/tid]` | 带页码主题链接 | `<a>` |
| `[code]...[/code]` | 代码块 | `<pre><code>` |
| `[table]...[/table]` | 表格 | `<table>` |
| `[tr]...[/tr]` | 表格行 | `<tr>` |
| `[td]...[/td]` | 表格单元格 | `<td>`（支持 colspan/rowspan/width） |
| `[h]...[/h]` | 标题加粗 | `<strong>` |
| `[item]...[/item]` | 物品加粗 | `<strong>` |
| `[l]...[/l]` | 左浮动 | `<div style="float:left">` |
| `[r]...[/r]` | 右浮动 | `<div style="float:right">` |
| `[lessernuke]...[/lessernuke]` | 警告框 | `<div class="nga-warn">` |
| `[album=X]...[/album]` | 图集 | 图片网格 + 标题 |
| `[randomblock]...` | 游戏/小说评分块 | 固定布局展示 |
| `[hip]...[/hip]` | 隐藏标记 | 剥离（直接输出内容） |
| `[comment ...]` | 注释标记 | 剥离 |
| `[style ...]` | 行内样式 div | `<div style="...">` |
| `[@uid]` | @提及 | `<a href="#/profile?uid=uid">@uid</a>` |
| `Post by XXX (uid)` | 引用行用户链接 | 用户链接化 |
| `[s:N]` | 旧版数字表情 | 表情图片 |
| html markup | NGA 返回的部分 HTML | 直接保留或清理 |

## 解析器架构

### 设计原则

1. **管线式处理**：输入 → 正则替换链 → 输出
2. **前后端共用**：解析器放在 `src/shared/` 目录，纯字符串操作
3. **安全过滤**：移除 `<script>` 和 `onclick` 等 XSS 向量
4. **处理顺序敏感**：NGA 特有标签优先于标准 BBCode，避免冲突（如 `[b]Reply to [pid=X,Y,Z]...[/pid][/b]` 需先处理 pid 再处理 b）

### 核心实现

```typescript
// src/shared/content-parser.ts

const EMOTION_BASE_URLS: Record<string, string> = {
  ac:  'https://img4.nga.178.com/ngabbs/nga_classic/ac',
  a2:  'https://img4.nga.178.com/ngabbs/nga_classic/a2',
  ng:  'https://img4.nga.178.com/ngabbs/nga_classic/ng',
  pst: 'https://img4.nga.178.com/ngabbs/nga_classic/pst',
  dt:  'https://img4.nga.178.com/pgc/dt',
  pg:  'https://img4.nga.178.com/pgc/pg',
};

export function parseNgaContent(content: string): string {
  if (!content) return '';

  let html = content;

  // === Phase 1: NGA 特有标签 ===

  // 帖子引用 [pid=X,Y,Z]text[/pid]  (X=pid, Y=tid, Z=page)
  html = html.replace(
    /\[pid=(\d+),(\d+),(\d+)\](.*?)\[\/pid\]/g,
    (_, pid, tid, page, text) =>
      `<a class="nga-quote-link" href="#/thread?tid=${tid}&pid=${pid}">${text}</a>`
  );

  // 用户链接 [uid=X]text[/uid]
  html = html.replace(
    /\[uid=(\d+)\](.*?)\[\/uid\]/g,
    (_, uid, text) =>
      `<a class="nga-user-link" href="#/profile?uid=${uid}">${text}</a>`
  );

  // 主题链接 [tid=X]text[/tid]（含可选 page 参数）
  html = html.replace(
    /\[tid=(\d+)(?:&page=(\d+))?\](.*?)\[\/tid\]/g,
    (_, tid, page, text) =>
      `<a class="nga-topic-link" href="#/thread?tid=${tid}${page ? '&page=' + page : ''}">${text}</a>`
  );

  // @提及 [@uid]
  html = html.replace(
    /\[@(\d+)\]/g,
    (_, uid) =>
      `<a class="nga-mention" href="#/profile?uid=${uid}">@${uid}</a>`
  );

  // "Post by XXX (uid)" 引用行用户链接
  html = html.replace(
    /Post by (.+?) \((\d+)\)/g,
    (_, name, uid) =>
      `Post by <a href="#/profile?uid=${uid}">${name}</a> (${uid})`
  );

  // NGA 表情 [s:category:code] 或 [s:N]（旧版数字格式）
  html = html.replace(
    /\[s:(\w+):(\w+)\]/g,
    (_, cat, code) => {
      const base = EMOTION_BASE_URLS[cat];
      if (base) return `<img class="nga-emotion" src="${base}/${code}.gif" alt="${cat}:${code}">`;
      return `[s:${cat}:${code}]`;
    }
  );
  html = html.replace(
    /\[s:(\d+)\]/g,
    (_, num) =>
      `<span class="nga-emotion-old" data-code="${num}">[表情${num}]</span>`
  );

  // NGA 图片 [img]./mon_XXX[/img]（相对路径表情图），需剥离缩略图后缀
  html = html.replace(
    /\[img\]\.(\/mon_\S+?)\[\/img\]/g,
    (_, path) => {
      const cleanPath = stripThumbnailSuffix(path);
      return `<img class="nga-img" src="https://img.nga.178.com${cleanPath}" loading="lazy">`;
    }
  );

  // 折叠内容 [collapse=title]...[/collapse]
  html = html.replace(
    /\[collapse=(.*?)\](.*?)\[\/collapse\]/gs,
    (_, title, body) =>
      `<details class="nga-collapse"><summary>${title}</summary>${body}</details>`
  );

  // 引用 [quote]...[/quote]（多次应用处理嵌套）
  for (let i = 0; i < 3; i++) {
    html = html.replace(
      /\[quote\](.*?)\[\/quote\]/gs,
      (_, body) => `<blockquote class="nga-quote">${body}</blockquote>`
    );
  }

  // 骰子 [dice]...[/dice]
  html = html.replace(
    /\[dice\](.*?)\[\/dice\]/g,
    (_, data) =>
      `<div class="nga-dice" data-dice="${encodeURIComponent(data)}">🎲 骰子结果</div>`
  );

  // 视频 [flash=video]URL[/flash]
  html = html.replace(
    /\[flash=video\](.*?)\[\/flash\]/g,
    (_, url) =>
      `<video class="nga-video" src="${url}" controls></video>`
  );

  // 音频 [flash=audio]URL[/flash]
  html = html.replace(
    /\[flash=audio\](.*?)\[\/flash\]/g,
    (_, url) =>
      `<audio class="nga-audio" src="${url}" controls></audio>`
  );

  // Flash（旧） [flash]URL[/flash]
  html = html.replace(
    /\[flash\](.*?)\[\/flash\]/g,
    (_, url) =>
      `<a class="nga-flash-link" href="${url}" target="_blank">[Flash 内容]</a>`
  );

  // 警告框 [lessernuke]...[/lessernuke]
  html = html.replace(
    /\[lessernuke\](.*?)\[\/lessernuke\]/gs,
    (_, body) => `<div class="nga-warn">${body}</div>`
  );

  // 图集 [album=title]...[/album]
  html = html.replace(
    /\[album=(.*?)\](.*?)\[\/album\]/gs,
    (_, title, body) =>
      `<div class="nga-album"><div class="nga-album-title">${title}</div>${body}</div>`
  );

  // 剥离 [hip]...[/hip]
  html = html.replace(/\[hip\](.*?)\[\/hip\]/gs, '$1');

  // 剥离 [comment ...]
  html = html.replace(/\[comment[^\]]*\]/g, '');

  // [randomblock] 游戏/小说评分块
  html = html.replace(
    /\[randomblock\]/g,
    '<div class="nga-randomblock">'
  );

  // === Phase 2: 标准 BBCode ===

  // 代码块 [code]...[/code]
  html = html.replace(
    /\[code\](.*?)\[\/code\]/gs,
    (_, code) => `<pre class="nga-code"><code>${code}</code></pre>`
  );

  // 加粗/斜体/下划线/删除线
  html = html.replace(/\[b\](.*?)\[\/b\]/g, '<strong>$1</strong>');
  html = html.replace(/\[i\](.*?)\[\/i\]/g, '<em>$1</em>');
  html = html.replace(/\[u\](.*?)\[\/u\]/g, '<u>$1</u>');
  html = html.replace(/\[del\](.*?)\[\/del\]/g, '<del>$1</del>');

  // [h] 标题加粗 / [item] 物品加粗
  html = html.replace(/\[h\](.*?)\[\/h\]/g, '<strong>$1</strong>');
  html = html.replace(/\[item\](.*?)\[\/item\]/g, '<strong>$1</strong>');

  // 浮动
  html = html.replace(/\[l\](.*?)\[\/l\]/gs, '<div style="float:left">$1</div>');
  html = html.replace(/\[r\](.*?)\[\/r\]/gs, '<div style="float:right">$1</div>');

  // 颜色
  html = html.replace(
    /\[color=(#[0-9a-fA-F]+|\w+)\](.*?)\[\/color\]/gs,
    '<span style="color:$1">$2</span>'
  );

  // 字号
  html = html.replace(
    /\[size=(\d+)\](.*?)\[\/size\]/gs,
    '<span style="font-size:$1px">$2</span>'
  );

  // 字体
  html = html.replace(
    /\[font=(.*?)\](.*?)\[\/font\]/gs,
    '<span style="font-family:$1">$2</span>'
  );

  // 超链接
  html = html.replace(
    /\[url=(.*?)\](.*?)\[\/url\]/g,
    '<a href="$1" target="_blank" rel="noopener">$2</a>'
  );
  html = html.replace(
    /\[url\](.*?)\[\/url\]/g,
    '<a href="$1" target="_blank" rel="noopener">$1</a>'
  );

  // 图片（通用），剥离缩略图后缀
  html = html.replace(
    /\[img\](.*?)\[\/img\]/g,
    (_, url) => {
      const cleanUrl = stripThumbnailSuffix(url);
      return `<img class="nga-img" src="${cleanUrl}" loading="lazy">`;
    }
  );

  // 列表
  html = html.replace(/\[list\](.*?)\[\/list\]/gs, '<ul>$1</ul>');
  html = html.replace(/\[\*\](.*?)(?=\[\*\]|\[\/list\])/gs, '<li>$1</li>');

  // 对齐
  html = html.replace(
    /\[align=(\w+)\](.*?)\[\/align\]/gs,
    '<div style="text-align:$1">$2</div>'
  );

  // 表格
  html = html.replace(/\[table\]/g, '<table class="nga-table">');
  html = html.replace(/\[\/table\]/g, '</table>');
  html = html.replace(/\[tr\]/g, '<tr>');
  html = html.replace(/\[\/tr\]/g, '</tr>');
  html = html.replace(
    /\[td(?:=(\d+))?(?:,(\d+))?(?:,(\d+))?\]/g,
    (_, colspan, rowspan, width) => {
      let attrs = '';
      if (colspan) attrs += ` colspan="${colspan}"`;
      if (rowspan) attrs += ` rowspan="${rowspan}"`;
      if (width) attrs += ` width="${width}"`;
      return `<td${attrs}>`;
    }
  );
  html = html.replace(/\[\/td\]/g, '</td>');

  // [style ...] 行内样式 div
  html = html.replace(
    /\[style\s+([^\]]*)\]/g,
    (_, style) => `<div style="${style}">`
  );
  html = html.replace(/\[\/style\]/g, '</div>');

  // === Phase 3: 安全清理 ===

  // 移除 <script> 标签
  html = html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');

  // 移除事件属性
  html = html.replace(/\bon\w+\s*=\s*["'][^"']*["']/gi, '');

  // 移除 javascript: 链接
  html = html.replace(/href\s*=\s*["']javascript:/gi, 'href="');

  return html;
}

/**
 * 剥离 NGA 图片缩略图后缀以获取原图
 * 例: ./mon_202501/xxx.gif.thumb_s.jpg → ./mon_202501/xxx.gif
 */
const THUMB_SUFFIXES = [
  /\.thumb_s\.jpg$/i,
  /\.thumb_s\.png$/i,
  /\.thumb_m\.jpg$/i,
  /\.thumb_m\.png$/i,
  /\.medium\.jpg$/i,
  /\.medium\.png$/i,
  /\.thumb\.jpg$/i,
  /\.thumb\.png$/i,
];

function stripThumbnailSuffix(url: string): string {
  for (const suffix of THUMB_SUFFIXES) {
    if (suffix.test(url)) {
      return url.replace(suffix, '');
    }
  }
  return url;
}
```

### 嵌套处理

NGA 的 `[quote]` 标签可以嵌套。当前方案使用循环多次 apply 正则（最多 3 层嵌套），对绝大多数帖子够用。如果遇到复杂多层嵌套解析错误，可改用栈式解析器：

```typescript
// 备选方案：栈式解析器（处理复杂嵌套）
function parseQuotesWithStack(input: string): string {
  const stack: { start: number }[] = [];
  let i = 0;
  while (i < input.length) {
    if (input.startsWith('[quote]', i)) {
      stack.push({ start: i });
      i += 7;
    } else if (input.startsWith('[/quote]', i) && stack.length > 0) {
      const { start } = stack.pop()!;
      const body = input.slice(start + 7, i);
      const replacement = `<blockquote class="nga-quote">${body}</blockquote>`;
      input = input.slice(0, start) + replacement + input.slice(i + 8);
      i = start + replacement.length;
    } else {
      i++;
    }
  }
  return input;
}
```

### 图片懒加载

解析器输出的图片标签带有 `loading="lazy"` 属性，浏览器原生支持懒加载。额外策略：

```css
/* 默认不加载，滚动到可视区域时加载 */
.nga-img {
  background: #f0f0f0;
  min-height: 100px;
}
```

### 内容中的附件

帖子内容中的附件（`content` 字段里的 `<img src="./mon_XXX">` 等）和 `attachs` 字段的附件需要统一处理：

```typescript
// src/shared/content-parser.ts

/** 将附件 URL 转为绝对路径 */
export function resolveAttachUrl(attachurl: string): string {
  if (attachurl.startsWith('http')) return attachurl;
  return `https://img.nga.178.com/attach/${attachurl}`;
}
```

## 表情系统

NGA 有多套表情体系：

1. **文字表情代码**：`[s:ac:blink]` → 解析为 GIF 图片 URL
2. **图片路径表情**：`[img]./mon_202501/xxx.png[/img]` → 拼接域名
3. **旧版数字表情**：`[s:123]` → 旧版表情编号

### 表情分类和 URL 规则

| 分类代码 | 数量 | URL 模板 |
|---------|------|---------|
| `ac` | 45 | `https://img4.nga.178.com/ngabbs/nga_classic/ac/{code}.gif` |
| `a2` | 46 | `https://img4.nga.178.com/ngabbs/nga_classic/a2/{code}.gif` |
| `ng` | 34 | `https://img4.nga.178.com/ngabbs/nga_classic/ng/{code}.gif` |
| `pst` | 65 | `https://img4.nga.178.com/ngabbs/nga_classic/pst/{code}.gif` |
| `dt` | 33 | `https://img4.nga.178.com/pgc/dt/{code}.gif` |
| `pg` | 15 | `https://img4.nga.178.com/pgc/pg/{code}.gif` |

图片路径表情：`https://img.nga.178.com{path}`

### 编辑器中的表情面板

前端编辑器需要提供表情选择 UI。表情列表硬编码为 JSON 文件（`src/client/assets/emotions.json`），从参考项目 `assets/json/category.json` 提取。也可打包进 esbuild bundle 中。
