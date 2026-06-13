/**
 * Toast 消息提示状态管理
 */
@Observed
export class ToastState {
  message: string = ''
  visible: boolean = false
}

export class ToastManager {
  state: ToastState = new ToastState()
  private timer: number = -1

  show(msg: string): void {
    clearTimeout(this.timer)
    this.state.message = msg
    this.state.visible = true
    this.timer = setTimeout(() => {
      this.state.visible = false
      this.state.message = ''
    }, 2500)
  }
}
