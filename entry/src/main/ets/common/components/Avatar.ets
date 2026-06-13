/**
 * 头像组件 - 从 React Avatar.tsx 迁移
 * 支持图片加载失败时显示首字母
 */

import { AppColors } from '../constants/Constants'
import { getAvatarUrl, nameToHue, hslToHex, getInitial } from '../utils/Utils'

@Component
export struct Avatar {
  @Prop avatar: string = ''
  @Prop uid: string = ''
  @Prop name: string = ''
  @Prop avatarSize: number = 40
  @State imgError: boolean = false

  build() {
    Stack() {
      // 首字母：当有头像图片且未出错时隐藏，否则显示
      Text(getInitial(this.name))
        .fontSize(this.avatarSize * 0.4)
        .fontColor(AppColors.white)
        .fontWeight(FontWeight.Bold)
        .visibility(this.getAvatarUrlStr() && !this.imgError ? Visibility.None : Visibility.Visible)

      // 头像图片：仅在 URL 有效且未出错时渲染
      if (this.getAvatarUrlStr() && !this.imgError) {
        Image(this.getAvatarUrlStr())
          .width(this.avatarSize)
          .height(this.avatarSize)
          .borderRadius(this.avatarSize / 2)
          .objectFit(ImageFit.Cover)
          .onError(() => {
            this.imgError = true
          })
      }
    }
    .width(this.avatarSize)
    .height(this.avatarSize)
    .borderRadius(this.avatarSize / 2)
    .backgroundColor(this.getBgColor())
  }

  private getAvatarUrlStr(): string {
    return getAvatarUrl(this.avatar, this.uid)
  }

  private getBgColor(): string {
    return hslToHex(nameToHue(this.name), 55, 55)
  }
}
