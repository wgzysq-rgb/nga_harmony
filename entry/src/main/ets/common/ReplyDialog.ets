import { AppColors } from './Constants'
import { floatingLayerStore } from '../store/FloatingLayerStore'

@Component
export struct ReplyDialog {
  @Prop dialogTitle: string = '回复'
  @State replyText: string = ''
  @State sending: boolean = false
  private maxLength: number = 10000
  onSend?: (text: string) => void
  onClose: () => void = () => {}

  aboutToAppear(): void {
    floatingLayerStore.registerReplyCloseHandler(() => { this.requestClose() })
  }

  private requestClose(): void {
    if (this.replyText.trim().length > 0) {
      floatingLayerStore.showReplyConfirm(
        () => { this.onClose() },
        () => {}
      )
    } else {
      this.onClose()
    }
  }

  build() {
    Column() {
      Row() {
        Blank()
        Divider().width(40).height(4).borderRadius(2).margin({ top: 8, bottom: 4 })
        Blank()
      }.width('100%')

      Row() {
        Text(this.dialogTitle).fontSize(17).fontWeight(FontWeight.Bold).fontColor(AppColors.textPrimary).layoutWeight(1)
        Text('取消').fontSize(15).fontColor(AppColors.textSecondary)
          .onClick(() => { this.requestClose() }).padding({ left: 8, right: 8 })
      }.width('100%').padding({ left: 20, right: 12, top: 12, bottom: 4 })

      TextArea({ text: this.replyText, placeholder: '写回复...' })
        .width('92%').height(240).margin({ top: 8, bottom: 8 }).padding(14).fontSize(15)
        .borderRadius(12).backgroundColor(AppColors.bgSecondary)
        .onChange((value: string) => { this.replyText = value })
        .maxLength(this.maxLength)

      Row() {
        Text(`${this.replyText.length} / ${this.maxLength}`)
          .fontSize(11).fontColor(AppColors.textTertiary)
        Blank().layoutWeight(1)
        Button(this.sending ? '发送中...' : '发送')
          .fontSize(16).fontWeight(FontWeight.Medium).height(40)
          .fontColor(Color.White).backgroundColor(AppColors.primary)
          .borderRadius(20).padding({ left: 24, right: 24 })
          .enabled(!this.sending && this.replyText.trim().length > 0)
          .onClick(() => {
            if (this.onSend && this.replyText.trim()) {
              this.sending = true
              this.onSend(this.replyText.trim())
              this.sending = false
            }
          })
      }.width('92%').margin({ top: 4 }).alignItems(VerticalAlign.Center)
    }
    .width('100%').constraintSize({ maxWidth: 576 }).backgroundColor(AppColors.bg).borderRadius(16).alignItems(HorizontalAlign.Center).padding({ bottom: 20 })
  }
}
