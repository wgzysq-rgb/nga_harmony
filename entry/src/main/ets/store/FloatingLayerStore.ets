export enum FloatingPage {
  NONE = '',
  IMAGE_VIEWER = 'imageViewer',
  PROFILE_CARD = 'profileCard',
  REPLY_DIALOG = 'replyDialog'
}

class FloatingLayerStoreClass {
  private _stack: string[] = []
  private _version: number = 0

  imageViewerUrls: string[] = []
  imageViewerIndex: number = 0

  profileCardUid: string = ''
  profileCardX: number = 0
  profileCardY: number = 0

  replyDialogTitle: string = '回复'
  replyOnSend?: (text: string) => void

  get top(): string {
    return this._stack.length > 0 ? this._stack[this._stack.length - 1] : ''
  }

  get size(): number {
    return this._stack.length
  }

  push(page: string): void {
    const idx = this._stack.indexOf(page)
    if (idx >= 0) {
      this._stack.splice(idx, 1)
    }
    this._stack.push(page)
    this.bump()
  }

  pop(): boolean {
    if (this._stack.length > 0) {
      this._stack.pop()
      this.bump()
      return true
    }
    return false
  }

  remove(page: string): void {
    const idx = this._stack.indexOf(page)
    if (idx >= 0) {
      this._stack.splice(idx, 1)
      this.bump()
    }
  }

  replyConfirmActive: boolean = false
  private _replyCloseHandler: (() => void) | null = null
  replyConfirmOnConfirm: (() => void) | null = null
  replyConfirmOnCancel: (() => void) | null = null

  registerReplyCloseHandler(handler: (() => void) | null): void {
    this._replyCloseHandler = handler
  }

  notifyReplyCloseRequested(): void {
    if (this._replyCloseHandler) {
      this._replyCloseHandler()
    }
  }

  showReplyConfirm(onConfirm: () => void, onCancel: () => void): void {
    this.replyConfirmOnConfirm = onConfirm
    this.replyConfirmOnCancel = onCancel
    this.replyConfirmActive = true
    this.bump()
  }

  hideReplyConfirm(): void {
    this.replyConfirmActive = false
    this.replyConfirmOnConfirm = null
    this.replyConfirmOnCancel = null
    this.bump()
  }

  clear(): void {
    this._stack = []
    this.bump()
  }

  private bump(): void {
    this._version++
    AppStorage.setOrCreate('floatingStackVersion', this._version)
  }
}

export const floatingLayerStore = new FloatingLayerStoreClass()
