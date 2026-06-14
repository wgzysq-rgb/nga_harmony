import { AppColors } from '../../constants/Constants'
import { PostInfo } from '../../../model/PostInfo'

/**
 * 帖子投票/动作栏子组件。
 *
 * 渲染点赞、踩、回复、编辑、分享、AI 总结、朗读等动作按钮。根据握姿
 * （holdingHand，1=左手布局）切换按钮排布顺序。展开/收起额外动作菜单（menuExpanded）
 * 时使用 150ms 动画。自持 menuExpanded，在组件复用时（aboutToReuse）重置为 false。
 */
@Component
export struct PostVoteBar {
  /** 所属帖子信息（@Prop 值拷贝） */
  @Prop post: PostInfo = new PostInfo()
  /** 是否已点赞（影响点赞按钮高亮与分数显示） */
  @Prop isVotedUp: boolean = false
  /** 是否已踩（影响踩按钮高亮与分数显示） */
  @Prop isVotedDown: boolean = false
  /** 握姿：0=右手布局，1=左手布局（动作按钮靠左） */
  @Prop holdingHand: number = 0
  /** 是否为本人的帖子（决定是否显示编辑按钮） */
  @Prop isOwnPost: boolean = false
  /** 动作菜单展开状态 */
  @State private menuExpanded: boolean = false
  /** 投票回调，value=1 为赞，-1 为踩 */
  onVote: (post: PostInfo, value: number) => void = (_post: PostInfo, _value: number) => {}
  /** 回复回调 */
  onReply: (post: PostInfo) => void = (_post: PostInfo) => {}
  /** 编辑回调 */
  onEdit: (post: PostInfo) => void = (_post: PostInfo) => {}
  /** 分享回调 */
  onShare: (post: PostInfo) => void = (_post: PostInfo) => {}
  /** AI 总结回调 */
  onSummarize: (post: PostInfo) => void = (_post: PostInfo) => {}
  /** 朗读回调 */
  onReadAloud: (post: PostInfo) => void = (_post: PostInfo) => {}

  aboutToReuse(params: Record<string, Object>): void {
    this.menuExpanded = false
  }

