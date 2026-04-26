import { AppColors } from './Constants'
import { floatingLayerStore } from '../store/FloatingLayerStore'
import { replyManager, ReplyManagerClass, ReplyType } from './ReplyManager'
import { appStore } from '../store/AppStore'
import fileIo from '@ohos.file.fs'
import picker from '@ohos.file.picker'

interface FormatAction {
  label: string
  tag: string
}

const FORMAT_ACTIONS: FormatAction[] = [
  { label: '粗体', tag: 'b' },
  { label: '斜体', tag: 'i' },
  { label: '下划线', tag: 'u' },
  { label: '删除线', tag: 'del' },
  { label: '引用', tag: 'quote' },
  { label: '链接', tag: 'url' },
  { label: '@', tag: 'at' },
  { label: '图片', tag: 'img' },
]

@Component
export struct ReplyDialog {
  @Prop dialogTitle: string = '回复'
  @State replyText: string = ''
  @State sending: boolean = false
  @State isAnonymous: boolean = false
  @State isCommentMode: boolean = false
  @State selStart: number = 0
  @State selEnd: number = 0
  private textAreaController: TextAreaController = new TextAreaController()
  onSend?: (text: string, isAnony: boolean) => Promise<void>
  onClose: () => void = () => {}

  aboutToAppear(): void {
    this.isCommentMode = replyManager.type === ReplyType.COMMENT
    const draft: string = replyManager.loadDraft()
    if (draft.length > 0) {
      this.replyText = draft
    }
    floatingLayerStore.registerReplyCloseHandler(() => { this.requestClose() })
  }

  private requestClose(): void {
    if (this.replyText.trim().length > 0) {
      replyManager.saveDraft(this.replyText)
      floatingLayerStore.showReplyConfirm()
    } else {
      this.onClose()
    }
  }

  private onModeChange(commentMode: boolean): void {
    if (commentMode === this.isCommentMode) {
      return
    }
    if (replyManager.canToggleComment) {
      replyManager.toggleMode()
      this.isCommentMode = commentMode
    }
  }

  private applyFormat(action: FormatAction): void {
    const tag: string = action.tag
    if (tag === 'url') {
      this.replyText = ReplyManagerClass.insertUrl(this.replyText, this.selStart, this.selEnd)
    } else if (tag === 'at') {
      this.replyText = ReplyManagerClass.insertAtTag(this.replyText, this.selStart, this.selEnd)
    } else if (tag === 'img') {
      this.handleImagePick()
    } else {
      this.replyText = ReplyManagerClass.wrapSelectedText(this.replyText, this.selStart, this.selEnd, tag)
    }
  }

  private async handleImagePick(): Promise<void> {
    try {
      const photoPicker: picker.PhotoViewPicker = new picker.PhotoViewPicker()
      const pickResult: picker.PhotoSelectResult = await photoPicker.select({ maxSelectNumber: 1 })
      const photoUris: string[] = pickResult.photoUris
      if (!photoUris || photoUris.length === 0) {
        return
      }
      const uri: string = photoUris[0]
      if (!uri || uri.length === 0) {
        return
      }
      const fileName: string = uri.split('/').pop() || 'image.jpg'
      appStore.showToast('正在上传图片...')

      let buf: ArrayBuffer = new ArrayBuffer(0)
      try {
        const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
        const stat = fileIo.statSync(uri)
        buf = new ArrayBuffer(stat.size)
        fileIo.readSync(file.fd, buf)
        fileIo.closeSync(file)
      } catch (readErr) {
        appStore.showToast('读取图片失败')
        return
      }

      const imgUrl: string = await replyManager.uploadImage(buf, fileName)
      if (!imgUrl) {
        appStore.showToast('上传图片失败')
        return
      }

      const imgTag: string = '[img]./' + imgUrl + '.medium.jpg[/img]'
      this.replyText = ReplyManagerClass.insertImg(this.replyText, this.selStart, this.selEnd, imgTag)
      appStore.showToast('图片已插入')
    } catch (e) {
      // 用户取消选择 — 静默处理
    }
  }

  private doSend(): void {
    if (!this.onSend || (!this.replyText.trim() && !replyManager.shouldQuote)) {
      return
    }
    if (this.isCommentMode) {
      const byteLen: number = this.getByteLength(this.replyText.trim())
      if (byteLen < 6 || byteLen > 650) {
        appStore.showToast('贴条长度需在6~650字节之间')
        return
      }
    }
    this.sending = true
    this.onSend(this.replyText.trim(), this.isAnonymous).then(() => {
      replyManager.clearDraft()
      this.onClose()
    }).finally(() => {
      this.sending = false
    })
  }

