import { BBNode, BBNodeType } from '../../model/BBCodeNode'
import { decodeHtmlEntities } from '../_shared/HtmlEntityCodec'
import { ParseState, preprocessContent, createBBNode } from './lexer'
import { parseInlineInto } from './inline-parser'
import { handlePostBy } from './block-handlers/handlePostBy'
import { handleQuote } from './block-handlers/handleQuote'
import { handleCollapse } from './block-handlers/handleCollapse'
import { handleCode } from './block-handlers/handleCode'
import { handleList } from './block-handlers/handleList'
import { handleNuke, handleAlbum } from './block-handlers/handleNuke'
import { handleFlash } from './block-handlers/handleFlash'
import { handleImg } from './block-handlers/handleImg'
import { handleTable } from './block-handlers/handleTable'
import {
  handleDice,
  handleFloatLeft,
  handleFloatRight,
  handleAlign,
  handleStyle,
  handleHip,
  handleComment,
  handleRandomBlock
} from './block-handlers/handleFormat'

/**
 * 编排层：parseBBCode 公共入口、parseBlockNodes 块级循环、tryMatchBlock 标签族分发，
 * 以及表格/列表的结构化辅助解析。按原 tryMatchBlock 的 if 顺序依次调用各块级 handler。
 */

/** 公共入口：预处理后从顶层解析块级节点。 */
function parseBBCode(content: string): BBNode[] {
  if (!content) return []
  const state = new ParseState()
  state.content = preprocessContent(content)
  state.pos = 0
  state.len = state.content.length
  return parseBlockNodes(state, null)
}

/** 块级循环：消费文本段与块级标签，遇 closePattern 指定的闭合标签时返回。 */
function parseBlockNodes(state: ParseState, closePattern: RegExp | null): BBNode[] {
  const result: BBNode[] = []
  let blockPos: number = state.pos

  while (state.pos < state.len) {
    if (closePattern) {
      closePattern.lastIndex = state.pos
      const cm = closePattern.exec(state.content)
      if (cm && cm.index === state.pos) {
        if (state.pos > blockPos) {
          const seg = decodeHtmlEntities(state.content.substring(blockPos, state.pos))
          parseInlineInto(seg, result)
        }
        state.pos = closePattern.lastIndex
        return result
      }
    }

    const idx = state.content.indexOf('[', state.pos)
    if (idx < 0) {
      if (state.len > blockPos) {
        const remaining = decodeHtmlEntities(state.content.substring(blockPos, state.len))
        parseInlineInto(remaining, result)
      }
      state.pos = state.len
      blockPos = state.len
      break
    }

    if (idx > state.pos) {
      const seg = decodeHtmlEntities(state.content.substring(blockPos, idx))
      parseInlineInto(seg, result)
      blockPos = idx
    }
    state.pos = idx

    if (tryMatchBlock(state, result)) {
      blockPos = state.pos
      continue
    }

    if (closePattern) {
      closePattern.lastIndex = idx
      const cmAtIdx = closePattern.exec(state.content)
      if (cmAtIdx && cmAtIdx.index === idx) {
        if (idx > blockPos) {
          const seg = decodeHtmlEntities(state.content.substring(blockPos, idx))
          parseInlineInto(seg, result)
        }
        state.pos = closePattern.lastIndex
        return result
      }
    }

    state.pos = idx + 1
  }

  if (state.pos > blockPos && blockPos < state.len) {
    const remaining = decodeHtmlEntities(state.content.substring(blockPos, state.pos))
    parseInlineInto(remaining, result)
  }
  return result
}

/**
 * 按原 if 顺序依次尝试各块级标签 handler，命中即返回。
 * 顺序与拆分前 tryMatchBlock 逐字一致，保证行为等价。
 *
 * @param state 解析游标
 * @param result 当前块级节点输出数组
 * @returns 是否命中任一块级标签
 */
