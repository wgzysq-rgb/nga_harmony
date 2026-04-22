import { create } from 'zustand'

export type LayoutMode = 'mobile' | 'twocol' | 'threecol'

export type BoardState = { type: 'forum'; fid: number; name: string }

export type DetailScreen =
  | { type: 'thread'; tid: string; page?: number; pid?: string }
  | { type: 'profile'; uid: string }
  | { type: 'messages' }
  | { type: 'messageDetail'; mid: string; page?: number }
  | { type: 'notifications' }
  | { type: 'search' }
  | { type: 'blacklist' }
  | { type: 'authorPosts'; authorid: string; name: string; searchpost?: boolean }
  | { type: 'favorites' }
  | { type: 'browseHistory' }
  | { type: 'settings' }

export type DetailCategory = 'thread' | 'pm' | 'user' | 'history' | 'tool'

export function getDetailCategory(screen: DetailScreen): DetailCategory {
  switch (screen.type) {
    case 'thread':
      return 'thread'
    case 'messages':
    case 'messageDetail':
      return 'pm'
    case 'profile':
      return 'user'
    case 'authorPosts':
      return 'history'
    case 'notifications':
    case 'search':
    case 'blacklist':
    case 'favorites':
    case 'browseHistory':
    case 'settings':
      return 'tool'
  }
}

export interface DetailEntry {
  id: string
  screen: DetailScreen
  category: DetailCategory
}

let nextId = 0
function genId(): string {
  return `nav_${++nextId}_${Date.now()}`
}

function detectLayoutMode(): LayoutMode {
  if (typeof window === 'undefined') return 'mobile'
  if (window.matchMedia('(min-width: 1400px)').matches) return 'threecol'
  if (window.matchMedia('(min-width: 1024px)').matches) return 'twocol'
  return 'mobile'
}

interface RouterState {
  layoutMode: LayoutMode
  board: BoardState | null
  detailStack: DetailEntry[]

  setLayoutMode: (mode: LayoutMode) => void
  openBoard: (board: BoardState) => void
  pushDetail: (screen: DetailScreen) => void
  replaceDetail: (screen: DetailScreen) => void
  goBack: () => void
  resetAll: () => void
  removeByCategory: (category: DetailCategory) => void
}

export const useRouterStore = create<RouterState>((set, get) => ({
  layoutMode: detectLayoutMode(),
  board: null,
  detailStack: [],

  setLayoutMode: (mode) => {
    if (get().layoutMode === mode) return
    set({ layoutMode: mode })
  },

  openBoard: (board) => {
    set({ board, detailStack: [] })
  },

  pushDetail: (screen) => {
    set((s) => ({
      detailStack: [...s.detailStack, { id: genId(), screen, category: getDetailCategory(screen) }],
    }))
  },

  replaceDetail: (screen) => {
    set((s) => {
      const stack = [...s.detailStack]
      const entry: DetailEntry = { id: genId(), screen, category: getDetailCategory(screen) }
      if (stack.length > 0) {
        stack[stack.length - 1] = entry
      } else {
        stack.push(entry)
      }
      return { detailStack: stack }
    })
  },

  goBack: () => {
    const { detailStack, board, layoutMode } = get()
    if (detailStack.length > 0) {
      set({ detailStack: detailStack.slice(0, -1) })
      return
    }
    if (board) {
      set({ board: null })
      return
    }
  },

  resetAll: () => {
    set({
      board: null,
      detailStack: [],
    })
  },

  removeByCategory: (category) => {
    set((s) => ({
      detailStack: s.detailStack.filter((e) => e.category !== category),
    }))
  },
}))
