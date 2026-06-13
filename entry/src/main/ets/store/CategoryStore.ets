import { hilog } from '@kit.PerformanceAnalysisKit'
import { getForumCategories } from '../service/NgaApi'
import { PreferencesStore } from '../common/infra/PreferencesStore'
import { SerialQueue } from '../common/infra/SerialQueue'
import type { Category } from '../model/Forum'
import type { AuthState } from './AuthStore'

const TAG = 'CategoryStore'
const DOMAIN = 0x0000

/**
 * 论坛分类缓存管理
 */
export class CategoryStore {
  cachedCategories: Category[] = []
  private store!: PreferencesStore
  private writeQueue!: SerialQueue
  private auth!: AuthState
  private categoriesVersion: number = 0
  private categoriesRefreshing: boolean = false
  private static readonly REFRESH_DELAY: number = 10000

  async init(store: PreferencesStore, queue: SerialQueue, auth: AuthState): Promise<void> {
    this.store = store
    this.writeQueue = queue
    this.auth = auth
    await this.loadCachedCategories()
  }

  /** 重置缓存（登出时调用） */
  reset(): void {
    this.cachedCategories = []
    this.categoriesVersion = 0
    this.categoriesRefreshing = false
  }

  // ============== Cache ==============

  private async loadCachedCategories(): Promise<void> {
    const saved = await this.store.getJSON<Category[]>('cached_categories')
    if (saved && saved.length > 0) {
      this.cachedCategories = saved
      this.categoriesVersion++
      AppStorage.setOrCreate('catVersion', this.categoriesVersion)
      hilog.info(DOMAIN, TAG, 'Loaded cached categories: %{public}d', saved.length)
    }
  }

  private persistCategories(): void {
    this.writeQueue.enqueue(async (): Promise<void> => {
      await this.store.putJSON('cached_categories', this.cachedCategories, false)
      this.store.scheduleFlush()
    })
  }

  ensureCategories(): void {
    if (this.categoriesRefreshing) return
    this.categoriesRefreshing = true
    const hasCache = this.cachedCategories.length > 0
    setTimeout(async () => {
      await this.doRefreshCategories()
      this.categoriesRefreshing = false
    }, hasCache ? CategoryStore.REFRESH_DELAY : 0)
  }

  private async doRefreshCategories(): Promise<void> {
    if (!this.auth.isAuthenticated) return
    try {
      const result = await getForumCategories(this.auth.token)
      if (result.ok && result.data.length > 0) {
        const newJson = JSON.stringify(result.data)
        const oldJson = JSON.stringify(this.cachedCategories)
        if (newJson !== oldJson) {
          this.cachedCategories = result.data
          this.categoriesVersion++
          AppStorage.setOrCreate('catVersion', this.categoriesVersion)
          this.persistCategories()
          hilog.info(DOMAIN, TAG, 'Categories updated from network')
        } else {
          hilog.info(DOMAIN, TAG, 'Categories unchanged')
        }
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'refreshCategories failed')
    }
  }
}
