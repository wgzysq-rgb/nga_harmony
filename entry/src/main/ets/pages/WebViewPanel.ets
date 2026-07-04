import { webview } from '@kit.ArkWeb'
import { common, bundleManager } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { PanelNavBar } from '../common/components/PanelNavBar'
import { routerStore, Screen } from '../store/RouterStore'
import { getSession, getActiveDomain } from '../service/NgaApi'
import { appStore } from '../store/AppStore'
import { Logger, DOMAIN_UI, formatError } from '../common/utils/Logger'
import { KEY_USE_INTERNAL_WEBVIEW } from '../common/constants/AppStorageKeys'
import { handleForumLink } from '../common/utils/LinkUtils'

const logger = new Logger(DOMAIN_UI, 'WebViewPanel')

/** NGA 域名列表（与 LinkUtils 保持同步） */
const NGA_DOMAINS: string[] = [
  'bbs.nga.cn',
  'ngabbs.com',
  'nga.178.com',
]

/** 已知支持外部 APP 拉起的域名列表 */
const EXTERNAL_APP_DOMAINS: string[] = [
  'bilibili.com',
  'www.bilibili.com',
  'b23.tv',
  'douyin.com',
  'www.douyin.com',
  'youtube.com',
  'www.youtube.com',
  'm.youtube.com',
  'zhihu.com',
  'www.zhihu.com',
  'weibo.com',
  'www.weibo.com',
  'm.weibo.cn',
  'taobao.com',
  'www.taobao.com',
  'tmall.com',
  'www.tmall.com',
  'jd.com',
  'www.jd.com',
  'xiaohongshu.com',
  'www.xiaohongshu.com',
]

@Component
export struct WebViewPanel {
  @Prop url: string = ''
  private controller: webview.WebviewController = new webview.WebviewController()
  @State pageTitle: string = ''
  @State isLoading: boolean = true
  @State progress: number = 0

  aboutToAppear(): void {
    this.injectCookies()
  }

  private injectCookies(): void {
    if (!appStore.auth.isAuthenticated) {
      return
    }
    const session = getSession(appStore.auth.token)
    if (!session) {
      return
    }
    const baseUrl: string = getActiveDomain()
    try {
      webview.WebCookieManager.configCookieSync(baseUrl, 'ngaPassportUid=' + session.uid + '; Path=/')
      webview.WebCookieManager.configCookieSync(baseUrl, 'ngaPassportCid=' + session.cid + '; Path=/')
    } catch (e) {
      logger.error('[WebViewPanel] setCookie failed: %{public}s', formatError(e))
    }
  }

  /**
   * 从 URL 中提取主机名。
   */
  private extractHostname(url: string): string {
    const match = url.match(/^https?:\/\/([^/]+)/)
    return match ? match[1] : url
  }

  /**
   * 判断主机名是否属于 NGA 域名。
   */
  private isNgaDomain(hostname: string): boolean {
    const lower: string = hostname.toLowerCase()
    for (let i = 0; i < NGA_DOMAINS.length; i++) {
      if (lower === NGA_DOMAINS[i] || lower.endsWith('.' + NGA_DOMAINS[i])) {
        return true
      }
    }
    return false
  }

  /**
   * 判断主机名是否属于已知支持外部 APP 拉起的域名。
   */
  private isKnownExternalAppDomain(hostname: string): boolean {
    const lower: string = hostname.toLowerCase()
    for (let i = 0; i < EXTERNAL_APP_DOMAINS.length; i++) {
      if (lower === EXTERNAL_APP_DOMAINS[i] || lower.endsWith('.' + EXTERNAL_APP_DOMAINS[i])) {
        return true
      }
    }
    return false
  }

  /**
   * 三段式 URL 路由分发。
   * 返回值 true=已拦截（WebView 不应加载），false=继续加载。
   */
  private handleUrlIntercept(targetUrl: string): boolean {
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      return false
    }

    const hostname: string = this.extractHostname(targetUrl)
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext

    // ─── 第一优先级：NGA 链接 → 回归原生页面 ───
    if (this.isNgaDomain(hostname)) {
      // 委托 handleForumLink 做原生路由（帖子详情 / 用户主页 / WebView 兜底）
      handleForumLink(targetUrl, context)
      return true
    }

    // ─── 第二优先级：已知外部 APP 域名 → 直接拉起 ───
    if (this.isKnownExternalAppDomain(hostname)) {
      try {
        context.openLink(targetUrl)
      } catch (e) {}
      return true
    }

    // ─── 第三优先级：检查是否有其他 APP 能响应 ───
    try {
      if (bundleManager.canOpenLink(targetUrl)) {
        context.openLink(targetUrl)
        return true
      }
    } catch (e) {
      // canOpenLink 可能因 querySchemes 未配置而抛异常
    }

    // ─── 无 APP 响应：按用户设置决策 ───
    const useInternalWebView: boolean = AppStorage.get<boolean>(KEY_USE_INTERNAL_WEBVIEW) ?? true
    if (!useInternalWebView) {
      try {
        context.openLink(targetUrl)
      } catch (e) {}
      return true
    }

    // 用户开启「内置网页浏览」：让 WebView 继续加载此 URL
    return false
  }

  /** 在系统浏览器中打开当前页面 */
  private openInBrowser(): void {
    const currentUrl: string = this.controller.getUrl()
    if (!currentUrl) {
      return
    }
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    try {
      context.openLink(currentUrl, { hideFailureTipDialog: true })
    } catch (e) {
      logger.error('[WebViewPanel] openInBrowser failed: %{public}s', formatError(e))
    }
  }

  build() {
    Column() {
      // ─── 导航栏（标题 + 右侧"浏览器打开"按钮） ───
      PanelNavBar({
        title: this.pageTitle || 'NGA网页版',
        onBack: (): void => {
          routerStore.back()
        },
        rightLabel: '浏览器打开',
        rightLabelColor: '#007AFF',
        onRightClick: (): void => {
          this.openInBrowser()
        }
      })

      // ─── 加载进度条 ───
      if (this.isLoading) {
        Progress({ value: this.progress, total: 100 })
          .width('100%')
          .height(2)
          .color('#007AFF')
      }

      // ─── WebView ───
      Web({ src: this.url, controller: this.controller })
        .layoutWeight(1).width('100%')
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .geolocationAccess(true)
        .zoomAccess(true)
        .overviewModeAccess(true)
        .onControllerAttached(() => {
          try {
            this.controller.setCustomUserAgent('Mozilla/5.0 (Linux; Android 10; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.144 Mobile Safari/537.36')
          } catch (e) { logger.error('setCustomUserAgent failed: %{public}s', (e as Error).message) }
        })
        .onTitleReceive((event: Object): void => {
          const evt = event as Record<string, Object>
          this.pageTitle = String(evt['title'] ?? '')
        })
        // 页面加载进度
        .onProgressChange((event): void => {
          if (event) {
            this.progress = event.newProgress
            if (event.newProgress >= 100) {
              setTimeout(() => { this.isLoading = false }, 300)
            }
          }
        })
        // 拦截页面内所有链接跳转，走三段式路由
        .onLoadIntercept((event): boolean => {
          const targetUrl: string = event.data.getRequestUrl()
          return this.handleUrlIntercept(targetUrl)
        })
        // 加载失败处理
        .onErrorReceive((event): void => {
          if (event?.request) {
            logger.error('[WebViewPanel] load error: %{public}s', event.request.getRequestUrl())
          }
        })
    }
    .width('100%').height('100%')
  }
}
