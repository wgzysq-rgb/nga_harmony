import { SettingsContext } from '../SettingsContext'
import { SettingsState } from '../SettingsState'

/**
 * 阅读设置域子 store。
 *
 * 承载帖子翻页模式（无缝 / 分页）与向前预加载页数字段及其 setter。
 */
export class ReadingSettings {
  private ctx: SettingsContext

  constructor(ctx: SettingsContext) {
    this.ctx = ctx
  }

  setThreadNavMode(v: string): void {
    this.ctx.state.threadNavMode = v
    this.ctx.persist()
  }

  /** 设置预加载页数（0~5，0 表示关闭预加载） */
  setPrefetchPageCount(v: number): void {
    this.ctx.state.prefetchPageCount = Math.max(0, Math.min(5, v))
    this.ctx.persist()
  }

  /** 从持久化对象加载阅读字段 */
  load(saved: SettingsState): void {
    if (saved.threadNavMode !== undefined) this.ctx.state.threadNavMode = saved.threadNavMode
    if (saved.prefetchPageCount !== undefined) {
      this.ctx.state.prefetchPageCount = saved.prefetchPageCount
    }
  }
}
