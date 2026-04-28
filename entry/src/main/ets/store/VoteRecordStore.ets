import { Context } from '@kit.AbilityKit'
import { PreferencesStore } from './PreferencesStore'

class VoteRecord {
  upPids: string[] = []
  downPids: string[] = []
  ts: number = 0
}

const MAX_ENTRIES: number = 200

class VoteRecordStoreClass {
  private store: PreferencesStore | null = null
  private cache: Record<string, VoteRecord> = {}
  private loadedUid: string = ''

  async init(context: Context): Promise<void> {
    this.store = new PreferencesStore()
    await this.store.init(context, 'nga_vote_record')
  }

  async load(uid: string, tid: string): Promise<Set<string>[]> {
    if (!this.store || uid.length === 0) {
      return [new Set<string>(), new Set<string>()]
    }
    if (this.loadedUid !== uid) {
      const saved = await this.store.getJSON<Record<string, VoteRecord>>(`votes_${uid}`)
      this.cache = saved ?? {}
      this.loadedUid = uid
    }
    const upSet = new Set<string>()
    const downSet = new Set<string>()
    const record = this.cache[tid]
    if (record) {
      for (let i = 0; i < record.upPids.length; i++) {
        upSet.add(record.upPids[i])
      }
      for (let i = 0; i < record.downPids.length; i++) {
        downSet.add(record.downPids[i])
      }
    }
    return [upSet, downSet]
  }

  async save(uid: string, tid: string, upPids: Set<string>, downPids: Set<string>): Promise<void> {
    if (!this.store || uid.length === 0 || tid.length === 0) {
      return
    }
    if (this.loadedUid !== uid) {
      const saved = await this.store.getJSON<Record<string, VoteRecord>>(`votes_${uid}`)
      this.cache = saved ?? {}
      this.loadedUid = uid
    }
    const record = new VoteRecord()
    const upArr: string[] = []
    upPids.forEach((pid: string) => { upArr.push(pid) })
    const downArr: string[] = []
    downPids.forEach((pid: string) => { downArr.push(pid) })
    record.upPids = upArr
    record.downPids = downArr
    record.ts = Date.now()
    this.cache[tid] = record
    this.evictIfNeeded()
    await this.store.putJSON(`votes_${uid}`, this.cache)
  }

  async remove(uid: string, tid: string): Promise<void> {
    if (!this.store || uid.length === 0) {
      return
    }
    if (this.loadedUid !== uid) {
      const saved = await this.store.getJSON<Record<string, VoteRecord>>(`votes_${uid}`)
      this.cache = saved ?? {}
      this.loadedUid = uid
    }
    const newCache: Record<string, VoteRecord> = {}
    const cacheKeys = Object.keys(this.cache)
    for (let i = 0; i < cacheKeys.length; i++) {
      if (cacheKeys[i] !== tid) {
        newCache[cacheKeys[i]] = this.cache[cacheKeys[i]]
      }
    }
    this.cache = newCache
    await this.store.putJSON(`votes_${uid}`, this.cache)
  }

  async clear(uid: string): Promise<void> {
    if (!this.store) {
      return
    }
    this.cache = {}
    this.loadedUid = uid
    await this.store.putJSON(`votes_${uid}`, this.cache)
  }

  private evictIfNeeded(): void {
    const keys = Object.keys(this.cache)
    if (keys.length <= MAX_ENTRIES) {
      return
    }
    const entries: string[][] = []
    for (let i = 0; i < keys.length; i++) {
      const record = this.cache[keys[i]]
      if (record) {
        entries.push([keys[i], String(record.ts)])
      }
    }
    entries.sort((a: string[], b: string[]): number => {
      return Number(a[1]) - Number(b[1])
    })
    const removeCount = entries.length - MAX_ENTRIES
    const evictSet = new Set<string>()
    for (let i = 0; i < removeCount; i++) {
      evictSet.add(entries[i][0])
    }
    const newCache: Record<string, VoteRecord> = {}
    for (let i = 0; i < keys.length; i++) {
      if (!evictSet.has(keys[i])) {
        newCache[keys[i]] = this.cache[keys[i]]
      }
    }
    this.cache = newCache
  }
}

export const voteRecordStore = new VoteRecordStoreClass()
