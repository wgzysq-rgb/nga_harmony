import { BBNode, BBNodeType } from '../../../model/BBCodeNode'
import { createBBNode, escAngle, ParseState } from '../lexer'

/**
 * [code]代码块处理器。原样提取到 [/code] 前的内容（转义尖括号），不做内联解析。
 *
 * @param state 解析游标
 * @param result 当前块级节点输出数组
 * @returns 是否匹配并消费了 [code] 块
 */
export const handleCode = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pCode: RegExp = /\[code\]/gi
  pCode.lastIndex = state.pos
  const cdm = pCode.exec(state.content)
  if (cdm && cdm.index === state.pos) {
    state.pos = pCode.lastIndex
    let end = state.content.indexOf('[/code]', state.pos)
    if (end < 0) end = state.len
    const codeText = state.content.substring(state.pos, end)
    state.pos = end < state.len ? end + 7 : state.len
    const n = createBBNode()
    n.type = BBNodeType.CODE
    n.text = escAngle(codeText)
    result.push(n)
    return true
  }

  state.pos = savedPos
  return false
}
