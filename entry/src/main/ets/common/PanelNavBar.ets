import { routerStore } from '../store/RouterStore'
import { AppColors } from './Constants'

@Component
export struct PanelNavBar {
  private title: string = ''
  @StorageProp('statusBarHeight') statusBarHeight: number = 0

  build() {
    Row() {
      Text('←').fontSize(22).fontColor(AppColors.primary)
        .onClick(() => routerStore.back()).padding({ left: 8, right: 8 })
      Text(this.title).fontSize(17).fontWeight(FontWeight.Bold).layoutWeight(1)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%').height(44 + this.statusBarHeight)
    .padding({ top: this.statusBarHeight })
    .backgroundColor(AppColors.bgTertiary)
    .border({ width: { bottom: 0.5 }, color: AppColors.separator }).alignItems(VerticalAlign.Center)
  }
}
