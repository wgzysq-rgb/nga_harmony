import type { Context } from '@kit.AbilityKit'
import { SettingsState } from './SettingsState'
import type { AuthState } from '../AuthStore'

/**
 * 域子 store 的共享依赖上下文。
 *
 * 由 SettingsStore 门面构造并注入各子 store。子 store 仅依赖此上下文 + SettingsState，
 * 子 store 之间不产生横向 import。包含：
 * - state：持久化根状态引用（子 store 直接读写其字段）
 * - persist：触发持久化的回调（指向门面的 persistSettings）
 * - auth：认证状态（favorites/checkin 需要 token/uid/isAuthenticated）
 * - context：AbilityContext（主题切换 setColorMode 需要）
 */
export class SettingsContext {
  state: SettingsState
  persist: () => void
  auth?: AuthState
  context?: Context

  constructor(state: SettingsState, persist: () => void) {
    this.state = state
    this.persist = persist
  }
}
