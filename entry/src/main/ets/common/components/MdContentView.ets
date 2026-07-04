import { MdNode, MdNodeType } from '../../model/MdNode'
import { parseMd } from '../../parser/md/MdParser'
import { AppColors } from '../constants/Constants'

/**
 * Markdown 内容渲染组件。
 *
 * 接收原始 Markdown 文本，自动解析为 AST 并通过 @Builder 渲染。
 * 支持流式输出 — 每次 text 属性更新时全量重解析并刷新 UI。
 *
 * @example
 * MdContentView({
 *   text: this.aiResultText,
 *   onLinkClick: (href: string) => { routerStore.navigateUrl(href) }
 * })
 *
 * ╔══════════════════════════════════════════════════════════════╗
 * ║  ⚠️  ARKTS 响应式陷阱 — 后续 AI / 维护者必读  ⚠️          ║
 * ╠══════════════════════════════════════════════════════════════╣
 * ║                                                            ║
 * ║  ForEach 必须直接读取 @State 变量，不能通过 @Builder       ║
 * ║  参数间接传入。ArkTS 不会在 @Builder 参数与 @State         ║
 * ║  之间建立响应式依赖链。                                    ║
 * ║                                                            ║
 * ║  ❌ 错误写法（会导致流式场景只渲染第一个块）：             ║
 * ║    @Builder RenderList(nodes: MdNode[]) {                  ║
 * ║      ForEach(nodes, ...)  // nodes 是参数，不追踪变化      ║
 * ║    }                                                       ║
 * ║    build() { this.RenderList(this.parsedNodes) }           ║
 * ║                                                            ║
 * ║  ✅ 正确写法（本项目采用）：                               ║
 * ║    build() {                                              ║
 * ║      ForEach(this.parsedNodes, ...) // 直接读 @State       ║
 * ║    }                                                       ║
 * ║                                                            ║
 * ║  同理，不要将 ForEach 包装在任何 @Builder 参数函数中。    ║
 * ║  BBCodeContentView 不受影响的原因：它的 nodes 数组在       ║
 * ║  组件生命周期内不变，不依赖响应式更新。                    ║
 * ║                                                            ║
 * ║  另见：parseMd 中不能标注 RegExpMatchArray | null 类型，   ║
 * ║  ArkTS 不支持结构类型联合（arkts-no-structural-typing）。  ║
 * ╚══════════════════════════════════════════════════════════════╝
 */
@Component
export struct MdContentView {
  /** 原始 Markdown 文本 */
  @Prop @Watch('onTextChange') text: string = ''
  /** 链接点击回调 */
  onLinkClick: (href: string) => void = (_href: string) => {}

  /** 解析后的 AST 节点缓存 */
  @State private parsedNodes: MdNode[] = []

  /**
   * 文本变化时重新解析 AST。
   */
  private onTextChange(): void {
    this.parsedNodes = parseMd(this.text)
  }

  aboutToAppear(): void {
    this.parsedNodes = parseMd(this.text)
  }

