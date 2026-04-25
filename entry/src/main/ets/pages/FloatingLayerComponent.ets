import { floatingLayerStore, FloatingPage } from '../store/FloatingLayerStore'
import { AppColors } from '../common/Constants'
import { ImageViewer } from '../common/ImageViewer'
import { ProfileCardPopup } from '../common/ProfileCardPopup'
import { ReplyDialog } from '../common/ReplyDialog'

function topOf(stack: string[]): string {
  return stack.length > 0 ? stack[stack.length - 1] : ''
}

@Component
export struct FloatingLayerComponent {
  @StorageProp('floatingVersion') floatingVersion: number = 0
  @Prop currentBreakpoint: string = 'sm'

  build() {
    Stack() {
      if (topOf(floatingLayerStore.stack) === FloatingPage.IMAGE_VIEWER) {
        ImageViewer({
          urls: floatingLayerStore.imageViewerUrls,
          initialIndex: floatingLayerStore.imageViewerIndex,
          onClose: () => { floatingLayerStore.remove(FloatingPage.IMAGE_VIEWER) }
        })
      }
      if (topOf(floatingLayerStore.stack) === FloatingPage.PROFILE_CARD) {
        Stack() {
          Column().width('100%').height('100%').backgroundColor('#33000000')
            .onClick(() => { floatingLayerStore.remove(FloatingPage.PROFILE_CARD) })
          ProfileCardPopup({
            targetUid: floatingLayerStore.profileCardUid,
            currentBreakpoint: this.currentBreakpoint,
            onClose: () => { floatingLayerStore.remove(FloatingPage.PROFILE_CARD) }
          })
          .position({
            x: floatingLayerStore.profileCardX,
            y: floatingLayerStore.profileCardY
          })
        }
        .width('100%').height('100%')
      }
      if (topOf(floatingLayerStore.stack) === FloatingPage.REPLY_DIALOG) {
        Stack() {
          Column().width('100%').height('100%').backgroundColor('#33000000')

          Column().width('100%').height('100%')
            .onClick(() => { floatingLayerStore.notifyReplyCloseRequested() })

          Column() {
            ReplyDialog({
              dialogTitle: floatingLayerStore.replyDialogTitle,
              onSend: floatingLayerStore.replyOnSend,
              onClose: () => {
                floatingLayerStore.registerReplyCloseHandler(null)
                floatingLayerStore.remove(FloatingPage.REPLY_DIALOG)
              }
            })
          }
          .align(Alignment.Center)
        }
        .width('100%').height('100%')
      }

      if (floatingLayerStore.replyConfirmActive) {
        Stack() {
          Column().width('100%').height('100%').backgroundColor('#33000000')
            .onClick(() => {
              floatingLayerStore.hideReplyConfirm()
            })
          Column() {
            Text('放弃编辑？').fontSize(17).fontWeight(FontWeight.Bold).fontColor(AppColors.textPrimary)
              .margin({ top: 20 })
            Text('已输入的内容将丢失').fontSize(14).fontColor(AppColors.textSecondary)
              .margin({ top: 8 })
            Row() {
              Text('继续编辑').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.primary)
                .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 14, bottom: 14 })
                .onClick(() => {
                  floatingLayerStore.hideReplyConfirm()
                })
              Divider().vertical(true).height(24).color(AppColors.separator).alignSelf(ItemAlign.Center)
              Text('放弃').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppColors.destructive)
                .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 14, bottom: 14 })
                .onClick(() => {
                  floatingLayerStore.confirmAbandon()
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
      (topOf(floatingLayerStore.stack) === FloatingPage.IMAGE_VIEWER ||
       topOf(floatingLayerStore.stack) === FloatingPage.PROFILE_CARD ||
       topOf(floatingLayerStore.stack) === FloatingPage.REPLY_DIALOG)
        ? HitTestMode.Default : HitTestMode.None
    )
  }
}
