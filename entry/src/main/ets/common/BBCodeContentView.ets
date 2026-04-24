import { BBNode, BBNodeType } from '../model/BBCodeNode'
import { AppColors } from '../common/Constants'
import { getEmotionResource } from '../common/EmotionResources'

function isInlineNode(type: BBNodeType): boolean {
  return type === BBNodeType.TEXT || type === BBNodeType.BOLD ||
    type === BBNodeType.ITALIC || type === BBNodeType.UNDERLINE ||
    type === BBNodeType.STRIKETHROUGH || type === BBNodeType.COLOR ||
    type === BBNodeType.SIZE || type === BBNodeType.FONT ||
    type === BBNodeType.URL || type === BBNodeType.PID_LINK ||
    type === BBNodeType.UID_LINK || type === BBNodeType.TID_LINK ||
    type === BBNodeType.MENTION || type === BBNodeType.EMOTION
}

@Component
export struct BBCodeContentView {
  nodes: BBNode[] = []
  @State collapseKeys: Set<string> = new Set()
  onImageClick: (urls: string[], index: number) => void = (_urls: string[], _index: number) => {}
  onLinkClick: (href: string) => void = (_href: string) => {}

  private getImageUrls(): string[] {
    return this.collectUrls(this.nodes)
  }

  private collectUrls(nodes: BBNode[]): string[] {
    const urls: string[] = []
    for (let i = 0; i < nodes.length; i++) {
      const n = nodes[i]
      if (n.type === BBNodeType.IMAGE && n.src.length > 0) {
        urls.push(n.src)
      }
      if (n.children.length > 0) {
        const childUrls = this.collectUrls(n.children)
        for (let j = 0; j < childUrls.length; j++) {
          urls.push(childUrls[j])
        }
      }
    }
    return urls
  }

