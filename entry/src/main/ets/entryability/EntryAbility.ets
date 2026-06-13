import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { display, window } from '@kit.ArkUI';
import { appStore } from '../store/AppStore';
import { initStatusBarManager, updateStatusBarStyle } from '../common/managers/StatusBarManager';
import { startNetworkMonitor } from '../common/managers/NetworkMonitor';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  private curBp: string = 'sm'

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 在 loadContent 前尽可能早地应用用户保存的主题，减少主题切换闪烁
    // 注意：此时 appStore 尚未 init，直接使用默认主题；appStore.init 完成后会通过 applyCurrentTheme 修正
    try {
      const appContext = this.context.getApplicationContext()
      appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
      AppStorage.setOrCreate('themeName', 'light')
      AppStorage.setOrCreate('effectiveColorMode', 'light')
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    // 初始化 AppStore（异步，Index 页面会等待 initialized 标志）
    appStore.init(this.context)
      .then(() => {
        hilog.info(DOMAIN, TAG, 'AppStore initialized');
      })
      .catch((e: Error) => {
        hilog.error(DOMAIN, TAG, 'AppStore init failed: %{public}s', JSON.stringify(e));
      });

    startNetworkMonitor();

    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    const themeName = AppStorage.get<string>('themeName') ?? 'light'
    if (themeName === 'system') {
      const isDark = newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      const effective = isDark ? 'dark' : 'light'
      AppStorage.setOrCreate('effectiveColorMode', effective)
      updateStatusBarStyle(isDark)
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }

      try {
        const mainWindow = windowStage.getMainWindowSync()

        mainWindow.setWindowLayoutFullScreen(true)

        initStatusBarManager(mainWindow)
        const isDark: boolean = (AppStorage.get<string>('effectiveColorMode') ?? 'light') === 'dark'
        updateStatusBarStyle(isDark)

        const avoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
        const density = display.getDefaultDisplaySync().densityPixels
        const topInset = avoidArea.topRect.height / density
        const bottomInset = avoidArea.bottomRect.height / density
        AppStorage.setOrCreate('statusBarHeight', topInset)
        AppStorage.setOrCreate('navBarHeight', bottomInset)

        this.updateBreakpoint(mainWindow.getWindowProperties().windowRect.width)
        mainWindow.on('windowSizeChange', (size: window.Size) => {
          this.updateBreakpoint(size.width)
        })
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'Failed to setup immersive mode. Cause: %{public}s', JSON.stringify(e))
      }
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    appStore.autoCheckinIfNeeded();
    appStore.refreshUnreadCount();
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // 应用进入后台时持久化所有数据，防止被系统杀死后丢失
    appStore.flushAll();
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }

  private updateBreakpoint(windowWidth: number): void {
    let densityPixels: number = 1
    try {
      densityPixels = display.getDefaultDisplaySync().densityPixels
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'getDefaultDisplaySync failed')
    }
    const widthVp = windowWidth / densityPixels
    let newBp: string = 'sm'
    if (widthVp < 600) {
      newBp = 'sm'
    } else if (widthVp < 840) {
      newBp = 'md'
    } else {
      newBp = 'lg'
    }
    if (this.curBp !== newBp) {
      this.curBp = newBp
      AppStorage.setOrCreate('currentBreakpoint', newBp)
      hilog.info(DOMAIN, TAG, 'Breakpoint changed to: %{public}s (%{public}f vp)', newBp, widthVp)
    }
  }
}
