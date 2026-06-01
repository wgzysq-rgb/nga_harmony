import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { display, window } from '@kit.ArkUI';
import { sessionStore } from '../service/SessionStore';
import { appStore } from '../store/AppStore';
import { browseHistoryStore } from '../store/BrowseHistoryStore';
import { voteRecordStore } from '../store/VoteRecordStore';
import { initStatusBarManager, updateStatusBarStyle } from '../common/StatusBarManager';
import { startNetworkMonitor } from '../common/NetworkMonitor';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';
const THEME_CACHE_FILE = 'theme_cache.txt'

export default class EntryAbility extends UIAbility {
  private curBp: string = 'sm'

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 在 loadContent 前尽可能早地应用用户保存的主题，减少主题切换闪烁
    try {
      const appContext = this.context.getApplicationContext()
      let initialTheme: string = 'light'
      try {
        const themeCachePath = appContext.cacheDir + '/' + THEME_CACHE_FILE
        const cachedTheme = fileIo.readTextSync(themeCachePath).trim()
        if (cachedTheme === 'dark' || cachedTheme === 'system') {
          initialTheme = cachedTheme
        }
      } catch (e) {
        // 尚未缓存过主题，使用默认值
      }
      if (initialTheme === 'system') {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
        const isDark = this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
        AppStorage.setOrCreate('effectiveColorMode', isDark ? 'dark' : 'light')
      } else if (initialTheme === 'dark') {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
        AppStorage.setOrCreate('effectiveColorMode', 'dark')
      } else {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
        AppStorage.setOrCreate('effectiveColorMode', 'light')
      }
      AppStorage.setOrCreate('themeName', initialTheme)
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    // 初始化 SessionStore 和 AppStore（异步，Index 页面会等待 initialized 标志）
    Promise.all([sessionStore.init(this.context), appStore.init(this.context), browseHistoryStore.init(this.context), voteRecordStore.init(this.context)])
      .then(() => {
        hilog.info(DOMAIN, TAG, 'All stores initialized');
      })
      .catch((e: Error) => {
        hilog.error(DOMAIN, TAG, 'Store init failed: %{public}s', JSON.stringify(e));
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
    // 应用进入后台时持久化会话，防止被系统杀死后丢失
    sessionStore.flushNow();
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
