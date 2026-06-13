import { AppColors } from '../constants/Constants'
import { unescapeHtml } from '../utils/Utils'
import { decodeAnonymousName } from '../../parser/AnonymousParser'

@Component
export struct AnonymousName {
  @Prop author: string = ''
  @Prop isAnonymous: boolean = false
  @Prop fontSize: number = 14
  @Prop normalColor: ResourceColor = AppColors.textTertiary

  build() {
    Row() {
      Text(this.isAnonymous ? decodeAnonymousName(this.author) : unescapeHtml(this.author))
        .fontSize(this.fontSize)
        .fontColor(this.isAnonymous ? AppColors.textTertiary : this.normalColor)
        .fontWeight(FontWeight.Medium)
      if (this.isAnonymous) {
        Text('(匿名)')
          .fontSize(Math.max(10, this.fontSize - 3))
          .fontColor(AppColors.textTertiary)
          .margin({ left: 4 })
      }
    }
  }
}
