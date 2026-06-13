import { SettingsContext } from '../SettingsContext'
import { SettingsState } from '../SettingsState'

/**
 * 显示设置域子 store。
 *
 * 承载 fontSize / domainIndex / holdingHand / smartGrip / showSignature 字段及其 setter。
 */
export class DisplaySettings {
  private ctx: SettingsContext

  constructor(ctx: SettingsContext) {
    this.ctx = ctx
  }

  setFontSize(size: number): void {
    this.ctx.state.fontSize = size
    this.ctx.persist()
  }

  setDomainIndex(index: number): void {
    this.ctx.state.domainIndex = index
    this.ctx.persist()
  }

  setHoldingHand(value: number): void {
    this.ctx.state.holdingHand = value
    this.ctx.persist()
  }

  setSmartGrip(enabled: boolean): void {
    this.ctx.state.smartGrip = enabled
    this.ctx.persist()
  }

  /** 设置是否显示签名（同步 AppStorage 供 UI 响应式读取，并持久化） */
  setShowSignature(enabled: boolean): void {
    this.ctx.state.showSignature = enabled
    AppStorage.setOrCreate('showSignature', enabled)
    this.ctx.persist()
  }

  /** 从持久化对象加载显示字段 */
  load(saved: SettingsState): void {
    if (saved.fontSize) this.ctx.state.fontSize = saved.fontSize
    if (saved.domainIndex) this.ctx.state.domainIndex = saved.domainIndex
    if (saved.holdingHand !== undefined) this.ctx.state.holdingHand = saved.holdingHand
    if (saved.smartGrip !== undefined) this.ctx.state.smartGrip = saved.smartGrip
    if (saved.showSignature !== undefined) {
      this.ctx.state.showSignature = saved.showSignature
    }
  }
}