  build() {
    Column() {
      if (this.nodes.length > 0) {
        this.RenderChildren(this.nodes)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RenderChildren(nodes: BBNode[]) {
    ForEach(this.splitIntoGroups(nodes), (group: NodeGroup) => {
      if (group.kind === 'inline') {
        Text() {
          ForEach(group.nodes, (node: BBNode) => {
            this.RenderInlineSpan(node)
          })
        }
        .fontSize(15)
        .fontColor(AppColors.textPrimary)
        .lineHeight(22)
        .width('100%')
      } else {
        this.RenderBlockNode(group.nodes[0])
      }
    })
  }

  private splitIntoGroups(nodes: BBNode[]): NodeGroup[] {
    const groups: NodeGroup[] = []
    let i = 0
    while (i < nodes.length) {
      if (isInlineNode(nodes[i].type)) {
        const inlineNodes: BBNode[] = []
        while (i < nodes.length && isInlineNode(nodes[i].type)) {
          inlineNodes.push(nodes[i])
          i++
        }
        const g = new NodeGroup()
        g.kind = 'inline'
        g.nodes = inlineNodes
        groups.push(g)
      } else {
        const g = new NodeGroup()
        g.kind = 'block'
        g.nodes = [nodes[i]]
        groups.push(g)
        i++
      }
    }
    return groups
  }

  @Builder
  RenderInlineSpan(node: BBNode) {
    if (node.type === BBNodeType.TEXT) {
      Span(node.text)
    } else if (node.type === BBNodeType.BOLD) {
      Span(node.text).fontWeight(FontWeight.Bold)
    } else if (node.type === BBNodeType.ITALIC) {
      Span(node.text).fontStyle(FontStyle.Italic)
    } else if (node.type === BBNodeType.UNDERLINE) {
      Span(node.text).decoration({ type: TextDecorationType.Underline, color: AppColors.textPrimary })
    } else if (node.type === BBNodeType.STRIKETHROUGH) {
      Span(node.text).decoration({ type: TextDecorationType.LineThrough, color: AppColors.textPrimary })
    } else if (node.type === BBNodeType.COLOR) {
      Span(node.text).fontColor(node.color.length > 0 ? node.color : AppColors.textPrimary)
    } else if (node.type === BBNodeType.SIZE) {
      Span(node.text).fontSize(node.size > 0 ? node.size : 15)
    } else if (node.type === BBNodeType.FONT) {
      Span(node.text).fontFamily(node.fontFamily)
    } else if (node.type === BBNodeType.URL || node.type === BBNodeType.PID_LINK ||
      node.type === BBNodeType.UID_LINK || node.type === BBNodeType.TID_LINK ||
      node.type === BBNodeType.MENTION) {
      Span(node.text)
        .fontColor(AppColors.primary)
        .decoration({ type: TextDecorationType.Underline, color: AppColors.primary })
        .onClick(() => {
          if (node.href.length > 0) {
            this.onLinkClick(node.href)
          }
        })
    } else if (node.type === BBNodeType.EMOTION) {
      if (getEmotionResource(node.emotionCat, node.emotionCode) !== null) {
        ImageSpan(getEmotionResource(node.emotionCat, node.emotionCode))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
      } else {
        Span(`[表情:${node.emotionCat}:${node.emotionCode}]`)
          .fontSize(14)
          .fontColor(AppColors.textTertiary)
      }
    }
  }

  @Builder
  RenderBlockNode(node: BBNode) {
    if (node.type === BBNodeType.IMAGE) {
      this.RenderImage(node)
    } else if (node.type === BBNodeType.QUOTE) {
      this.RenderQuote(node)
    } else if (node.type === BBNodeType.COLLAPSE) {
      this.RenderCollapse(node)
    } else if (node.type === BBNodeType.CODE) {
      this.RenderCode(node)
    } else if (node.type === BBNodeType.LIST) {
      this.RenderList(node)
    } else if (node.type === BBNodeType.VIDEO) {
      Text('🎬 视频').fontSize(15).fontColor(AppColors.primary).margin({ top: 6, bottom: 4 })
    } else if (node.type === BBNodeType.AUDIO) {
      Text('🎵 音频').fontSize(15).fontColor(AppColors.primary).margin({ top: 6, bottom: 4 })
    } else if (node.type === BBNodeType.DICE) {
      Text('🎲 骰子').fontSize(15).fontColor(AppColors.textPrimary)
    } else if (node.type === BBNodeType.WARN) {
      this.RenderWarn(node)
    } else if (node.type === BBNodeType.ALBUM) {
      this.RenderAlbum(node)
    } else if (node.type === BBNodeType.FLOAT_LEFT) {
      this.RenderFloat(node, FlexAlign.Start)
    } else if (node.type === BBNodeType.FLOAT_RIGHT) {
      this.RenderFloat(node, FlexAlign.End)
    } else if (node.type === BBNodeType.ALIGN) {
      this.RenderAlign(node)
    } else if (node.type === BBNodeType.TABLE) {
      this.RenderTable(node)
    } else if (node.type === BBNodeType.STYLE_DIV) {
      this.RenderStyleDiv(node)
    }
  }

  @Builder
  RenderImage(node: BBNode) {
    if (node.src.length > 0) {
      Image(node.src)
        .width('100%')
        .objectFit(ImageFit.Contain)
        .borderRadius(8)
        .backgroundColor(AppColors.bgSecondary)
        .margin({ top: 6, bottom: 4 })
        .onError(() => {})
        .onClick(() => {
          const allUrls = this.getImageUrls()
          if (allUrls.length > 0) {
            let clickIdx = 0
            for (let i = 0; i < allUrls.length; i++) {
              if (allUrls[i] === node.src) {
                clickIdx = i
                break
              }
            }
            this.onImageClick(allUrls, clickIdx)
          } else {
            this.onImageClick([node.src], 0)
          }
        })
    }
  }

  @Builder
  RenderQuote(node: BBNode) {
    Column() {
      this.RenderChildren(node.children)
    }
    .width('100%')
    .padding({ left: 12, top: 8, bottom: 8 })
    .margin({ top: 6, bottom: 4 })
    .border({
      width: { left: 3 },
      color: { left: AppColors.primary },
      style: { left: BorderStyle.Solid }
    })
    .borderRadius({ topLeft: 4, bottomLeft: 4 })
    .backgroundColor(AppColors.bgSecondary)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RenderCollapse(node: BBNode) {
    Column() {
      Row() {
        Text('▸ ' + node.title)
          .fontSize(14)
          .fontColor(AppColors.textSecondary)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })
      .onClick(() => {
        const s = new Set(this.collapseKeys)
        if (s.has(node.title)) {
          s.delete(node.title)
        } else {
          s.add(node.title)
        }
        this.collapseKeys = s
      })

      if (this.collapseKeys.has(node.title)) {
        Column() {
          this.RenderChildren(node.children)
        }
        .width('100%')
        .padding({ top: 4 })
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .margin({ top: 4, bottom: 2 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RenderCode(node: BBNode) {
    Scroll() {
      Text(node.text)
        .fontSize(13)
        .fontColor(AppColors.textPrimary)
        .fontFamily('monospace')
        .lineHeight(20)
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .padding(10)
    .margin({ top: 6, bottom: 4 })
    .borderRadius(8)
    .backgroundColor(AppColors.bgSecondary)
    .align(Alignment.TopStart)
  }

  @Builder
  RenderList(node: BBNode) {
    Column() {
      ForEach(node.children, (child: BBNode) => {
        if (child.type === BBNodeType.LIST_ITEM) {
          Row() {
            Text('• ')
              .fontSize(15)
              .fontColor(AppColors.textPrimary)
            if (child.children.length > 0) {
              Column() {
                this.RenderChildren(child.children)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            } else {
              Text(child.text)
                .fontSize(15)
                .fontColor(AppColors.textPrimary)
                .layoutWeight(1)
                .lineHeight(22)
            }
          }
          .width('100%')
          .padding({ top: 2, bottom: 2 })
          .alignItems(VerticalAlign.Top)
        }
      })
    }
    .width('100%')
    .padding({ left: 12 })
    .margin({ top: 4, bottom: 4 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RenderWarn(node: BBNode) {
    Column() {
      if (node.children.length > 0) {
        this.RenderChildren(node.children)
      } else {
        Text(node.text)
          .fontSize(15)
          .fontColor('#8B0000')
          .lineHeight(22)
      }
    }
    .width('100%')
    .padding(12)
    .margin({ top: 6, bottom: 4 })
    .borderRadius(8)
    .backgroundColor('#FFF3E0')
    .border({ width: 1, color: '#FFB74D' })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RenderAlbum(node: BBNode) {
    Column() {
      if (node.title.length > 0) {
        Text(node.title)
          .fontSize(14)
          .fontColor(AppColors.textSecondary)
          .fontWeight(FontWeight.Bold)
          .padding({ top: 4, bottom: 4 })
      }
      this.RenderChildren(node.children)
    }
    .width('100%')
    .padding(10)
    .margin({ top: 6, bottom: 4 })
    .borderRadius(8)
    .backgroundColor(AppColors.bgSecondary)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RenderFloat(node: BBNode, flexAlign: FlexAlign) {
    Row() {
      Column() {
        this.RenderChildren(node.children)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .justifyContent(flexAlign)
    .margin({ top: 4, bottom: 2 })
  }

  @Builder
  RenderAlign(node: BBNode) {
    Column() {
      this.RenderChildren(node.children)
    }
    .width('100%')
    .alignItems(node.align === 'center' ? HorizontalAlign.Center :
      node.align === 'right' ? HorizontalAlign.End : HorizontalAlign.Start)
    .margin({ top: 4, bottom: 2 })
  }

  @Builder
  RenderTable(node: BBNode) {
    Column() {
      ForEach(node.children, (row: BBNode) => {
        if (row.type === BBNodeType.TABLE_ROW) {
          Row() {
            ForEach(row.children, (cell: BBNode) => {
              if (cell.type === BBNodeType.TABLE_CELL) {
                Column() {
                  this.RenderChildren(cell.children)
                }
                .padding(6)
                .border({ width: 0.5, color: AppColors.separator })
                .alignItems(HorizontalAlign.Start)
              }
            })
          }
          .width('100%')
        }
      })
    }
    .width('100%')
    .margin({ top: 6, bottom: 4 })
    .border({ width: 0.5, color: AppColors.separator })
    .borderRadius(4)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RenderStyleDiv(node: BBNode) {
    Column() {
      this.RenderChildren(node.children)
    }
    .width('100%')
    .margin({ top: 4, bottom: 2 })
    .alignItems(HorizontalAlign.Start)
  }
}

class NodeGroup {
  kind: string = 'inline'
  nodes: BBNode[] = []
}
