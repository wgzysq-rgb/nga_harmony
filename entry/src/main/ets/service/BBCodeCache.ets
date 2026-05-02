import { taskpool } from '@kit.ArkTS'
import { BBNode, BBNodeType } from '../model/BBCodeNode'
import { parseBBCode } from './BBCodeParser'
import { parseBBCodeTask, BBNodeJSON } from './BBCodeParseTask'

const MAX_CACHE_SIZE: number = 150
const cache: Map<string, BBNode[]> = new Map()
const keyOrder: string[] = []

function bbNodesFromJSON(json: string): BBNode[] {
  const raw: BBNodeJSON[] = JSON.parse(json) as BBNodeJSON[]
  const result: BBNode[] = []
  for (let i: number = 0; i < raw.length; i++) {
    result.push(jsonToBBNode(raw[i]))
  }
  return result
}

function jsonToBBNode(d: BBNodeJSON): BBNode {
  const n: BBNode = new BBNode()
  n.type = d.type as BBNodeType
  n.text = d.text
  n.href = d.href
  n.color = d.color
  n.size = d.size
  n.src = d.src
  n.title = d.title
  n.emotionCat = d.emotionCat
  n.emotionCode = d.emotionCode
  n.fontFamily = d.fontFamily
  n.align = d.align
  n.colSpan = d.colSpan
  n.rowSpan = d.rowSpan
  n.colWidth = d.colWidth
  const childCount: number = d.children.length
  for (let i: number = 0; i < childCount; i++) {
    n.children.push(jsonToBBNode(d.children[i]))
  }
  return n
}

function cachePut(content: string, nodes: BBNode[]): void {
  if (cache.size >= MAX_CACHE_SIZE && keyOrder.length > 0) {
    const oldest: string | undefined = keyOrder.shift()
    if (oldest) cache.delete(oldest)
  }
  cache.set(content, nodes)
  keyOrder.push(content)
}

export function getCachedBBNodes(content: string): BBNode[] {
  const cached: BBNode[] | undefined = cache.get(content)
  if (cached) return cached

  const nodes: BBNode[] = parseBBCode(content)
  cachePut(content, nodes)
  return nodes
}

export function clearBBCodeCache(): void {
  cache.clear()
  keyOrder.length = 0
}

export function preWarmBBCache(content: string): void {
  if (!content || cache.has(content)) return
  const task: Promise<Object> = taskpool.execute(parseBBCodeTask, content) as Promise<Object>
  task.then((result: Object) => {
    const json: string = result as string
    const nodes: BBNode[] = bbNodesFromJSON(json)
    cachePut(content, nodes)
  }).catch((err: Error) => {
    console.error('preWarmBBCache failed:', err.message)
  })
}
