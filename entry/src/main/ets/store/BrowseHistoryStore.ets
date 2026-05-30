import { Context } from '@kit.AbilityKit'
import { PreferencesStore } from './PreferencesStore'
import { SerialQueue } from './SerialQueue'

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

const MAX_COUNT: number = 500

class BrowseHistoryStoreClass {
  private store: PreferencesStore | null = null
  private items: BrowseHistoryEntry[] = []
  private loadedUid: string = ''
  private version: number = 0
  private writeQueue: SerialQueue = new SerialQueue()

  async init(context: Context): Promise<void> {
    this.store = new PreferencesStore()
    await this.store.init(context, 'nga_browse_history')
  }

  async getItems(uid: string): Promise<BrowseHistoryEntry[]> {
    if (!this.store) {
      return []
    }
    if (this.loadedUid !== uid) {
      const saved = await this.store.getJSON<BrowseHistoryEntry[]>(`history_${uid}`)
      this.items = saved ?? []
      this.loadedUid = uid
    }
    const result: BrowseHistoryEntry[] = []
    for (let i = 0; i < this.items.length; i++) {
      result.push(this.items[i])
    }
    return result
  }

  async add(uid: string, entry: BrowseHistoryEntry): Promise<void> {
    if (!this.store || uid.length === 0) {
      return
    }
    if (this.loadedUid !== uid) {
      await this.getItems(uid)
    }
    const filtered: BrowseHistoryEntry[] = []
    for (let i = 0; i < this.items.length; i++) {
      if (this.items[i].tid !== entry.tid) {
        filtered.push(this.items[i])
      }
    }
    entry.ts = Date.now()
    const newList: BrowseHistoryEntry[] = [entry, ...filtered]
    if (newList.length > MAX_COUNT) {
      this.items = newList.slice(0, MAX_COUNT)
    } else {
      this.items = newList
    }
    await this.persist(uid)
  }

  async remove(uid: string, tid: string): Promise<void> {
    if (!this.store) {
      return
    }
    if (this.loadedUid !== uid) {
      await this.getItems(uid)
    }
    const filtered: BrowseHistoryEntry[] = []
    for (let i = 0; i < this.items.length; i++) {
      if (this.items[i].tid !== tid) {
        filtered.push(this.items[i])
      }
    }
    this.items = filtered
    await this.persist(uid)
  }

  async clear(uid: string): Promise<void> {
    if (!this.store) {
      return
    }
    this.items = []
    await this.persist(uid)
  }

  private async persist(uid: string): Promise<void> {
    const store = this.store
    if (!store) {
      return
    }
    await this.writeQueue.enqueue(async (): Promise<void> => {
      await store.putJSON(`history_${uid}`, this.items)
      this.version++
      AppStorage.setOrCreate('browseHistoryVersion', this.version)
    })
  }
}

export const browseHistoryStore = new BrowseHistoryStoreClass()
