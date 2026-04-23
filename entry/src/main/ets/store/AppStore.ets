/**
 * 全局状态管理 - 替代 React Zustand stores
 * 使用 AppStorage + PersistentStorage 实现跨组件共享和持久化
 */

import { preferences } from '@kit.ArkData'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { Context } from '@kit.AbilityKit'
import { fetchForumFavorites } from '../service/NgaApi'

const TAG = 'AppStore'
const DOMAIN = 0x0000

// ============== 认证状态 ==============

export class AuthState {
  token: string = ''
  uid: string = ''
  nickName: string = ''
  avatarUrl: string = ''
  isAuthenticated: boolean = false
  initialized: boolean = false
}

// ============== 设置状态 ==============

export interface BlacklistEntry {
  userId: string
  nickName: string
}

export class FavBoard {
  fid: number = 0
  stid: number = 0
  name: string = ''
}

export class SettingsState {
  blacklist: BlacklistEntry[] = []
  favorites: FavBoard[] = []
  fontSize: number = 15
  domainIndex: number = 0
  theme: string = 'light'
}

// ============== Toast 状态 ==============

export class ToastState {
  message: string = ''
  visible: boolean = false
}

// ============== 全局 Store 单例 ==============

class AppStoreClass {
  private pref: preferences.Preferences | null = null

  // 认证
  auth: AuthState = new AuthState()

  // 设置
  settings: SettingsState = new SettingsState()

  // Toast
  toast: ToastState = new ToastState()
  private toastTimer: number = -1

  async init(context: Context): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, 'nga_app_store')
      await this.loadSettings()
      await this.loadAuth()
      hilog.info(DOMAIN, TAG, 'AppStore initialized')
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'AppStore init failed: %{public}s', JSON.stringify(e))
    }
  }

  // ============== Auth ==============

  setAuth(token: string, uid: string, nickName: string, avatarUrl: string): void {
    this.auth.token = token
    this.auth.uid = uid
    this.auth.nickName = nickName
    this.auth.avatarUrl = avatarUrl
    this.auth.isAuthenticated = true
    this.auth.initialized = true
    this.persistAuth()
  }

  clearAuth(): void {
    this.auth.token = ''
    this.auth.uid = ''
    this.auth.nickName = ''
    this.auth.avatarUrl = ''
    this.auth.isAuthenticated = false
    this.auth.initialized = true
    this.favoritesLoaded = false
    this.persistAuth()
  }

  private async persistAuth(): Promise<void> {
    if (!this.pref) return
    try {
      await this.pref.put('auth_token', this.auth.token)
      await this.pref.put('auth_uid', this.auth.uid)
      await this.pref.put('auth_nickName', this.auth.nickName)
      await this.pref.put('auth_avatarUrl', this.auth.avatarUrl)
      await this.pref.put('auth_isAuth', this.auth.isAuthenticated ? '1' : '0')
      await this.pref.flush()
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'persistAuth failed')
    }
  }

  private async loadAuth(): Promise<void> {
    if (!this.pref) return
    try {
      this.auth.token = (await this.pref.get('auth_token', '')) as string
      this.auth.uid = (await this.pref.get('auth_uid', '')) as string
      this.auth.nickName = (await this.pref.get('auth_nickName', '')) as string
      this.auth.avatarUrl = (await this.pref.get('auth_avatarUrl', '')) as string
      const isAuth = (await this.pref.get('auth_isAuth', '0')) as string
      this.auth.isAuthenticated = isAuth === '1' && this.auth.token !== ''
      this.auth.initialized = true
    } catch (e) {
      this.auth.initialized = true
    }
  }

  // ============== Settings ==============

  addBlacklist(entry: BlacklistEntry): void {
    this.settings.blacklist = [...this.settings.blacklist, entry]
    this.persistSettings()
  }

  removeBlacklist(userId: string): void {
    this.settings.blacklist = this.settings.blacklist.filter(u => u.userId !== userId)
    this.persistSettings()
  }

  getBlacklistIds(): Set<string> {
    const ids = new Set<string>()
    for (const entry of this.settings.blacklist) {
      ids.add(entry.userId)
    }
    return ids
  }

  private favoritesLoaded: boolean = false

  async fetchFavorites(): Promise<void> {
    if (this.favoritesLoaded || !this.auth.isAuthenticated) return
    try {
      const result = await fetchForumFavorites(this.auth.token)
      if (result.ok && result.data.length > 0) {
        const favs: FavBoard[] = []
        for (let i = 0; i < result.data.length; i++) {
          const item = result.data[i]
          const fb = new FavBoard()
          fb.fid = item.fid
          fb.stid = item.stid
          fb.name = item.name
          favs.push(fb)
        }
        this.settings.favorites = favs
        this.persistSettings()
        AppStorage.setOrCreate('favVersion', (AppStorage.get<number>('favVersion') ?? 0) + 1)
      }
      this.favoritesLoaded = true
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'fetchFavorites failed')
    }
  }

  addFavorite(board: FavBoard): void {
    this.settings.favorites = [...this.settings.favorites, board]
    this.persistSettings()
    AppStorage.setOrCreate('favVersion', (AppStorage.get<number>('favVersion') ?? 0) + 1)
  }

  removeFavorite(fid: number): void {
    this.settings.favorites = this.settings.favorites.filter(f => f.fid !== fid)
    this.persistSettings()
    AppStorage.setOrCreate('favVersion', (AppStorage.get<number>('favVersion') ?? 0) + 1)
  }

  setFontSize(size: number): void {
    this.settings.fontSize = size
    this.persistSettings()
  }

  setDomainIndex(index: number): void {
    this.settings.domainIndex = index
    this.persistSettings()
  }

  setTheme(theme: string): void {
    this.settings.theme = theme
    this.persistSettings()
  }

  toggleTheme(): void {
    this.settings.theme = this.settings.theme === 'dark' ? 'light' : 'dark'
    this.persistSettings()
  }

  private async persistSettings(): Promise<void> {
    if (!this.pref) return
    try {
      await this.pref.put('settings', JSON.stringify(this.settings))
      await this.pref.flush()
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'persistSettings failed')
    }
  }

  private async loadSettings(): Promise<void> {
    if (!this.pref) return
    try {
      const raw = (await this.pref.get('settings', '')) as string
      if (raw) {
        const obj = JSON.parse(raw) as Record<string, Object>
        if (obj['blacklist']) this.settings.blacklist = obj['blacklist'] as BlacklistEntry[]
        if (obj['fontSize']) this.settings.fontSize = Number(obj['fontSize'])
        if (obj['domainIndex']) this.settings.domainIndex = Number(obj['domainIndex'])
        if (obj['theme']) this.settings.theme = String(obj['theme'])
      }
    } catch (e) {
      hilog.info(DOMAIN, TAG, 'No saved settings')
    }
  }

  // ============== Toast ==============

  showToast(msg: string): void {
    clearTimeout(this.toastTimer)
    this.toast.message = msg
    this.toast.visible = true
    this.toastTimer = setTimeout(() => {
      this.toast.visible = false
      this.toast.message = ''
    }, 2500)
  }

  // ============== Blacklist helper string ==============

  getBlacklistHeaderString(): string {
    return this.settings.blacklist.map(u => u.userId).join(',')
  }
}

export const appStore = new AppStoreClass()
