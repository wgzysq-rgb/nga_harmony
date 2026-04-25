export enum FloatingPage {
  NONE = '',
  IMAGE_VIEWER = 'imageViewer',
  PROFILE_CARD = 'profileCard',
  REPLY_DIALOG = 'replyDialog'
}

const FLOATING_VERSION_KEY = 'floatingVersion'

export class FloatingLayerStoreClass {
  stack: string[] = []

  imageViewerUrls: string[] = []
  imageViewerIndex: number = 0

  profileCardUid: string = ''
  profileCardX: number = 0
  profileCardY: number = 0

  replyDialogTitle: string = '回复'
  replyOnSend?: (text: string) => Promise<void>

  get top(): string {
    return this.stack.length > 0 ? this.stack[this.stack.length - 1] : ''
  }

  get size(): number {
    return this.stack.length
  }

  private notify(): void {
    AppStorage.set(FLOATING_VERSION_KEY, (AppStorage.get<number>(FLOATING_VERSION_KEY) ?? 0) + 1)
  }

  push(page: string): void {
    const idx = this.stack.indexOf(page)
    if (idx >= 0) {
      const next = [...this.stack]
      next.splice(idx, 1)
      next.push(page)
      this.stack = next
    } else {
      this.stack = [...this.stack, page]
    }
    this.notify()
  }

  pop(): boolean {
    if (this.stack.length > 0) {
      this.stack = this.stack.slice(0, -1)
      this.notify()
      return true
    }
    return false
  }

  remove(page: string): void {
    this.stack = this.stack.filter(p => p !== page)
    this.notify()
  }

  clear(): void {
    this.stack = []
    this.notify()
  }

  // Reply close handler (for system back interception)
  private _replyCloseHandler: (() => void) | null = null

  registerReplyCloseHandler(handler: (() => void) | null): void {
    this._replyCloseHandler = handler
  }

  notifyReplyCloseRequested(): void {
    if (this._replyCloseHandler) {
      this._replyCloseHandler()
    }
  }

  // Confirm dialog (simplified)
  replyConfirmActive: boolean = false

  showReplyConfirm(): void {
    this.replyConfirmActive = true
  }

  hideReplyConfirm(): void {
    this.replyConfirmActive = false
  }

  confirmAbandon(): void {
    this.registerReplyCloseHandler(null)
    this.stack = this.stack.filter(p => p !== FloatingPage.REPLY_DIALOG)
    this.replyConfirmActive = false
    this.notify()
  }
}

export const floatingLayerStore = new FloatingLayerStoreClass()
