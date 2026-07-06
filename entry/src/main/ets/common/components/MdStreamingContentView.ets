import { MdNode } from '../../model/MdNode'
import { parseMd } from '../../parser/md/MdParser'
import { MdNodeDataSource } from '../datasource/MdNodeDataSource'
import { AppColors } from '../constants/Constants'
import { MdNodesView } from './MdNodesView'

/**
 * 流式 Markdown 拆分结果。
 *
 * 采用"逐行稳定"策略：非代码块内的每个完整行（以 \n 结尾）都视作稳定块，
 * 立即送入 AST 解析渲染。尾段仅包含当前未完结行和未闭合代码块内的内容。
 * 这种策略让标量、段落、列表项等在流式过程中即时获得 Markdown 格式化，
 * 显著提升感知流畅度。最终气泡由 MdContentView 完整解析纠正。
 */
class MarkdownStreamSplit {
  /** 已到达"逐行稳定"边界的 Markdown 前缀，可安全送入 AST 解析渲染。 */
  stableText: string = ''
  /** 仍在增长中的尾部文本（当前行未完结，或位于未闭合代码块内）。 */
  tailText: string = ''
  /** 尾部文本是否位于未闭合代码块内。 */
  tailInCodeBlock: boolean = false
}

/**
 * Markdown 流式内容渲染组件。
 *
 * 稳定块增量解析为 AST 并追加到数据源，正在增长的尾段使用轻量 Text 渲染。
 */
@Component
export struct MdStreamingContentView {
  /** 原始流式 Markdown 文本。 */
  @Prop @Watch('onTextChange') text: string = ''
  /** 链接点击回调。 */
  onLinkClick: (href: string) => void = (_href: string) => {}

  /** 已稳定的 Markdown AST 节点。 */
  private stableNodes: MdNode[] = []
  /** 当前是否已有稳定 Markdown 节点。 */
  @State private hasStableNodes: boolean = false
  /** 正在增长的尾部文本。 */
  @State private tailText: string = ''
  /** 尾部文本是否处于未闭合代码块。 */
  @State private tailInCodeBlock: boolean = false
  /** 已消费的稳定前缀长度。 */
  private consumedStableLength: number = 0
  /** 稳定段序号，用于给增量解析结果补充唯一 key 前缀。 */
  private stableSegmentSerial: number = 0
  /** 稳定块 LazyForEach 数据源。 */
  private stableDataSource: MdNodeDataSource = new MdNodeDataSource()

  /**
   * 组件出现时初始化拆分状态。
   */
  aboutToAppear(): void {
    this.updateSplitState()
  }

  /**
   * 文本变化时刷新稳定前缀与尾段。
   */
  private onTextChange(): void {
    this.updateSplitState()
  }

  /**
   * 根据当前文本计算并写入组件内部响应式状态。
   */
  private updateSplitState(): void {
    const split: MarkdownStreamSplit = splitStreamingMarkdown(this.text)
    if (split.stableText.length < this.consumedStableLength) {
      this.resetStableNodes()
    }
    if (split.stableText.length > this.consumedStableLength) {
      const addedStableText: string = split.stableText.substring(this.consumedStableLength)
      this.appendStableText(addedStableText)
      this.consumedStableLength = split.stableText.length
    }
    if (this.tailText !== split.tailText) {
      this.tailText = split.tailText
    }
    if (this.tailInCodeBlock !== split.tailInCodeBlock) {
      this.tailInCodeBlock = split.tailInCodeBlock
    }
  }

  /**
   * 重置稳定节点缓存与数据源。
   */
  private resetStableNodes(): void {
    this.stableNodes = []
    this.hasStableNodes = false
    this.stableDataSource.clear()
    this.consumedStableLength = 0
    this.stableSegmentSerial = 0
  }

  /**
   * 解析新增稳定 Markdown 片段并追加到稳定节点数据源。
   *
   * @param text - 新增的稳定 Markdown 文本
   */
  private appendStableText(text: string): void {
    if (text.trim().length === 0) {
      return
    }
    const addedNodes: MdNode[] = parseMd(text)
    if (addedNodes.length === 0) {
      return
    }
    this.stableSegmentSerial++
    prefixNodeKeys(addedNodes, 'stream_' + this.stableSegmentSerial.toString())
    for (let i: number = 0; i < addedNodes.length; i++) {
      this.stableNodes.push(addedNodes[i])
    }
    this.stableDataSource.appendAll(addedNodes)
    if (!this.hasStableNodes) {
      this.hasStableNodes = true
    }
  }