function tryMatchBlock(state: ParseState, result: BBNode[]): boolean {
  if (handlePostBy(state, result)) return true
  if (handleQuote(state, result)) return true
  if (handleCollapse(state, result)) return true
  if (handleCode(state, result)) return true
  if (handleList(state, result)) return true
  if (handleNuke(state, result)) return true
  if (handleAlbum(state, result)) return true
  if (handleFlash(state, result)) return true
  if (handleDice(state, result)) return true
  if (handleImg(state, result)) return true
  if (handleFloatLeft(state, result)) return true
  if (handleFloatRight(state, result)) return true
  if (handleAlign(state, result)) return true
  if (handleTable(state, result)) return true
  if (handleStyle(state, result)) return true
  if (handleHip(state, result)) return true
  if (handleComment(state, result)) return true
  if (handleRandomBlock(state, result)) return true
  return false
}

/** 解析表格行：遇 [/table] 返回，遇 [tr] 解析一行单元格。 */
function parseTableContent(state: ParseState, closePattern: RegExp): BBNode[] {
  const rows: BBNode[] = []
  while (state.pos < state.len) {
    closePattern.lastIndex = state.pos
    const cm = closePattern.exec(state.content)
    if (cm && cm.index === state.pos) {
      state.pos = closePattern.lastIndex
      return rows
    }

    let pTr: RegExp = /\[tr\]/gi
    pTr.lastIndex = state.pos
    const trm = pTr.exec(state.content)
    if (trm && trm.index === state.pos) {
      state.pos = pTr.lastIndex
      const row = createBBNode()
      row.type = BBNodeType.TABLE_ROW
      row.children = parseTableRowCells(state)
      rows.push(row)
      continue
    }
    state.pos = state.pos + 1
  }
  return rows
}

/** 解析表格行内的 [td] 单元格，处理 colspan/rowspan/colwidth 属性。 */
function parseTableRowCells(state: ParseState): BBNode[] {
  const cells: BBNode[] = []
  while (state.pos < state.len) {
    const trClose = state.content.indexOf('[/tr]', state.pos)
    const tdOpen = state.content.indexOf('[td', state.pos)
    if (tdOpen < 0 || (trClose >= 0 && trClose < tdOpen)) {
      if (trClose >= 0) state.pos = trClose + 5
      break
    }

    let pTd: RegExp = /\[td(?:=(\d+))?(?:,(\d+))?(?:,(\d+))?\]/gi
    pTd.lastIndex = state.pos
    const tdm = pTd.exec(state.content)
    if (tdm && tdm.index === state.pos) {
      state.pos = pTd.lastIndex
      const cell = createBBNode()
      cell.type = BBNodeType.TABLE_CELL
      if (tdm[1]) cell.colSpan = parseInt(tdm[1], 10)
      if (tdm[2]) cell.rowSpan = parseInt(tdm[2], 10)
      if (tdm[3]) cell.colWidth = parseInt(tdm[3], 10)

      const closeTdIdx = state.content.indexOf('[/td]', state.pos)
      const cellEnd = closeTdIdx >= 0 ? closeTdIdx : state.len
      const cellText = decodeHtmlEntities(state.content.substring(state.pos, cellEnd))
      state.pos = closeTdIdx >= 0 ? cellEnd + 5 : state.len
      cell.children = parseBBCode(cellText)
      cells.push(cell)
    } else {
      state.pos = state.pos + 1
    }
  }
  return cells
}

/** 解析列表项：[*] 分隔，每项 trim 后递归解析。 */
function parseListItems(state: ParseState): BBNode[] {
  const items: BBNode[] = []
  while (state.pos < state.len) {
    const starIdx = state.content.indexOf('[*]', state.pos)
    const closeIdx = state.content.indexOf('[/list]', state.pos)
    if (starIdx < 0 || (closeIdx >= 0 && starIdx > closeIdx)) {
      if (closeIdx >= 0) state.pos = closeIdx + 7
      else state.pos = state.len
      break
    }
    state.pos = starIdx + 3
    let itemEnd = state.content.indexOf('[*]', state.pos)
    const listClose = state.content.indexOf('[/list]', state.pos)
    if (itemEnd < 0 || (listClose >= 0 && itemEnd > listClose)) {
      itemEnd = listClose >= 0 ? listClose : state.len
    }
    const itemText = decodeHtmlEntities(state.content.substring(state.pos, itemEnd))
    state.pos = itemEnd
    const n = createBBNode()
    n.type = BBNodeType.LIST_ITEM
    n.children = parseBBCode(itemText.trim())
    items.push(n)
  }
  return items
}

export { parseBBCode, parseBlockNodes, parseTableContent, parseListItems }
