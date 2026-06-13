import { BBNode, BBNodeType } from '../../model/BBCodeNode'
import { decodeHtmlEntities } from '../_shared/HtmlEntityCodec'
import { resolveImgUrl, NGA_CDN_BASE } from '../_shared/AttachUrl'

/**
 * 词法/状态层：ParseState、节点工厂、文本预处理与 HTML 转义工具。
 * 供 parser / block-handlers / inline-parser 共享，是解析各阶段的公共基础设施。
 */

let bbNodeIdCounter: number = 0

/** 创建一个新的 BBNode 并分配全局自增 id。 */
function createBBNode(): BBNode {
  const n = new BBNode()
  n.id = ++bbNodeIdCounter
  return n
}

/** 内联解析中用于吞掉未匹配的闭合标签，避免它们被当作纯文本。 */
const CLOSE_TAG_PATTERN: RegExp = /\[\/(b|i|u|del|h|item|color|size|font|url|img|pid|uid|tid|quote|collapse|code|list|flash|lessernuke|album|hip|dice|align|style|table|tr|td|l|r|randomblock|sub|sup)\]/gi

/** 行内格式化标签描述：开标签正则 + 闭标签字符串 + 节点类型。 */
interface FormatRecord {
  open: RegExp
  close: string
  type: BBNodeType
}

/**
 * 解析 [flash] / [flash=video] / [flash=audio] 标签内的媒体 URL。
 * 与 AttachUrl.resolveAttachUrl（附件对象字段语义）不同：此处保留 BBCode 原有语义——
 * http 原样、`./mon_` / `/mon_` 拼 CDN、其余原样返回，不剥离后缀（视频/音频扩展名有意义）。
 *
 * @param raw [flash] 标签原始内容
 * @returns 可访问的媒体 URL
 */
function resolveMediaUrl(raw: string): string {
  if (raw.startsWith('http')) return raw
  if (raw.startsWith('./mon_') || raw.startsWith('/mon_')) {
    const path: string = raw.startsWith('./') ? raw.substring(1) : raw
    return NGA_CDN_BASE + path
  }
  return raw
}

/** 将字符串中的 < > 转义为 HTML 实体，用于 title 等需原样展示的文本。 */
function escAngle(s: string): string {
  return s.replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

/** 判断 URL 是否属于可安全跳转/加载的白名单协议。 */
function isSafeUrl(url: string): boolean {
  const trimmed = url.trim().toLowerCase()
  if (/^javascript:/i.test(trimmed)) return false
  if (/^vbscript:/i.test(trimmed)) return false
  if (/^data:/i.test(trimmed)) return false
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('mailto:')) return true
  if (trimmed.startsWith('/') && !trimmed.startsWith('//')) return true
  if (trimmed.startsWith('./')) return true
  if (/^\w+\.php\b/i.test(trimmed)) return true
  return false
}

/** 反转义常见 HTML 实体，供链接/格式化文本展示前清洗。 */
function escSegHtml(s: string): string {
  return s
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
}

/** 解析器游标状态：当前内容、位置、总长度。 */
class ParseState {
  content: string = ''
  pos: number = 0
  len: number = 0
}

/** 向节点数组追加一个文本节点；连续换行折叠为单个，空文本忽略。 */
function pushTextNode(into: BBNode[], text: string): void {
  if (text.length === 0) return
  const normalized = text.replace(/\n{2,}/g, '\n')
  if (normalized.length === 0) return
  const n = createBBNode()
  n.type = BBNodeType.TEXT
  n.text = normalized
  into.push(n)
}

/** 预处理原始内容：还原转义的中括号、规范化 blockquote/a/img 标签为 BBCode。 */
function preprocessContent(s: string): string {
  return s
    .replace(/&#91;/g, '[')
    .replace(/&#93;/g, ']')
    .replace(/<blockquote[^>]*>/gi, '[quote]')
    .replace(/<\/blockquote>/gi, '[/quote]')
    .replace(/<a\s+href="(https?:\/\/[^"]+)"[^>]*>(.*?)<\/a>/gi, '[url=$1]$2[/url]')
    .replace(/<img[^>]+class="nga-emotion"[^>]+alt="([a-z]+):([^"]+)"\s*\/?>/gi, '[s:$1:$2]')
    .replace(/\[img\]https?:\/\/img4\.(?:nga\.cn|nga\.178\.com)\/ngabbs\/post\/smile\/(\w+)\.\w+\[\/img\]/gi,
      (_m: string, fname: string): string => {
        const us: number = fname.indexOf('_')
        if (us >= 0) return `[s:${fname.substring(0, us)}:${fname.substring(us + 1)}]`
        const nm: RegExpExecArray | null = /^([a-z]+?)(\d+)$/i.exec(fname)
        if (nm) return `[s:${nm[1]}:${nm[2]}]`
        return _m
      })
}

export {
  createBBNode,
  CLOSE_TAG_PATTERN,
  resolveMediaUrl,
  escAngle,
  isSafeUrl,
  escSegHtml,
  pushTextNode,
  preprocessContent
}
export { ParseState }
export { FormatRecord }