  build() {
    Column() {
      // ⚠️ ForEach 必须直接读 @State，不能包在 @Builder 参数里！详见文件头注释。
      ForEach(this.parsedNodes, (node: MdNode) => {
        this.RenderBlock(node)
      }, (node: MdNode) => this.renderKey(node, 'b'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // ============================================================
  // 块级渲染分派
  // ============================================================

  /**
   * 分派单个块级节点到对应的渲染方法。
   *
   * @param node - 块级节点
   */
  @Builder
  RenderBlock(node: MdNode) {
    if (node.type === MdNodeType.HEADING) {
      this.RenderHeading(node)
    } else if (node.type === MdNodeType.PARAGRAPH) {
      this.RenderParagraph(node)
    } else if (node.type === MdNodeType.CODE_BLOCK) {
      this.RenderCodeBlock(node)
    } else if (node.type === MdNodeType.UNORDERED_LIST) {
      this.RenderUnorderedList(node)
    } else if (node.type === MdNodeType.ORDERED_LIST) {
      this.RenderOrderedList(node)
    } else if (node.type === MdNodeType.BLOCKQUOTE) {
      this.RenderBlockquote(node)
    } else if (node.type === MdNodeType.THEMATIC_BREAK) {
      this.RenderThematicBreak()
    }
  }

  // ============================================================
  // 各块级节点渲染
  // ============================================================

  /** 渲染标题 (H1-H6)。递归拼接子节点文本，保留内联格式的视觉内容。 */
  @Builder
  RenderHeading(node: MdNode) {
    Text(this.collectPlainText(node))
      .fontSize(this.headingFontSize(node.level))
      .fontColor(AppColors.textPrimary)
      .fontWeight(this.headingFontWeight(node.level))
      .lineHeight(this.headingLineHeight(node.level))
      .width('100%')
      .margin({ top: node.level <= 2 ? 14 : 10, bottom: 4 })
  }

  /** 渲染段落。通过 Span 级联支持粗体/斜体/代码/链接等内联格式。 */
  @Builder
  RenderParagraph(node: MdNode) {
    Text() {
      ForEach(node.children, (child: MdNode) => {
        this.RenderSpanLeaf(child)
      }, (child: MdNode) => this.renderKey(child, 'p'))
    }
    .fontSize(15)
    .fontColor(AppColors.textPrimary)
    .lineHeight(26)
    .width('100%')
    .margin({ top: 2, bottom: 6 })
  }

  /** 渲染围栏代码块。 */
  @Builder
  RenderCodeBlock(node: MdNode) {
    Column() {
      if (node.language.length > 0) {
        Text(node.language)
          .fontSize(11)
          .fontColor(AppColors.textTertiary)
          .padding({ left: 12, right: 12, top: 6, bottom: 4 })
      }
      Scroll() {
        Text(node.text)
          .fontSize(13)
          .fontColor(AppColors.textPrimary)
          .fontFamily('monospace')
          .lineHeight(20)
          .padding(12)
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
    }
    .width('100%')
    .backgroundColor(AppColors.bgSecondary)
    .borderRadius(8)
    .margin({ top: 6, bottom: 6 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 渲染无序列表。 */
  @Builder
  RenderUnorderedList(node: MdNode) {
    Column() {
      ForEach(node.children, (item: MdNode) => {
        Row() {
          Text('•')
            .fontSize(15)
            .fontColor(AppColors.textPrimary)
            .margin({ right: 6 })
          Text(this.collectPlainText(item))
            .fontSize(15)
            .fontColor(AppColors.textPrimary)
            .lineHeight(26)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 2, bottom: 2 })
        .alignItems(VerticalAlign.Top)
      }, (item: MdNode) => this.renderKey(item, 'uli'))
    }
    .width('100%')
    .padding({ left: 8 })
    .margin({ top: 4, bottom: 4 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 渲染有序列表。 */
  @Builder
  RenderOrderedList(node: MdNode) {
    Column() {
      ForEach(node.children, (item: MdNode, index: number) => {
        Row() {
          Text((index + 1).toString() + '.')
            .fontSize(15)
            .fontColor(AppColors.textPrimary)
            .margin({ right: 6 })
          Text(this.collectPlainText(item))
            .fontSize(15)
            .fontColor(AppColors.textPrimary)
            .lineHeight(26)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 2, bottom: 2 })
        .alignItems(VerticalAlign.Top)
      }, (item: MdNode) => this.renderKey(item, 'ol'))
    }
    .width('100%')
    .padding({ left: 8 })
    .margin({ top: 4, bottom: 4 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 渲染引用块。 */
  @Builder
  RenderBlockquote(node: MdNode) {
    Column() {
      Text(this.collectPlainText(node))
        .fontSize(14)
        .fontColor(AppColors.textSecondary)
        .fontStyle(FontStyle.Italic)
        .lineHeight(24)
        .width('100%')
    }
    .width('100%')
    .padding({ left: 12, top: 6, bottom: 6 })
    .margin({ top: 6, bottom: 4 })
    .border({
      width: { left: 2 },
      color: { left: AppColors.quoteBorders[0] },
      style: { left: BorderStyle.Solid }
    })
    .borderRadius({ topLeft: 4, bottomLeft: 4 })
    .alignItems(HorizontalAlign.Start)
  }

  /** 渲染分隔线。 */
  @Builder
  RenderThematicBreak() {
    Divider()
      .color(AppColors.separator)
      .margin({ top: 10, bottom: 10 })
      .width('100%')
  }

  // ============================================================
  // 内联处理
  // ============================================================

  /**
   * 递归收集节点树中的纯文本内容。
   *
   * 遍历整棵子树，将所有叶子节点的文本按序拼接。
   * 用于标题、列表项、引用块等块级元素的文本渲染。
   *
   * @param node - 根节点
   * @returns 拼接后的纯文本
   */
  private collectPlainText(node: MdNode): string {
    // 叶子节点：有 text 且无子节点 → 直接返回
    if (node.children.length === 0) {
      return node.text
    }
    // 容器节点：递归收集子节点文本
    let result: string = ''
    for (let i: number = 0; i < node.children.length; i++) {
      result += this.collectPlainText(node.children[i])
    }
    return result
  }

  /**
   * 返回 ArkUI ForEach 使用的渲染 key。
   *
   * @param node - Markdown AST 节点
   * @param fallbackPrefix - 无稳定 key 时使用的前缀
   * @returns 渲染 key
   */
  private renderKey(node: MdNode, fallbackPrefix: string): string {
    if (node.key.length > 0) {
      return node.key
    }
    return fallbackPrefix + '_' + node.id.toString()
  }

  /**
   * 渲染段落中的内联叶子节点为 Span。
   *
   * 解析时 compressSingleTextChild 已将单 TEXT 子节点的格式化节点
   * 展平为 text 属性。此处仅需处理 TEXT、CODE_INLINE、LINK
   * 三种叶子类型以及带 text 的格式化节点。
   *
   * @param node - 内联叶子节点
   */
  @Builder
  RenderSpanLeaf(node: MdNode) {
    if (node.type === MdNodeType.CODE_INLINE) {
      Span(node.text)
        .fontFamily('monospace')
        .fontSize(13)
        .fontColor(AppColors.warnText)
        .textBackgroundStyle({ color: AppColors.bgSecondary })
    } else if (node.type === MdNodeType.LINK) {
      Span(node.text)
        .fontColor(AppColors.primary)
        .decoration({ type: TextDecorationType.Underline, color: AppColors.primary })
        .onClick(() => {
          if (node.href.length > 0) {
            this.onLinkClick(node.href)
          }
        })
    } else if (node.type === MdNodeType.BOLD) {
      Span(node.text).fontWeight(FontWeight.Bold).fontColor(AppColors.textPrimary)
    } else if (node.type === MdNodeType.ITALIC) {
      Span(node.text).fontStyle(FontStyle.Italic).fontColor(AppColors.textPrimary)
    } else if (node.type === MdNodeType.STRIKETHROUGH) {
      Span(node.text).decoration({ type: TextDecorationType.LineThrough }).fontColor(AppColors.textPrimary)
    } else {
      Span(node.text).fontColor(AppColors.textPrimary)
    }
  }

  // ============================================================
  // 标题样式计算
  // ============================================================

  /**
   * 根据标题级别返回对应字号。
   *
   * @param level - 标题级别 (1-6)
   * @returns 字号值
   */
  private headingFontSize(level: number): number {
    if (level === 1) {
      return 22
    }
    if (level === 2) {
      return 19
    }
    if (level === 3) {
      return 17
    }
    if (level === 4) {
      return 15
    }
    if (level === 5) {
      return 14
    }
    return 13
  }

  /**
   * 根据标题级别返回对应字重。
   *
   * @param level - 标题级别 (1-6)
   * @returns 字重
   */
  private headingFontWeight(level: number): FontWeight {
    if (level <= 2) {
      return FontWeight.Bold
    }
    return FontWeight.Medium
  }

  /**
   * 根据标题级别返回对应行高。
   *
   * @param level - 标题级别 (1-6)
   * @returns 行高
   */
  private headingLineHeight(level: number): number {
    if (level === 1) {
      return 30
    }
    if (level === 2) {
      return 27
    }
    if (level === 3) {
      return 24
    }
    return 22
  }
}