  private getByteLength(str: string): number {
    let len: number = 0
    for (let i: number = 0; i < str.length; i++) {
      const code: number = str.charCodeAt(i)
      if (code <= 0x7f) { len++ }
      else if (code <= 0x7ff) { len += 2 }
      else if (code <= 0xffff) { len += 3 }
      else { len += 4 }
    }
    return len
  }

  build() {
    Column() {
      // 拖拽指示条
      Row() {
        Blank()
        Divider().width(36).height(3).borderRadius(2).margin({ top: 6, bottom: 4 })
        Blank()
      }.width('100%')

      // 标题行：模式切换 + 取消
      Row() {
        if (replyManager.canToggleComment) {
          Row() {
            Text('回复')
              .fontSize(14).fontWeight(this.isCommentMode ? FontWeight.Regular : FontWeight.Bold)
              .fontColor(this.isCommentMode ? AppColors.textTertiary : Color.White)
              .padding({ left: 14, right: 14, top: 5, bottom: 5 })
              .backgroundColor(this.isCommentMode ? AppColors.bgSecondary : AppColors.primary)
              .borderRadius({ topLeft: 14, bottomLeft: 14 })
              .onClick(() => { this.onModeChange(false) })

            Text('贴条')
              .fontSize(14).fontWeight(this.isCommentMode ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.isCommentMode ? Color.White : AppColors.textTertiary)
              .padding({ left: 14, right: 14, top: 5, bottom: 5 })
              .backgroundColor(this.isCommentMode ? AppColors.primary : AppColors.bgSecondary)
              .borderRadius({ topRight: 14, bottomRight: 14 })
              .onClick(() => { this.onModeChange(true) })
          }
          .alignItems(VerticalAlign.Center)
        } else {
          Text(this.dialogTitle).fontSize(17).fontWeight(FontWeight.Bold).fontColor(AppColors.textPrimary)
        }

        Blank().layoutWeight(1)

        Text('取消').fontSize(15).fontColor(AppColors.textSecondary)
          .onClick(() => { this.requestClose() }).padding({ left: 8, right: 4 })
      }
      .width('100%').padding({ left: 16, right: 12, top: 6, bottom: 6 })

      // 贴条提示
      if (this.isCommentMode) {
        Row() {
          Text('贴条将附着在该楼层下方（6~650字节）')
            .fontSize(11).fontColor(AppColors.textTertiary)
        }.width('100%').padding({ top: 2, bottom: 2 })
      }

      // 格式工具栏
      Row() {
        Scroll() {
          Row() {
            ForEach(FORMAT_ACTIONS, (action: FormatAction) => {
              Text(action.label)
                .fontSize(13).fontColor(AppColors.primary)
                .fontWeight(FontWeight.Medium)
                .padding({ left: 9, right: 9, top: 3, bottom: 3 })
                .borderRadius(4)
                .backgroundColor(AppColors.bgSecondary)
                .margin({ right: 5 })
                .onClick(() => { this.applyFormat(action) })
            }, (action: FormatAction) => action.tag)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .width('100%')
      }
      .width('100%').padding({ top: 4, bottom: 4 })

      // 正文输入
      TextArea({ text: this.replyText, placeholder: '输入内容...', controller: this.textAreaController })
        .width('100%').height(220).padding(12).fontSize(15)
        .borderRadius(8).backgroundColor(AppColors.bgSecondary)
        .onChange((value: string) => { this.replyText = value })
        .onTextSelectionChange((start: number, end: number) => {
          this.selStart = start
          this.selEnd = end
        })

      // 底栏：匿名 + 发送
      Row() {
        Row() {
          Toggle({ type: ToggleType.Checkbox, isOn: this.isAnonymous })
            .width(16).height(16)
            .onChange((value: boolean) => { this.isAnonymous = value })
          Text('匿名').fontSize(11).fontColor(AppColors.textTertiary).margin({ left: 3 })
        }
        .alignItems(VerticalAlign.Center)

        Blank().layoutWeight(1)

        Button(this.sending ? '...' : '发送')
          .fontSize(14).fontWeight(FontWeight.Medium).height(34)
          .fontColor(Color.White).backgroundColor(AppColors.primary)
          .borderRadius(17).padding({ left: 20, right: 20 })
          .enabled(!this.sending && (this.replyText.trim().length > 0 || replyManager.shouldQuote))
          .onClick(() => { this.doSend() })
      }
      .width('100%').margin({ top: 6, bottom: 4 }).alignItems(VerticalAlign.Center)
    }
    .width('100%').constraintSize({ maxWidth: 576 }).padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(AppColors.bg).borderRadius(16)
  }
}
