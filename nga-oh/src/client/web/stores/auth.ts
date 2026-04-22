import { create } from 'zustand'
import { api } from '@/api/client'
import { useSettingsStore } from './settings'

interface CurrentUser {
  uid: string
  nickName: string
  avatarUrl: string
}

interface AuthState {
  token: string
  currentUser: CurrentUser | null
  isAuthenticated: boolean
  initialized: boolean
  setAuth: (token: string, user: CurrentUser | null) => void
  logout: () => void
  fetchUser: () => Promise<void>
}

export const useAuthStore = create<AuthState>((set, get) => {
  const token = localStorage.getItem('nga_token') ?? ''
  return {
    token,
    currentUser: null,
    isAuthenticated: !!token,
    initialized: false,
    setAuth: (token, user) => {
      localStorage.setItem('nga_token', token)
      document.cookie = `nga_token=${token};path=/;max-age=${60 * 60 * 24 * 365};samesite=strict`
      set({ token, currentUser: user, isAuthenticated: true, initialized: true })
    },
    logout: () => {
      localStorage.removeItem('nga_token')
      document.cookie = 'nga_token=;path=/;max-age=0'
      set({ token: '', currentUser: null, isAuthenticated: false, initialized: true })
      useSettingsStore.getState().resetFavorites()
    },
    fetchUser: async () => {
      const { token } = get()
      if (!token) {
        set({ initialized: true })
        return
      }
      try {
        const res = await api.get<{ ok: boolean; user: CurrentUser }>('/auth/me')
        if (res.ok && res.user) {
          set({ currentUser: res.user, isAuthenticated: true, initialized: true })
        } else {
          set({ currentUser: null, isAuthenticated: false, initialized: true })
        }
      } catch {
        set({ initialized: true })
      }
    },
  }
})

window.addEventListener('auth:unauthorized', () => {
  useAuthStore.getState().logout()
})
