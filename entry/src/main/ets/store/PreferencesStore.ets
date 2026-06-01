import { preferences } from '@kit.ArkData'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { Context } from '@kit.AbilityKit'

const TAG = 'PreferencesStore'
const DOMAIN = 0x0000

export class PreferencesStore {
  private pref: preferences.Preferences | null = null

  async init(context: Context, name: string): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, name)
      hilog.info(DOMAIN, TAG, 'Initialized: %{public}s', name)
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'init failed: %{public}s', name)
    }
  }

  async getString(key: string, def: string = ''): Promise<string> {
    if (!this.pref) return def
    try {
      return (await this.pref.get(key, def)) as string
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'getString failed: %{public}s', key)
      return def
    }
  }

  async putString(key: string, value: string, flush: boolean = true): Promise<void> {
    if (!this.pref) return
    try {
      await this.pref.put(key, value)
      if (flush) {
        await this.pref.flush()
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'putString failed: %{public}s', key)
    }
  }

  async getJSON<T>(key: string): Promise<T | null> {
    if (!this.pref) return null
    try {
      const raw = (await this.pref.get(key, '')) as string
      if (raw) {
        return JSON.parse(raw) as T
      }
    } catch (e) {
      hilog.info(DOMAIN, TAG, 'getJSON miss: %{public}s', key)
    }
    return null
  }

  async putJSON(key: string, value: Object, flush: boolean = true): Promise<void> {
    if (!this.pref) return
    try {
      await this.pref.put(key, JSON.stringify(value))
      if (flush) {
        await this.pref.flush()
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'putJSON failed: %{public}s', key)
    }
  }

  async flush(): Promise<void> {
    if (!this.pref) return
    try {
      await this.pref.flush()
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'flush failed')
    }
  }
}
