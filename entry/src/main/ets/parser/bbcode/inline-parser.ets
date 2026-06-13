import { BBNode, BBNodeType } from '../../model/BBCodeNode'
import { decodeHtmlEntities } from '../_shared/HtmlEntityCodec'
import {
  createBBNode,
  CLOSE_TAG_PATTERN,
  isSafeUrl,
  escSegHtml,
  pushTextNode,
  ParseState,
  FormatRecord
} from './lexer'

/**
 * 内联解析层：对一段已 decodeHtmlEntities 的纯文本/片段进行行内标签解析。
 * 处理 pid/uid/tid 链接、@提及、表情、Post by、url、b/i/u/del/color/size/font 等格式化标签，
 * 以及未匹配的闭合标签吞咽。本层不调用 parseBBCode，无循环依赖。
 */

/**
 * 根据文件扩展名推测 [img] 标签的真实媒体类型。
 * NGA 有时会把 GIF 转换后保存为 .gif.mp4 但仍用 [img] 包裹。
 * 返回 VIDEO / AUDIO 或 IMAGE（非媒体扩展名时由调用方默认当图片处理）。
 */
const MEDIA_VIDEO_EXTS: string[] = ['mp4', 'webm', 'ogg', 'mov', '3gp']
const MEDIA_AUDIO_EXTS: string[] = ['mp3', 'wav', 'flac', 'aac', 'm4a']

function guessMediaTypeFromExt(rawUrl: string): BBNodeType {
  const extMatch: RegExpExecArray | null = /\.(\w+)(\?.*)?$/.exec(rawUrl)
  if (!extMatch) return BBNodeType.IMAGE
  const ext: string = extMatch[1].toLowerCase()
  if (MEDIA_VIDEO_EXTS.indexOf(ext) >= 0) return BBNodeType.VIDEO
  if (MEDIA_AUDIO_EXTS.indexOf(ext) >= 0) return BBNodeType.AUDIO
  return BBNodeType.IMAGE
}