  build() {
    Row() {
       if (this.holdingHand === 1) {
         Row() {
           Row() {
             Row() {
               Image($r('app.media.icon_more'))
                 .width(16).height(16)
                 .fillColor(this.menuExpanded ? AppColors.primary : AppColors.textTertiary)
                 .rotate({ angle: this.menuExpanded ? -90 : 0 })
             }
             .padding({ left: 6, right: 6, top: 4, bottom: 4 })
             .borderRadius(6)
             .alignItems(VerticalAlign.Center)
             .onClick(() => { this.getUIContext()?.animateTo({ duration: 150, curve: Curve.EaseInOut }, () => { this.menuExpanded = !this.menuExpanded }) })

              if (this.menuExpanded) {
                Row() {
                  Image($r('app.media.icon_ai'))
                    .width(16).height(16)
                    .fillColor(AppColors.textTertiary)
                }
                .padding({ left: 6, right: 6, top: 4, bottom: 4 })
                .borderRadius(6)
                .margin({ left: 6 })
                .alignItems(VerticalAlign.Center)
                .transition(TransitionEffect.OPACITY)
                .onClick(() => this.onSummarize(this.post))

                Row() {
                  Image($r('app.media.icon_volume_up'))
                    .width(16).height(16)
                    .fillColor(AppColors.textTertiary)
                }
                .padding({ left: 6, right: 6, top: 4, bottom: 4 })
                .borderRadius(6)
                .margin({ left: 6 })
                .alignItems(VerticalAlign.Center)
                .transition(TransitionEffect.OPACITY)
                .onClick(() => this.onReadAloud(this.post))

                Row() {
                  Image($r('app.media.icon_share'))
                    .width(16).height(16)
                    .fillColor(AppColors.textTertiary)
                }
                .padding({ left: 6, right: 6, top: 4, bottom: 4 })
                .borderRadius(6)
                .margin({ left: 6 })
                .alignItems(VerticalAlign.Center)
                .transition(TransitionEffect.OPACITY)
                .onClick(() => this.onShare(this.post))
              }

              if (this.isOwnPost) {
               Row() {
                 Image($r('app.media.icon_compose'))
                   .width(16).height(16)
                   .fillColor(AppColors.textTertiary)
               }
               .padding({ left: 6, right: 6, top: 4, bottom: 4 })
               .borderRadius(6)
               .margin({ left: 6 })
               .alignItems(VerticalAlign.Center)
               .onClick(() => this.onEdit(this.post))
             }

             Row() {
               Image($r('app.media.icon_reply'))
                 .width(16).height(16)
                 .fillColor(AppColors.textTertiary)
             }
             .padding({ left: 6, right: 6, top: 4, bottom: 4 })
             .borderRadius(6)
             .margin({ left: 6 })
             .alignItems(VerticalAlign.Center)
             .onClick(() => this.onReply(this.post))

             Row() {
               Image($r('app.media.icon_thumb_down'))
                 .width(16).height(16)
                 .fillColor(this.isVotedDown ? AppColors.destructive : AppColors.textTertiary)
               if (this.post.score_2 > 0 || this.isVotedDown) {
                 Text(String(this.post.score_2))
                   .fontSize(13)
                   .fontColor(this.isVotedDown ? AppColors.destructive : AppColors.textSecondary)
                   .margin({ left: 3 })
               }
             }
             .padding({ left: 6, right: 6, top: 4, bottom: 4 })
             .borderRadius(6)
             .margin({ left: 6 })
             .alignItems(VerticalAlign.Center)
             .onClick(() => this.onVote(this.post, -1))

             Row() {
               Image($r('app.media.icon_thumb_up'))
                 .width(16).height(16)
                 .fillColor(this.isVotedUp ? AppColors.primary : AppColors.textTertiary)
               if (this.post.score > 0 || this.isVotedUp) {
                 Text(String(this.post.score))
                   .fontSize(13)
                   .fontColor(this.isVotedUp ? AppColors.primary : AppColors.textSecondary)
                   .margin({ left: 3 })
               }
             }
             .padding({ left: 6, right: 6, top: 4, bottom: 4 })
             .borderRadius(6)
             .margin({ left: 6 })
             .alignItems(VerticalAlign.Center)
             .onClick(() => this.onVote(this.post, 1))
           }
           .alignItems(VerticalAlign.Center)
           .transition(TransitionEffect.OPACITY)

            Row().layoutWeight(1)
          }
       } else {
         Row().layoutWeight(1)
        Row() {
          Row() {
            Image($r('app.media.icon_thumb_up'))
              .width(16).height(16)
              .fillColor(this.isVotedUp ? AppColors.primary : AppColors.textTertiary)
            if (this.post.score > 0 || this.isVotedUp) {
              Text(String(this.post.score))
                .fontSize(13)
                .fontColor(this.isVotedUp ? AppColors.primary : AppColors.textSecondary)
                .margin({ left: 3 })
            }
          }
          .padding({ left: 6, right: 6, top: 4, bottom: 4 })
          .borderRadius(6)
          .alignItems(VerticalAlign.Center)
          .onClick(() => this.onVote(this.post, 1))

          Row() {
            Image($r('app.media.icon_thumb_down'))
              .width(16).height(16)
              .fillColor(this.isVotedDown ? AppColors.destructive : AppColors.textTertiary)
            if (this.post.score_2 > 0 || this.isVotedDown) {
              Text(String(this.post.score_2))
                .fontSize(13)
                .fontColor(this.isVotedDown ? AppColors.destructive : AppColors.textSecondary)
                .margin({ left: 3 })
            }
          }
          .padding({ left: 6, right: 6, top: 4, bottom: 4 })
          .borderRadius(6)
          .margin({ left: 6 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => this.onVote(this.post, -1))

          Row() {
            Image($r('app.media.icon_reply'))
              .width(16).height(16)
              .fillColor(AppColors.textTertiary)
          }
          .padding({ left: 6, right: 6, top: 4, bottom: 4 })
          .borderRadius(6)
          .margin({ left: 6 })
          .alignItems(VerticalAlign.Center)
           .onClick(() => this.onReply(this.post))

          if (this.isOwnPost) {
            Row() {
              Image($r('app.media.icon_compose'))
                .width(16).height(16)
                .fillColor(AppColors.textTertiary)
            }
            .padding({ left: 6, right: 6, top: 4, bottom: 4 })
            .borderRadius(6)
            .margin({ left: 6 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => this.onEdit(this.post))
          }

          if (this.menuExpanded) {
            Row() {
              Image($r('app.media.icon_share'))
                .width(16).height(16)
                .fillColor(AppColors.textTertiary)
            }
            .padding({ left: 6, right: 6, top: 4, bottom: 4 })
            .borderRadius(6)
            .margin({ left: 6 })
            .alignItems(VerticalAlign.Center)
            .transition(TransitionEffect.OPACITY)
            .onClick(() => this.onShare(this.post))

            Row() {
              Image($r('app.media.icon_ai'))
                .width(16).height(16)
                .fillColor(AppColors.textTertiary)
            }
            .padding({ left: 6, right: 6, top: 4, bottom: 4 })
            .borderRadius(6)
            .margin({ left: 6 })
            .alignItems(VerticalAlign.Center)
            .transition(TransitionEffect.OPACITY)
            .onClick(() => this.onSummarize(this.post))

            Row() {
              Image($r('app.media.icon_volume_up'))
                .width(16).height(16)
                .fillColor(AppColors.textTertiary)
            }
            .padding({ left: 6, right: 6, top: 4, bottom: 4 })
            .borderRadius(6)
            .margin({ left: 6 })
            .alignItems(VerticalAlign.Center)
            .transition(TransitionEffect.OPACITY)
            .onClick(() => this.onReadAloud(this.post))
          }

          Row() {
            Image($r('app.media.icon_more'))
              .width(16).height(16)
              .fillColor(this.menuExpanded ? AppColors.primary : AppColors.textTertiary)
              .rotate({ angle: this.menuExpanded ? 90 : 0 })
          }
          .padding({ left: 6, right: 6, top: 4, bottom: 4 })
          .borderRadius(6)
          .margin({ left: 6 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.getUIContext()?.animateTo({ duration: 150, curve: Curve.EaseInOut }, () => { this.menuExpanded = !this.menuExpanded }) })
        }
        .alignItems(VerticalAlign.Center)
        .transition(TransitionEffect.OPACITY)
      }
    }.width('100%').margin({ top: 12 }).alignItems(VerticalAlign.Center)
  }
}
