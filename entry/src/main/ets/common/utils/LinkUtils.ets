import { common, Context } from '@kit.AbilityKit'
import { routerStore, Screen } from '../../store/RouterStore'
import { floatingLayerStore, FloatingPage } from '../../store/FloatingLayerStore'

export function openImageViewer(urls: string[], index: number): void {
  floatingLayerStore.imageViewerUrls = urls
  floatingLayerStore.imageViewerIndex = index
  floatingLayerStore.push(FloatingPage.IMAGE_VIEWER)
}

export function handleForumLink(
  href: string,
  context: Context,
  onProfileClick?: (uid: string) => void
): void {
  if (href.startsWith('#/thread?')) {
    const params = new Map<string, string>()
    const query = href.substring(href.indexOf('?') + 1)
    const parts = query.split('&')
    for (let i = 0; i < parts.length; i++) {
      const kv = parts[i].split('=')
      if (kv.length === 2) params.set(kv[0], kv[1])
    }
    const tid = params.get('tid') || ''
    const pageStr = params.get('page') || '1'
    const pid = params.get('pid') || ''
    const page = parseInt(pageStr, 10) || 1
    if (tid.length > 0) {
      routerStore.navigateActivity(Screen.thread(tid, page, pid))
    }
  } else if (href.startsWith('#/profile?')) {
    const uidStr = href.split('uid=')[1]
    if (uidStr) {
      const uid = uidStr.split('&')[0]
      if (onProfileClick) {
        onProfileClick(uid)
      }
    }
  } else if (href.startsWith('http://') || href.startsWith('https://')) {
    try {
      (context as common.UIAbilityContext).openLink(href)
    } catch (e) {}
  }
}