function parseInlineInto(seg: string, into: BBNode[]): void {
  let i = 0
  const segLen = seg.length

  while (i < segLen) {
    const ch = seg[i]

    if (ch === '[') {
      if (seg.length >= i + 5 && seg.substring(i, i + 5) === '[pid=') {
        const closerPos: string = '[/pid]'
        const closerLen: number = 6
        const idEnd: number = seg.indexOf(']', i + 5)
        const firstComma: number = seg.indexOf(',', i + 5)
        const secComma: number = firstComma >= 0 ? seg.indexOf(',', firstComma + 1) : -1
        if (idEnd >= 0 && firstComma >= 0 && secComma >= 0) {
          const pid: string = seg.substring(i + 5, firstComma)
          const tid: string = seg.substring(firstComma + 1, secComma)
          const bodyStart: number = idEnd + 1
          const closeIdx: number = seg.indexOf(closerPos, bodyStart)
          const bodyEnd: number = closeIdx >= 0 ? closeIdx : segLen
          const text: string = seg.substring(bodyStart, bodyEnd)
          i = closeIdx >= 0 ? bodyEnd + closerLen : segLen
          const n = createBBNode()
          n.type = BBNodeType.PID_LINK
          n.href = `#/thread?tid=${tid}&pid=${pid}`
          n.text = escSegHtml(text)
          into.push(n)
          continue
        }
      }

      if (seg.length >= i + 5 && seg.substring(i, i + 5) === '[uid=') {
        const closerPos: string = '[/uid]'
        const closerLen: number = 6
        const idEnd: number = seg.indexOf(']', i + 5)
        if (idEnd >= 0) {
          const uid: string = seg.substring(i + 5, idEnd)
          const bodyStart: number = idEnd + 1
          const closeIdx: number = seg.indexOf(closerPos, bodyStart)
          const bodyEnd: number = closeIdx >= 0 ? closeIdx : segLen
          const text: string = seg.substring(bodyStart, bodyEnd)
          i = closeIdx >= 0 ? bodyEnd + closerLen : segLen
          const n = createBBNode()
          n.type = BBNodeType.UID_LINK
          n.href = `#/profile?uid=${uid}`
          n.text = escSegHtml(text)
          into.push(n)
          continue
        }
      }

      if (seg.length >= i + 5 && seg.substring(i, i + 5) === '[tid=') {
        const closerPos: string = '[/tid]'
        const closerLen: number = 6
        const idEnd: number = seg.indexOf(']', i + 5)
        if (idEnd >= 0) {
          const tidPart: string = seg.substring(i + 5, idEnd)
          const ampPos: number = tidPart.indexOf('&page=')
          const tidVal: string = ampPos >= 0 ? tidPart.substring(0, ampPos) : tidPart
          const pageVal: string = ampPos >= 0 ? tidPart.substring(ampPos + 6) : ''
          const bodyStart: number = idEnd + 1
          const closeIdx: number = seg.indexOf(closerPos, bodyStart)
          const bodyEnd: number = closeIdx >= 0 ? closeIdx : segLen
          const text: string = seg.substring(bodyStart, bodyEnd)
          i = closeIdx >= 0 ? bodyEnd + closerLen : segLen
          const n = createBBNode()
          n.type = BBNodeType.TID_LINK
          n.href = `#/thread?tid=${tidVal}${pageVal.length > 0 ? '&page=' + pageVal : ''}`
          n.text = escSegHtml(text)
          into.push(n)
          continue
        }
      }

      const menP: RegExp = /\[@(\d+)\]/g
      menP.lastIndex = i
      const menM = menP.exec(seg)
      if (menM && menM.index === i) {
        i = menP.lastIndex
        const n = createBBNode()
        n.type = BBNodeType.MENTION
        n.href = `#/profile?uid=${menM[1]}`
        n.text = `@${menM[1]}`
        into.push(n)
        continue
      }

      const emo1P: RegExp = /\[s:(\w+):([^\]]+)\]/g
      emo1P.lastIndex = i
      const emo1M = emo1P.exec(seg)
      if (emo1M && emo1M.index === i) {
        i = emo1P.lastIndex
        const n = createBBNode()
        n.type = BBNodeType.EMOTION
        n.emotionCat = emo1M[1]
        n.emotionCode = emo1M[2]
        into.push(n)
        continue
      }

      const emo2P: RegExp = /\[s:(\d+)\]/g
      emo2P.lastIndex = i
      const emo2M = emo2P.exec(seg)
      if (emo2M && emo2M.index === i) {
        i = emo2P.lastIndex
        const n = createBBNode()
        n.type = BBNodeType.EMOTION
        n.emotionCat = 'old'
        n.emotionCode = emo2M[1]
        n.text = `[表情${emo2M[1]}]`
        into.push(n)
        continue
      }

      const pbP: RegExp = /Post by (.+?) \((\d+)\)/g
      pbP.lastIndex = i
      const pbM = pbP.exec(seg)
      if (pbM && pbM.index === i) {
        i = pbP.lastIndex
        pushTextNode(into, 'Post by ')
        const n = createBBNode()
        n.type = BBNodeType.UID_LINK
        n.href = `#/profile?uid=${pbM[2]}`
        n.text = escSegHtml(pbM[1])
        into.push(n)
        pushTextNode(into, ` (${pbM[2]})`)
        continue
      }

      let fmtMatched = false
      const closedFmtIndex: number = checkInlineFormat(i, seg, segLen, into)
      if (closedFmtIndex > i) {
        i = closedFmtIndex
        fmtMatched = true
      }
      if (fmtMatched) continue

      if (seg.length >= i + 5) {
        const fiveChars: string = seg.substring(i, i + 5)
        if (fiveChars === '[url=') {
          const hrefEnd: number = seg.indexOf(']', i + 5)
          if (hrefEnd >= 0) {
            const href: string = seg.substring(i + 5, hrefEnd)
            const bodyStart: number = hrefEnd + 1
            const closeTagIdx: number = seg.indexOf('[/url]', bodyStart)
            const bodyEnd: number = closeTagIdx >= 0 ? closeTagIdx : segLen
            const text: string = seg.substring(bodyStart, bodyEnd)
            i = closeTagIdx >= 0 ? bodyEnd + 6 : segLen
            const n = createBBNode()
            n.type = BBNodeType.URL
            n.href = isSafeUrl(href) ? href : ''
            n.text = escSegHtml(text)
            into.push(n)
            continue
          }
        } else if (fiveChars === '[url]') {
          const bodyStart: number = i + 5
          const closeTagIdx: number = seg.indexOf('[/url]', bodyStart)
          const bodyEnd: number = closeTagIdx >= 0 ? closeTagIdx : segLen
          const text: string = seg.substring(bodyStart, bodyEnd)
          i = closeTagIdx >= 0 ? bodyEnd + 6 : segLen
          const n = createBBNode()
          n.type = BBNodeType.URL
          n.href = isSafeUrl(text) ? text : ''
          n.text = escSegHtml(text)
          into.push(n)
          continue
        }
      }

      CLOSE_TAG_PATTERN.lastIndex = i
      const closeM = CLOSE_TAG_PATTERN.exec(seg)
      if (closeM && closeM.index === i) {
        i = CLOSE_TAG_PATTERN.lastIndex
        continue
      }

      pushTextNode(into, '[')
      i++
      continue
    }

    let nextBracket = seg.indexOf('[', i)
    if (nextBracket < 0) nextBracket = segLen
    if (nextBracket > i) {
      pushTextNode(into, seg.substring(i, nextBracket))
      i = nextBracket
    } else {
      pushTextNode(into, seg.substring(i, i + 1))
      i++
    }
  }
}

