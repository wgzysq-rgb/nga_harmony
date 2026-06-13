import { BBNode, BBNodeType } from '../../../model/BBCodeNode'
import { createBBNode, ParseState } from '../lexer'
import { parseListItems } from '../parser'

/**
 * [list]列表块处理器。解析 [*] 分隔的列表项。
 *
 * @param state 解析游标
 * @param result 当前块级节点输出数组
 * @returns 是否匹配并消费了 [list] 块
 */
export const handleList = (state: ParseState, result: BBNode[]): boolean => {
  const savedPos = state.pos

  let pList: RegExp = /\[list\]/gi
  pList.lastIndex = state.pos
  const lm = pList.exec(state.content)
  if (lm && lm.index === state.pos) {
    state.pos = pList.lastIndex
    const n = createBBNode()
    n.type = BBNodeType.LIST
    n.children = parseListItems(state)
    result.push(n)
    return true
  }

  state.pos = savedPos
  return false
}