  /**
   * 构建流式 Markdown 视图。
   */
  build() {
    Column() {
      if (this.hasStableNodes) {
        MdNodesView({
          nodes: this.stableNodes,
          onLinkClick: this.onLinkClick,
          forceLazy: true,
          dataSource: this.stableDataSource
        })
      }
      if (this.tailText.length > 0) {
        if (this.tailInCodeBlock) {
          this.RenderCodeTail()
        } else {
          this.RenderTextTail()
        }
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 渲染普通尾段文本与静态流式游标。
   */
  @Builder
  RenderTextTail() {
    Text() {
      Span(this.tailText).fontColor(AppColors.textPrimary)
      Span('▌').fontColor(AppColors.primary).fontSize(14)
    }
    .fontSize(15)
    .fontColor(AppColors.textPrimary)
    .lineHeight(26)
    .width('100%')
    .margin({ top: 2, bottom: 6 })
  }

  /**
   * 渲染未闭合代码块尾段与静态流式游标。
   */
  @Builder
  RenderCodeTail() {
    Scroll() {
      Text() {
        Span(this.tailText)
          .fontSize(13)
          .fontColor(AppColors.textPrimary)
        Span('▌').fontColor(AppColors.primary).fontSize(13)
      }
      .fontFamily('monospace')
      .lineHeight(20)
      .padding(12)
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .backgroundColor(AppColors.bgSecondary)
    .borderRadius(8)
    .margin({ top: 6, bottom: 6 })
  }
}

/**
 * 将流式 Markdown 拆分为稳定前缀与不稳定尾段。
 *
 * 稳定边界策略（逐行提交）：
 * - 非代码块区域：**每行**（以 \n 结尾的完整行）都是稳定边界。
 *   标题、段落、列表项、分隔线等到达即提交 AST，无需等待空行。
 *   不会截断 mid-line，因为仅当行完整（遇到 \n）时才推进边界。
 * - 代码块区域：围栏闭合前不推进稳定边界，整块以 tail 滞留，
 *   避免不完整的代码块内容进入 AST。
 *
 * 设计权衡：流式期间相同段落的多行会被拆成多个独立段落节点，
 * 流式结束后 MdContentView 会做完整正确解析，这是临时可接受的。
 *
 * @param text - 当前累计 Markdown 文本
 * @returns 拆分后的稳定前缀、尾部文本与代码块状态
 */
function splitStreamingMarkdown(text: string): MarkdownStreamSplit {
  const result: MarkdownStreamSplit = new MarkdownStreamSplit()
  if (text.length === 0) {
    return result
  }

  const normalized: string = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n')
  let inCodeBlock: boolean = false
  let stableBoundary: number = 0
  let lineStart: number = 0
  let i: number = 0

  while (i <= normalized.length) {
    if (i < normalized.length && normalized.charAt(i) !== '\n') {
      i++
      continue
    }

    const line: string = normalized.substring(lineStart, i)
    const trimmedLine: string = line.trim()
    if (isFenceLine(trimmedLine)) {
      inCodeBlock = !inCodeBlock
    }
    if (!inCodeBlock && i < normalized.length) {
      // 每个以换行符结尾的完整行都标记为稳定边界。
      // 相比"仅空行"策略，此方案让标题、段落、列表项等立即进入 AST 格式化渲染，
      // 而非滞留 tail 区以纯文本展示。流式结束后 MdContentView 会做完整正确解析，
      // 流式期间的段落分割差异（同一段多行变成多段）是临时可接受的视觉表现。
      stableBoundary = i + 1
    }
    lineStart = i + 1
    i++
  }

  result.stableText = normalized.substring(0, stableBoundary)
  result.tailText = normalized.substring(stableBoundary)
  result.tailInCodeBlock = inCodeBlock
  return result
}

/**
 * 判断一行是否为 Markdown 围栏代码标记。
 *
 * @param trimmedLine - 已经去除首尾空白的行文本
 * @returns 如果是围栏代码标记则返回 true
 */
function isFenceLine(trimmedLine: string): boolean {
  if (trimmedLine.indexOf('```') !== 0) {
    return false
  }
  const language: string = trimmedLine.substring(3).trim()
  if (language.length === 0) {
    return true
  }
  for (let i: number = 0; i < language.length; i++) {
    const ch: string = language.charAt(i)
    const isLower: boolean = ch >= 'a' && ch <= 'z'
    const isUpper: boolean = ch >= 'A' && ch <= 'Z'
    const isNumber: boolean = ch >= '0' && ch <= '9'
    if (!isLower && !isUpper && !isNumber && ch !== '_') {
      return false
    }
  }
  return true
}

/**
 * 为一批增量解析节点添加唯一 key 前缀，避免不同片段之间 key 冲突。
 *
 * @param nodes - 节点列表
 * @param prefix - key 前缀
 */
function prefixNodeKeys(nodes: MdNode[], prefix: string): void {
  for (let i: number = 0; i < nodes.length; i++) {
    prefixNodeKey(nodes[i], prefix)
  }
}

/**
 * 为单个节点及其子节点添加唯一 key 前缀。
 *
 * @param node - Markdown AST 节点
 * @param prefix - key 前缀
 */
function prefixNodeKey(node: MdNode, prefix: string): void {
  if (node.key.length > 0) {
    node.key = prefix + '_' + node.key
  } else {
    node.key = prefix + '_' + node.id.toString()
  }
  for (let i: number = 0; i < node.children.length; i++) {
    prefixNodeKey(node.children[i], prefix)
  }
}
