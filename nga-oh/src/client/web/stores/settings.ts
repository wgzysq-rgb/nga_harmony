import { create } from 'zustand'
import { setBlacklistHeader, api } from '@/api/client'

interface BlacklistEntry {
  userId: string
  nickName: string
}

export interface FavBoard {
  fid: number
  stid: number
  name: string
}

interface SettingsState {
  blacklist: BlacklistEntry[]
  favorites: FavBoard[]
  favoritesLoaded: boolean
  favoritesLoading: boolean
  fontSize: number
  domainIndex: number
  addBlacklist: (entry: BlacklistEntry) => void
  removeBlacklist: (userId: string) => void
  addFavorite: (board: FavBoard) => Promise<void>
  removeFavorite: (fid: number) => Promise<void>
  fetchFavorites: () => Promise<void>
  resetFavorites: () => void
  setFontSize: (size: number) => void
  setDomainIndex: (index: number) => void
}

function loadBlacklist(): BlacklistEntry[] {
  try {
    return JSON.parse(localStorage.getItem('nga_blacklist') ?? '[]')
  } catch {
    return []
  }
}

const initialBlacklist = loadBlacklist()
setBlacklistHeader(initialBlacklist.map(u => u.userId))

export const useSettingsStore = create<SettingsState>((set, get) => ({
  blacklist: initialBlacklist,
  favorites: [],
  favoritesLoaded: false,
  favoritesLoading: false,
  fontSize: Number(localStorage.getItem('nga_font_size')) || 15,
  domainIndex: Number(localStorage.getItem('nga_domain_index')) || 0,

  addBlacklist: (entry) => {
    const list = [...get().blacklist, entry]
    localStorage.setItem('nga_blacklist', JSON.stringify(list))
    setBlacklistHeader(list.map(u => u.userId))
    set({ blacklist: list })
  },

  removeBlacklist: (userId) => {
    const list = get().blacklist.filter(u => u.userId !== userId)
    localStorage.setItem('nga_blacklist', JSON.stringify(list))
    setBlacklistHeader(list.map(u => u.userId))
    set({ blacklist: list })
  },

  addFavorite: async (board) => {
    await api.post('/forum/favorite/add', {
      fid: String(board.fid),
    })
    const list = [...get().favorites, board]
    set({ favorites: list })
  },

  removeFavorite: async (fid) => {
    await api.post('/forum/favorite/remove', {
      fid: String(fid),
    })
    const list = get().favorites.filter(f => f.fid !== fid)
    set({ favorites: list })
  },

  fetchFavorites: async () => {
    const { favoritesLoaded, favoritesLoading } = get()
    if (favoritesLoaded || favoritesLoading) return
    set({ favoritesLoading: true })
    try {
      const res = await api.get<{ ok: boolean; data: FavBoard[] }>('/forum/favorites')
      if (res.ok && Array.isArray(res.data)) {
        set({ favorites: res.data, favoritesLoaded: true, favoritesLoading: false })
      } else {
        set({ favoritesLoading: false })
      }
    } catch {
      set({ favoritesLoading: false })
    }
  },

  resetFavorites: () => {
    set({ favorites: [], favoritesLoaded: false, favoritesLoading: false })
  },

  setFontSize: (size) => {
    localStorage.setItem('nga_font_size', String(size))
    document.documentElement.style.setProperty('--font-size-base', `${size}px`)
    set({ fontSize: size })
  },

  setDomainIndex: (index) => {
    localStorage.setItem('nga_domain_index', String(index))
    set({ domainIndex: index })
  },
}))
