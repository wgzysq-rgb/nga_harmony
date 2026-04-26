import { floatingLayerStore, FloatingLayerStoreClass, FloatingPage } from '../store/FloatingLayerStore'
import { AppColors } from '../common/Constants'
import { ImageViewer } from '../common/ImageViewer'
import { ProfileCardPopup } from '../common/ProfileCardPopup'
import { ReplyDialog } from '../common/ReplyDialog'

@Component
export struct FloatingLayerComponent {
  @State private floating: FloatingLayerStoreClass = floatingLayerStore
  @Prop currentBreakpoint: string = 'sm'

  build() {
    Stack() {
      if (this.floating.top === FloatingPage.IMAGE_VIEWER) {
        ImageViewer({
          urls: this.floating.imageViewerUrls,
          initialIndex: this.floating.imageViewerIndex,
          onClose: () => { this.floating.remove(FloatingPage.IMAGE_VIEWER) }
        })
      }
      if (this.floating.top === FloatingPage.PROFILE_CARD) {
        Stack() {
          Column().width('100%').height('100%').backgroundColor('#33000000')
            .onClick(() => { this.floating.remove(FloatingPage.PROFILE_CARD) })
          ProfileCardPopup({
            targetUid: this.floating.profileCardUid,
            currentBreakpoint: this.currentBreakpoint,
            onClose: () => { this.floating.remove(FloatingPage.PROFILE_CARD) }
          })
          .position({
            x: this.floating.profileCardX,
            y: this.floating.profileCardY
          })
        }
        .width('100%').height('100%')
      }
      if (this.floating.top === FloatingPage.REPLY_DIALOG) {
        Stack() {
          Column().width('100%').height('100%').backgroundColor('#33000000')

          Column().width('100%').height('100%')
            .onClick(() => { this.floating.notifyReplyCloseRequested() })

          Column() {
            ReplyDialog({
              dialogTitle: this.floating.replyDialogTitle,
              onSend: this.floating.replyOnSend,
              onClose: () => {
                this.floating.registerReplyCloseHandler(null)
                this.floating.remove(FloatingPage.REPLY_DIALOG)
              }
            })
          }
          .align(Alignment.Center)
        }
        .width('100%').height('100%')
      }

      if (this.floating.top === FloatingPage.CONFIRM_DIALOG) {
        Stack() {
          Column().width('100%').height('100%').backgroundColor('#66000000')
            .onClick(() => { this.floating.hideConfirm() })
          Column() {
            Text(this.floating.confirmTitle)
              .fontSize(17).fontWeight(FontWeight.Bold)
              .margin({ top: 20, bottom: 8 })
            Text(this.floating.confirmMessage)
              .fontSize(14).fontColor('#8E8E93')
              .margin({ bottom: 20 })
            Divider().color('#E5E5EA')
            Row() {
              Button('取消')
                .layoutWeight(1).backgroundColor(Color.Transparent).fontColor('#007AFF')
                .onClick(() => { this.floating.hideConfirm() })
              Divider().vertical(true).height(20).color('#E5E5EA')
              Button(this.floating.confirmLabel)
                .layoutWeight(1).backgroundColor(Color.Transparent)
                .fontColor(this.floating.confirmDestructive ? '#FF3B30' : '#007AFF')
                .fontWeight(FontWeight.Bold)
                .onClick(() => {
                  const handler = this.floating.confirmOnConfirm
                  this.floating.hideConfirm()
                  if (handler) {
                    handler()
                  }
                })
            }.height(44)
          }
          .width(300).padding({ left: 20, right: 20 })
          .backgroundColor(Color.White).borderRadius(14)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%').height('100%')
      }

      if (this.floating.replyConfirmActive) {
        Stack() {
          Column().width('100%').height('100%').backgroundColor('#33000000')
            .onClick(() => {
              this.floating.hideReplyConfirm()
            })
          Column() {
            Text('放弃编辑？').fontSize(17).fontWeight(FontWeight.Bold).fontColor(AppColors.textPrimary)
              .margin({ top: 20 })
            Text('已保存为草稿，下次编辑可恢复').fontSize(14).fontColor(AppColors.textSecondary)
              .margin({ top: 8 })
            Row() {
              Text('继续编辑').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.primary)
                .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 14, bottom: 14 })
                .onClick(() => {
                  this.floating.hideReplyConfirm()
                })
              Divider().vertical(true).height(24).color(AppColors.separator).alignSelf(ItemAlign.Center)
              Text('放弃').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.destructive)
                .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 14, bottom: 14 })
                .onClick(() => {
                  this.floating.confirmAbandon()
                })
            }.width('100%').margin({ top: 16 })
            .border({ width: { top: 0.5 }, color: AppColors.separator })
          }
          .width(270)
          .backgroundColor(AppColors.bg)
          .borderRadius(14)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%').height('100%')
      }
    }
    .width('100%').height('100%')
    .hitTestBehavior(
      (this.floating.top === FloatingPage.IMAGE_VIEWER ||
       this.floating.top === FloatingPage.PROFILE_CARD ||
       this.floating.top === FloatingPage.REPLY_DIALOG ||
       this.floating.top === FloatingPage.CONFIRM_DIALOG)
        ? HitTestMode.Default : HitTestMode.None
    )
  }
}
