import { BBNode, BBNodeType } from '../../../model/BBCodeNode'
import { createBBNode, isSafeUrl, resolveMediaUrl, ParseState } from '../lexer'

/**
 * [flash] / [flash=video] / [flash=audio] 媒体块处理器。
 * - flash=video/audio：按标签显式确定 VIDEO/AUDIO 类型
 * - flash：根据 URL 扩展名推测 VIDEO/AUDIO/FLASH
 *
 * @param state 解析游标
 * @param result 当前块级节点输出数组
 * @returns 是否匹配并消费了某个 [flash] 变体
 */
export const handleFlash = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pFv: RegExp = /\[flash=video\]/gi
  pFv.lastIndex = state.pos
  const fvm = pFv.exec(state.content)
  if (fvm && fvm.index === state.pos) {
    state.pos = pFv.lastIndex
    let end = state.content.indexOf('[/flash]', state.pos)
    if (end < 0) end = state.len
    const rawUrl = state.content.substring(state.pos, end).trim()
    state.pos = end < state.len ? end + 8 : state.len
    const n = createBBNode()
    n.type = BBNodeType.VIDEO
    n.src = isSafeUrl(rawUrl) ? resolveMediaUrl(rawUrl) : ''
    result.push(n)
    return true
  }

  let pFa: RegExp = /\[flash=audio\]/gi
  pFa.lastIndex = state.pos
  const fam = pFa.exec(state.content)
  if (fam && fam.index === state.pos) {
    state.pos = pFa.lastIndex
    let end = state.content.indexOf('[/flash]', state.pos)
    if (end < 0) end = state.len
    const rawUrl = state.content.substring(state.pos, end).trim()
    state.pos = end < state.len ? end + 8 : state.len
    const n = createBBNode()
    n.type = BBNodeType.AUDIO
    n.src = isSafeUrl(rawUrl) ? resolveMediaUrl(rawUrl) : ''
    result.push(n)
    return true
  }

  let pFlash: RegExp = /\[flash\](.*?)\[\/flash\]/gi
  pFlash.lastIndex = state.pos
  const ffm = pFlash.exec(state.content)
  if (ffm && ffm.index === state.pos) {
    state.pos = pFlash.lastIndex
    const rawUrl: string = ffm[1].trim()
    const resolved: string = resolveMediaUrl(rawUrl)
    const extMatch: RegExpExecArray | null = /\.(\w+)(\?.*)?$/.exec(resolved)
    const ext: string = extMatch ? extMatch[1].toLowerCase() : ''
    const videoExts: string[] = ['mp4', 'webm', 'ogg', 'mov', '3gp']
    const audioExts: string[] = ['mp3', 'wav', 'flac', 'aac', 'm4a']
    if (videoExts.indexOf(ext) >= 0) {
      const n = createBBNode()
      n.type = BBNodeType.VIDEO
      n.src = isSafeUrl(resolved) ? resolved : ''
      result.push(n)
    } else if (audioExts.indexOf(ext) >= 0) {
      const n = createBBNode()
      n.type = BBNodeType.AUDIO
      n.src = isSafeUrl(resolved) ? resolved : ''
      result.push(n)
    } else {
      const n = createBBNode()
      n.type = BBNodeType.FLASH
      n.href = isSafeUrl(resolved) ? resolved : ''
      result.push(n)
    }
    return true
  }

  state.pos = savedPos
  return false
}
