import { AppColors } from './Constants'
import { floatingLayerStore } from '../store/FloatingLayerStore'

@Component
export struct ReplyDialog {
  @Prop dialogTitle: string = '回复'
  @State replyText: string = ''
  @State sending: boolean = false
  @State replyTargetLou: number = 0
  private maxLength: number = 10000
  onSend?: (text: string) => Promise<void>
  onClose: () => void = () => {}

  aboutToAppear(): void {
    this.replyTargetLou = floatingLayerStore.replyTargetLou
    floatingLayerStore.registerReplyCloseHandler(() => { this.requestClose() })
  }

  private requestClose(): void {
    if (this.replyText.trim().length > 0) {
      floatingLayerStore.showReplyConfirm()
    } else {
      this.onClose()
    }
  }

  private clearReplyTarget(): void {
    this.replyTargetLou = 0
    floatingLayerStore.replyTargetLou = 0
    floatingLayerStore.replyDialogTitle = '写回复'
  }

  private doSend(): void {
    if (!this.onSend || !this.replyText.trim()) return
    this.sending = true
    this.onSend(this.replyText.trim()).then(() => {
      this.onClose()
    }).finally(() => {
      this.sending = false
    })
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

      if (this.replyTargetLou > 0) {
        Row() {
          Text(`回复 #${this.replyTargetLou} 的帖子`)
            .fontSize(13).fontColor(AppColors.primary)
          Blank().layoutWeight(1)
          Text('✕').fontSize(14).fontColor(AppColors.textTertiary)
            .onClick(() => { this.clearReplyTarget() })
            .padding({ left: 8, right: 4 })
        }
        .width('92%').padding({ top: 4, bottom: 4 })
        .alignItems(VerticalAlign.Center)
      }

      TextArea({ text: this.replyText, placeholder: this.replyTargetLou > 0 ? `回复 #${this.replyTargetLou}...` : '写回复...' })
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
          .onClick(() => { this.doSend() })
      }.width('92%').margin({ top: 4 }).alignItems(VerticalAlign.Center)
    }
    .width('100%').constraintSize({ maxWidth: 576 }).backgroundColor(AppColors.bg).borderRadius(16).alignItems(HorizontalAlign.Center).padding({ bottom: 20 })
  }
}
