/**
 * 通用导航栏组件
 */
import { AppColors } from '../constants/Constants'

@Component
export struct NavBar {
  @Prop title: string = ''
  @Prop showBack: boolean = false
  @Prop rightLabel: string = ''
  onBackClick?: () => void
  onRightClick?: () => void

  build() {
    Row() {
      // 左侧返回按钮
      Row() {
        if (this.showBack) {
          Text('< 返回')
            .fontSize(15)
            .fontColor(AppColors.primary)
            .onClick(() => {
              if (this.onBackClick) {
                this.onBackClick()
              }
            })
        }
      }
      .width(70)
      .alignItems(VerticalAlign.Center)

      // 中间标题
      Text(this.title)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 右侧操作区
      Row() {
        if (this.rightLabel) {
          Text(this.rightLabel)
            .fontSize(15)
            .fontColor(AppColors.primary)
            .onClick(() => {
              if (this.onRightClick) {
                this.onRightClick()
              }
            })
        }
      }
      .width(70)
      .justifyContent(FlexAlign.End)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.bgTertiary)
    .border({ width: { bottom: 0.5 }, color: AppColors.separator })
  }
}
