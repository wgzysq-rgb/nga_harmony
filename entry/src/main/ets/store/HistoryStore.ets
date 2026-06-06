import { PreferencesStore } from './PreferencesStore'
import { SerialQueue } from './SerialQueue'

/** 浏览历史条目 */
export class BrowseHistoryEntry {
  tid: string = ''
  subject: string = ''
  author: string = ''
  authorid: string = ''
  replies: number = 0
  postDate: number = 0
  board: string = ''
  ts: number = 0
}

const HISTORY_MAX_COUNT: number = 500

/**
 * 帖子浏览历史管理
 */
export class HistoryStore {
  private store!: PreferencesStore
  private writeQueue!: SerialQueue
  private historyItems: BrowseHistoryEntry[] = []
  private historyLoadedUid: string = ''
  private historyVersion: number = 0

  init(store: PreferencesStore, queue: SerialQueue): void {
    this.store = store
    this.writeQueue = queue
  }

  /** 重置缓存（登出时调用） */
  reset(): void {
    this.historyItems = []
    this.historyLoadedUid = ''
    this.historyVersion = 0
  }

  private historyKey(uid: string): string {
    return `history_${uid}`
  }

  async getBrowseHistory(uid: string): Promise<BrowseHistoryEntry[]> {
    if (this.historyLoadedUid !== uid) {
      const saved = await this.store.getJSON<BrowseHistoryEntry[]>(this.historyKey(uid))
      this.historyItems = saved ?? []
      this.historyLoadedUid = uid
    }
    const result: BrowseHistoryEntry[] = []
    for (let i = 0; i < this.historyItems.length; i++) {
      result.push(this.historyItems[i])
    }
    return result
  }

  async addBrowseHistory(uid: string, entry: BrowseHistoryEntry): Promise<void> {
    if (uid.length === 0) return
    if (this.historyLoadedUid !== uid) {
      await this.getBrowseHistory(uid)
    }
    const filtered: BrowseHistoryEntry[] = []
    for (let i = 0; i < this.historyItems.length; i++) {
      if (this.historyItems[i].tid !== entry.tid) {
        filtered.push(this.historyItems[i])
      }
    }
    entry.ts = Date.now()
    const newList: BrowseHistoryEntry[] = [entry, ...filtered]
    if (newList.length > HISTORY_MAX_COUNT) {
      this.historyItems = newList.slice(0, HISTORY_MAX_COUNT)
    } else {
      this.historyItems = newList
    }
    this.persistBrowseHistory(uid)
  }

  async removeBrowseHistory(uid: string, tid: string): Promise<void> {
    if (this.historyLoadedUid !== uid) {
      await this.getBrowseHistory(uid)
    }
    const filtered: BrowseHistoryEntry[] = []
    for (let i = 0; i < this.historyItems.length; i++) {
      if (this.historyItems[i].tid !== tid) {
        filtered.push(this.historyItems[i])
      }
    }
    this.historyItems = filtered
    this.persistBrowseHistory(uid)
  }

  async clearBrowseHistory(uid: string): Promise<void> {
    this.historyItems = []
    this.persistBrowseHistory(uid)
  }

  private persistBrowseHistory(uid: string): void {
    this.writeQueue.enqueue(async (): Promise<void> => {
      await this.store.putJSON(this.historyKey(uid), this.historyItems, false)
      this.historyVersion++
      AppStorage.setOrCreate('browseHistoryVersion', this.historyVersion)
      this.store.scheduleFlush()
    })
  }
}
