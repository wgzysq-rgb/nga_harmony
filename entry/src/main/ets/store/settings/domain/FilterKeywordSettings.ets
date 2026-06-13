import { FilterListManager } from '../../FilterListManager'
import { SettingsContext } from '../SettingsContext'
import { SettingsState } from '../SettingsState'
import { FilterKeyword } from '../../../model/FilterKeyword'

/**
 * 关键词屏蔽设置域子 store。
 *
 * 承载 filterKeywords 列表（含启用状态）及其增删改查，提供获取已启用关键词列表。
 */
export class FilterKeywordSettings {
  private ctx: SettingsContext
  private manager: FilterListManager<FilterKeyword> = new FilterListManager<FilterKeyword>()

  constructor(ctx: SettingsContext) {
    this.ctx = ctx
  }

  addKeyword(keyword: string): void {
    const item = new FilterKeyword()
    item.keyword = keyword
    item.enabled = true
    this.ctx.state.filterKeywords = this.manager.add(item)
    this.ctx.persist()
  }

  removeKeyword(keyword: string): void {
    this.ctx.state.filterKeywords = this.manager.remove((k: FilterKeyword) => k.keyword === keyword)
    this.ctx.persist()
  }

  toggleKeyword(keyword: string): void {
    const list = this.manager.getList()
    for (let i = 0; i < list.length; i++) {
      if (list[i].keyword === keyword) {
        list[i].enabled = !list[i].enabled
        this.ctx.state.filterKeywords = [...list]
        this.ctx.persist()
        return
      }
    }
  }

  removeAllKeywords(): void {
    this.manager.clear()
    this.ctx.state.filterKeywords = this.manager.getList()
    this.ctx.persist()
  }

  getEnabledKeywords(): string[] {
    const result: string[] = []
    const list = this.ctx.state.filterKeywords
    for (let i = 0; i < list.length; i++) {
      if (list[i].enabled) {
        result.push(list[i].keyword)
      }
    }
    return result
  }

  /** 从持久化对象加载关键词列表（回填 FilterListManager） */
  load(saved: SettingsState): void {
    if (saved.filterKeywords) {
      this.ctx.state.filterKeywords = saved.filterKeywords
      this.manager.init(saved.filterKeywords)
    }
  }

  /** 重置关键词列表与 manager */
  reset(): void {
    this.manager = new FilterListManager<FilterKeyword>()
  }
}
