import window from '@ohos.window';

let mainWindow: window.Window | null = null;

export function initStatusBarManager(win: window.Window): void {
  mainWindow = win;
}

export function updateStatusBarStyle(isDark: boolean): void {
  if (!mainWindow) {
    return;
  }
  try {
    const sysBarProps: window.SystemBarProperties = {
      statusBarColor: '#00000000',
      statusBarContentColor: isDark ? '#ffffff' : '#000000',
      navigationBarColor: '#00000000',
      navigationBarContentColor: isDark ? '#ffffff' : '#000000',
      isStatusBarLightIcon: isDark,
      isNavigationBarLightIcon: isDark
    };
    mainWindow.setWindowSystemBarProperties(sysBarProps);
  } catch (e) {
    // ignore
  }
}
