import { ConfigurationConstant } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { updateStatusBarStyle } from '../../../common/managers/StatusBarManager'
import { SettingsContext } from '../SettingsContext'
import { SettingsState } from '../SettingsState'
import { KEY_THEME_NAME, KEY_EFFECTIVE_COLOR_MODE } from '../../../common/constants/AppStorageKeys'

const TAG = 'ThemeSettings'
const DOMAIN = 0x0000

/**
 * 主题设置域子 store。
 *
 * 承载 theme 字段及其 setter、applyCurrentTheme（涉及 setColorMode / 状态栏样式）。
 */
export class ThemeSettings {
  private ctx: SettingsContext

  constructor(ctx: SettingsContext) {
    this.ctx = ctx
  }

  /** 设置主题并立即应用（持久化 + 切换颜色模式 + 更新状态栏） */
  setTheme(theme: string): void {
    this.ctx.state.theme = theme
    this.applyCurrentTheme()
    this.ctx.persist()
  }

  /** 按当前 theme 应用颜色模式与状态栏样式 */
  applyCurrentTheme(): void {
    let theme: string = this.ctx.state.theme
    if (theme === 'original' || theme === 'white') {
      theme = 'light'
    }
    let mode: number
    let effectiveTheme: string
    if (theme === 'system') {
      mode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
      effectiveTheme = AppStorage.get<string>(KEY_EFFECTIVE_COLOR_MODE) ?? 'light'
    } else if (theme === 'dark') {
      mode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      effectiveTheme = 'dark'
    } else {
      mode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
      effectiveTheme = 'light'
    }
    try {
      this.ctx.context?.getApplicationContext().setColorMode(mode)
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'setColorMode failed: %{public}s', JSON.stringify(err))
    }
    AppStorage.setOrCreate(KEY_THEME_NAME, theme)
    AppStorage.setOrCreate(KEY_EFFECTIVE_COLOR_MODE, effectiveTheme)

    try {
      updateStatusBarStyle(effectiveTheme === 'dark')
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'updateStatusBarStyle failed: %{public}s', JSON.stringify(err))
    }
  }

  /** 从持久化对象加载主题字段 */
  load(saved: SettingsState): void {
    if (saved.theme) this.ctx.state.theme = saved.theme
  }
}
