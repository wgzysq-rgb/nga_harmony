import { BBNode, BBNodeType } from '../../../model/BBCodeNode'
import { decodeHtmlEntities } from '../../_shared/HtmlEntityCodec'
import { createBBNode, ParseState } from '../lexer'
import { parseBlockNodes, parseBBCode } from '../parser'

/**
 * [dice]骰子块处理器。仅记录占位节点。
 */
export const handleDice = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pDice: RegExp = /\[dice\](.*?)\[\/dice\]/gi
  pDice.lastIndex = state.pos
  const dm = pDice.exec(state.content)
  if (dm && dm.index === state.pos) {
    state.pos = pDice.lastIndex
    const n = createBBNode()
    n.type = BBNodeType.DICE
    result.push(n)
    return true
  }

  state.pos = savedPos
  return false
}

/**
 * [l]左浮动块处理器。递归解析到 [/l] 前的正文。
 */
export const handleFloatLeft = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pFloatL: RegExp = /\[l\]/gi
  pFloatL.lastIndex = state.pos
  const flm = pFloatL.exec(state.content)
  if (flm && flm.index === state.pos) {
    state.pos = pFloatL.lastIndex
    const n = createBBNode()
    n.type = BBNodeType.FLOAT_LEFT
    let pCloseL: RegExp = /\[\/l\]/gi
    n.children = parseBlockNodes(state, pCloseL)
    result.push(n)
    return true
  }

  state.pos = savedPos
  return false
}

/**
 * [r]右浮动块处理器。递归解析到 [/r] 前的正文。
 */
export const handleFloatRight = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pFloatR: RegExp = /\[r\]/gi
  pFloatR.lastIndex = state.pos
  const frm = pFloatR.exec(state.content)
  if (frm && frm.index === state.pos) {
    state.pos = pFloatR.lastIndex
    const n = createBBNode()
    n.type = BBNodeType.FLOAT_RIGHT
    let pCloseR: RegExp = /\[\/r\]/gi
    n.children = parseBlockNodes(state, pCloseR)
    result.push(n)
    return true
  }

  state.pos = savedPos
  return false
}

/**
 * [align=left|center|right]对齐块处理器。递归解析到 [/align] 前的正文。
 */
export const handleAlign = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pAlign: RegExp = /\[align=(\w+)\]/gi
  pAlign.lastIndex = state.pos
  const alm = pAlign.exec(state.content)
  if (alm && alm.index === state.pos) {
    const alignVal = alm[1]
    state.pos = pAlign.lastIndex
    const n = createBBNode()
    n.type = BBNodeType.ALIGN
    n.align = alignVal
    let pCloseAlign: RegExp = /\[\/align\]/gi
    n.children = parseBlockNodes(state, pCloseAlign)
    result.push(n)
    return true
  }

  state.pos = savedPos
  return false
}

/**
 * [style 属性]样式块处理器。保留原始样式串并递归解析到 [/style] 前的正文。
 */
export const handleStyle = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pStyle: RegExp = /\[style\s+([^\]]*)\]/gi
  pStyle.lastIndex = state.pos
  const sm = pStyle.exec(state.content)
  if (sm && sm.index === state.pos) {
    const styleVal = sm[1]
    state.pos = pStyle.lastIndex
    const n = createBBNode()
    n.type = BBNodeType.STYLE_DIV
    n.text = styleVal
    let pCloseStyle: RegExp = /\[\/style\]/gi
    n.children = parseBlockNodes(state, pCloseStyle)
    result.push(n)
    return true
  }

  state.pos = savedPos
  return false
}

/**
 * [hip]高亮提示块处理器。decode 后重新解析内部 BBCode，结果直接并入父输出。
 */
export const handleHip = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pHip: RegExp = /\[hip\]/gi
  pHip.lastIndex = state.pos
  const hipm = pHip.exec(state.content)
  if (hipm && hipm.index === state.pos) {
    state.pos = pHip.lastIndex
    let end = state.content.indexOf('[/hip]', state.pos)
    if (end < 0) end = state.len
    const body = state.content.substring(state.pos, end)
    state.pos = end < state.len ? end + 6 : state.len
    const innerNodes = parseBBCode(decodeHtmlEntities(body))
    for (let k = 0; k < innerNodes.length; k++) {
      result.push(innerNodes[k])
    }
    return true
  }

  state.pos = savedPos
  return false
}

/**
 * [comment...]注释块处理器。直接吞咽，不产生节点。
 */
export const handleComment = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pComment: RegExp = /\[comment[^\]]*\]/gi
  pComment.lastIndex = state.pos
  const comt = pComment.exec(state.content)
  if (comt && comt.index === state.pos) {
    state.pos = pComment.lastIndex
    return true
  }

  state.pos = savedPos
  return false
}

/**
 * [randomblock]随机块处理器。产出带 nga-randomblock 标记的 STYLE_DIV 节点。
 */
export const handleRandomBlock = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pRandom: RegExp = /\[randomblock\]/gi
  pRandom.lastIndex = state.pos
  const rbm = pRandom.exec(state.content)
  if (rbm && rbm.index === state.pos) {
    state.pos = pRandom.lastIndex
    const n = createBBNode()
    n.type = BBNodeType.STYLE_DIV
    n.text = 'nga-randomblock'
    result.push(n)
    return true
  }

  state.pos = savedPos
  return false
}
