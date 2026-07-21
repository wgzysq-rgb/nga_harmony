import { AppColors } from '../../constants/Constants'
import { Avatar } from '../Avatar'
import { AnonymousName } from '../AnonymousName'
import { getCachedBBNodes } from '../../../parser/bbcode/BBCodeCache'
import { BBCodeContentView } from '../BBCodeContentView'
import { PostInfo } from '../../../model/PostInfo'
import { BBNode, BBNodeType } from '../../../model/BBCodeNode'
import { appStore } from '../../../store/AppStore'

/**
 * 过滤掉指定类型的 BBCode 节点（递归处理子节点）。
 *
 * 用于评论区渲染时剔除引用（QUOTE）与回复引用（POST_BY）等嵌套结构，
 * 保留干净的评论文本。被剔除节点的子节点会一并丢弃，但保留的节点会
 * 深拷贝并递归过滤其 children。
 *
 * @param nodes - 待过滤的 BBCode 节点数组
 * @param skipTypes - 需要剔除的节点类型集合
 * @returns 过滤后的新节点数组
 */
function filterBBTags(nodes: BBNode[], skipTypes: BBNodeType[]): BBNode[] {
  const result: BBNode[] = []
  for (const node of nodes) {
    if (skipTypes.indexOf(node.type) >= 0) continue
    if (node.children.length > 0) {
      const n = new BBNode()
      n.type = node.type
      n.text = node.text
      n.id = node.id
      n.href = node.href
      n.color = node.color
      n.size = node.size
      n.src = node.src
      n.title = node.title
      n.emotionCat = node.emotionCat
      n.emotionCode = node.emotionCode
      n.fontFamily = node.fontFamily
      n.align = node.align
      n.colSpan = node.colSpan
      n.rowSpan = node.rowSpan
      n.colWidth = node.colWidth
      n.children = filterBBTags(node.children, skipTypes)
      result.push(n)
    } else {
      result.push(node)
    }
  }
  return result
}

/**
 * 帖子评论区子组件。
 *
 * 渲染楼中楼评论列表（默认折叠为最近 2 条，可展开全部）。点击评论头像
 * （非匿名）会回调 onProfileClick 传屏幕坐标。自持 commentsExpanded，
 * 在组件复用时（aboutToReuse）重置为 false。
 */
@Component
export struct PostComments {
  /** 所属帖子信息（@Prop 值拷贝），评论来自 post.comments */
  @Prop post: PostInfo = new PostInfo()
  /** 评论展开状态（超过 2 条时可展开全部） */
  @State private commentsExpanded: boolean = false
  /** 图片点击回调 */
  onImageClick: (urls: string[], index: number) => void = (_urls: string[], _index: number) => {}
  /** 链接点击回调 */
  onLinkClick: (href: string) => void = (_href: string) => {}
  /** 点击评论用户资料回调，传入 uid 与点击位置的屏幕坐标 */
  onProfileClick: (uid: string, screenX: number, screenY: number) => void =
    (_uid: string, _x: number, _y: number) => {}

  aboutToReuse(params: Record<string, Object>): void {
    this.commentsExpanded = false
  }

  build() {
    Column() {
      ForEach(this.commentsExpanded ? this.post.comments : this.post.comments.slice(0, 2), (c: PostInfo) => {
        Row() {
          Avatar({ avatar: c.avatar, uid: String(c.authorid), name: c.author, avatarSize: 24 })
            .onClick((event: ClickEvent) => {
              if (c.isanonymous) {
                appStore.showToast('该用户已匿名')
                return
              }
              const uid = String(c.authorid)
              if (uid) {
                this.onProfileClick(uid, event.windowX, event.windowY)
              }
            })

          Column() {
            Row() {
              AnonymousName({ author: c.author, isAnonymous: c.isanonymous, fontSize: 12, normalColor: AppColors.primary })
              if (appStore.settingsStore.getNote(String(c.authorid)).length > 0) {
                Text('(' + appStore.settingsStore.getNote(String(c.authorid)) + ')')
                  .fontSize(10).fontColor(AppColors.warning).margin({ left: 3 })
              }
            }

            BBCodeContentView({
              nodes: filterBBTags(getCachedBBNodes(c.content), [BBNodeType.QUOTE, BBNodeType.POST_BY]),
              onImageClick: this.onImageClick,
              onLinkClick: this.onLinkClick,
            }).width('100%')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 8 })
        }
        .width('100%').alignItems(VerticalAlign.Top).padding({ top: 6, bottom: 6 })
      }, (c: PostInfo) => String(c.pid))
      if (this.post.comments.length > 2) {
        Text(this.commentsExpanded ? '收起' : `查看全部 ${this.post.comments.length} 条评论`)
          .fontSize(12).fontColor(AppColors.primary).margin({ top: 4 })
          .onClick(() => { this.commentsExpanded = !this.commentsExpanded })
      }
    }
    .width('80%').alignSelf(ItemAlign.End).padding(12).backgroundColor(AppColors.bgSecondary).borderRadius(8).margin({ top: 12 })
  }
}