function checkInlineFormat(startIdx: number, seg: string, segLen: number, into: BBNode[]): number {
  const savedI = startIdx
  let i = startIdx

  const fmtPats: FormatRecord[] = [
    { open: /\[b\]/gi, close: '[/b]', type: BBNodeType.BOLD },
    { open: /\[h\]/gi, close: '[/h]', type: BBNodeType.BOLD },
    { open: /\[item\]/gi, close: '[/item]', type: BBNodeType.BOLD },
    { open: /\[i\]/gi, close: '[/i]', type: BBNodeType.ITALIC },
    { open: /\[u\]/gi, close: '[/u]', type: BBNodeType.UNDERLINE },
    { open: /\[del\]/gi, close: '[/del]', type: BBNodeType.STRIKETHROUGH },
    { open: /\[color=(#[0-9a-fA-F]+|\w+)\]/gi, close: '[/color]', type: BBNodeType.COLOR },
    { open: /\[size=(\d+)%\]/gi, close: '[/size]', type: BBNodeType.SIZE },
    { open: /\[font=(.*?)\]/gi, close: '[/font]', type: BBNodeType.FONT },
    { open: /\[sub\]/gi, close: '[/sub]', type: BBNodeType.SUBSCRIPT },
    { open: /\[sup\]/gi, close: '[/sup]', type: BBNodeType.SUPERSCRIPT },
  ]

  for (let fi = 0; fi < fmtPats.length; fi++) {
    const rec = fmtPats[fi]
    rec.open.lastIndex = i
    const fm = rec.open.exec(seg)
    if (fm && fm.index === i) {
      i = rec.open.lastIndex
      const closeIdx = seg.toLowerCase().indexOf(rec.close.toLowerCase(), i)
      const bodyEnd = closeIdx >= 0 ? closeIdx : segLen
      const body = seg.substring(i, bodyEnd)
      i = closeIdx >= 0 ? bodyEnd + rec.close.length : segLen

      const n = createBBNode()
      n.type = rec.type
      if (rec.type === BBNodeType.COLOR) n.color = fm[1]
      if (rec.type === BBNodeType.SIZE) n.size = parseInt(fm[1], 10)
      if (rec.type === BBNodeType.FONT) n.fontFamily = fm[1]

      const childNodes: BBNode[] = []
      parseInlineInto(body, childNodes)
      if (childNodes.length === 1 && childNodes[0].type === BBNodeType.TEXT) {
        n.text = childNodes[0].text
      } else if (childNodes.length === 0) {
        n.text = ''
      } else {
        n.children = childNodes
      }
      into.push(n)
      return i
    }
  }
  return savedI
}

export { parseInlineInto, guessMediaTypeFromExt }
