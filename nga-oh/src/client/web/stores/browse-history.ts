import { create } from 'zustand'
import { api } from '@/api/client'
import type { BrowseHistoryEntry } from '../../../shared/types/browse-history.js'

export type BrowseHistoryItem = BrowseHistoryEntry

interface BrowseHistoryState {
  items: BrowseHistoryItem[]
  loading: boolean
  fetch: () => Promise<void>
  add: (item: Omit<BrowseHistoryItem, 'ts'>) => void
  remove: (tid: string) => Promise<void>
  clear: () => Promise<void>
}

export const useBrowseHistoryStore = create<BrowseHistoryState>((set, get) => ({
  items: [],
  loading: false,

  fetch: async () => {
    set({ loading: true })
    try {
      const res = await api.get<{ ok: boolean; data: BrowseHistoryItem[] }>('/browse-history')
      if (res.ok) {
        set({ items: res.data })
      }
    } catch {
    } finally {
      set({ loading: false })
    }
  },

  add: (item) => {
    api.post('/browse-history/add', item).catch(() => {})
    set((s) => {
      const filtered = s.items.filter((h) => h.tid !== item.tid)
      const newItem: BrowseHistoryItem = { ...item, ts: Date.now() }
      const list = [newItem, ...filtered].slice(0, 500)
      return { items: list }
    })
  },

  remove: async (tid) => {
    try {
      await api.post('/browse-history/remove', { tid })
    } catch {}
    set((s) => ({ items: s.items.filter((h) => h.tid !== tid) }))
  },

  clear: async () => {
    try {
      await api.post('/browse-history/clear', {})
    } catch {}
    set({ items: [] })
  },
}))
