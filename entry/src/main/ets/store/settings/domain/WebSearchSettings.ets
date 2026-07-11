/**
 * 联网搜索设置域子 store。
 *
 * 管理联网搜索提供商配置的增删改查及激活切换，
 * 遵循 SettingsContext 注入模式，子 store 之间无横向 import。
 */

import { SettingsContext } from '../SettingsContext'
import { SettingsState } from '../SettingsState'
import type { WebSearchProviderProfile } from '../../../model/WebSearchConfig'
import { KEY_AI_CONFIG_VERSION } from '../../../common/constants/AppStorageKeys'
import { bumpAppStorageVersion } from '../../../common/utils/AppStorageVersion'

/** 生成简单唯一 ID */
function generateId(): string {
  return 'ws_' + Date.now() + '_' + Math.floor(Math.random() * 10000)
}

/**
 * 联网搜索设置域子 store。
 *
 * 管理联网搜索提供商配置的增删改查及激活切换。
 */
export class WebSearchSettings {
  /** 设置域上下文。 */
  private ctx: SettingsContext

  /**
   * 创建联网搜索设置域子 store。
   *
   * @param ctx - 设置域共享上下文
   */
  constructor(ctx: SettingsContext) {
    this.ctx = ctx
  }

  /**
   * 添加新的搜索提供商配置。
   *
   * @param profile - 新配置（id 字段被自动赋值）
   */
  addProfile(profile: WebSearchProviderProfile): void {
    profile.id = generateId()
    this.ctx.state.webSearchProfiles = [...this.ctx.state.webSearchProfiles, profile]
    this.ctx.persist()
    this.notifyConfigChanged()
  }

  /**
   * 更新已有的搜索提供商配置。
   *
   * @param profile - 已变更的配置
   */
  updateProfile(profile: WebSearchProviderProfile): void {
    const newList: WebSearchProviderProfile[] = []
    for (let i = 0; i < this.ctx.state.webSearchProfiles.length; i++) {
      if (this.ctx.state.webSearchProfiles[i].id === profile.id) {
        newList.push(profile)
      } else {
        newList.push(this.ctx.state.webSearchProfiles[i])
      }
    }
    this.ctx.state.webSearchProfiles = newList
    this.ctx.persist()
    this.notifyConfigChanged()
  }

  /**
   * 删除指定 ID 的搜索提供商配置。
   *
   * 若删除的是当前激活配置，自动切换到剩余配置的第一项。
   *
   * @param id - 待删除的配置 ID
   */
  deleteProfile(id: string): void {
    const newList: WebSearchProviderProfile[] = []
    for (let i = 0; i < this.ctx.state.webSearchProfiles.length; i++) {
      if (this.ctx.state.webSearchProfiles[i].id !== id) {
        newList.push(this.ctx.state.webSearchProfiles[i])
      }
    }
    this.ctx.state.webSearchProfiles = newList

    if (this.ctx.state.activeWebSearchProfileId === id ||
      !this.hasProfile(this.ctx.state.activeWebSearchProfileId)) {
      this.ctx.state.activeWebSearchProfileId = newList.length > 0 ? newList[0].id : ''
    }

    this.ctx.persist()
    this.notifyConfigChanged()
  }

  /**
   * 设置当前激活的搜索提供商配置。
   *
   * @param id - 配置 ID
   */
  setActiveProfile(id: string): void {
    this.ctx.state.activeWebSearchProfileId = this.hasProfile(id) ? id : ''
    this.ctx.persist()
    this.notifyConfigChanged()
  }

  /**
   * 获取当前激活的搜索提供商配置。
   *
   * @returns 激活的配置，若未选择或配置已不存在则返回 null
   */
  getActiveProfile(): WebSearchProviderProfile | null {
    for (let i = 0; i < this.ctx.state.webSearchProfiles.length; i++) {
      if (this.ctx.state.webSearchProfiles[i].id === this.ctx.state.activeWebSearchProfileId) {
        return this.ctx.state.webSearchProfiles[i]
      }
    }
    return null
  }

  /** 从持久化对象加载搜索设置 */
  load(saved: SettingsState): void {
    if (saved.webSearchProfiles) {
      this.ctx.state.webSearchProfiles = saved.webSearchProfiles
    }
    if (saved.activeWebSearchProfileId !== undefined) {
      this.ctx.state.activeWebSearchProfileId =
        this.hasProfile(saved.activeWebSearchProfileId) ? saved.activeWebSearchProfileId : ''
    }
  }

  /** 重置搜索设置为默认 */
  reset(): void {
  }

  /**
   * 判断指定配置是否存在。
   *
   * @param id - 配置 ID
   * @returns 配置是否存在
   */
  private hasProfile(id: string): boolean {
    if (id.length === 0) {
      return false
    }
    for (let i = 0; i < this.ctx.state.webSearchProfiles.length; i++) {
      if (this.ctx.state.webSearchProfiles[i].id === id) {
        return true
      }
    }
    return false
  }

  /**
   * 通知依赖 AI 配置摘要的页面刷新。
   */
  private notifyConfigChanged(): void {
    bumpAppStorageVersion(KEY_AI_CONFIG_VERSION)
  }
}
