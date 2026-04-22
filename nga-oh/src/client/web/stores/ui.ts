import { create } from 'zustand'

interface ProfileCardState {
  uid: string
  anchorRect: { x: number; y: number; width: number; height: number; top: number; right: number; bottom: number; left: number }
}

interface ReplyModalState {
  tid: string
  fid: string
  replyTarget: { pid: string; lou: number } | null
  replyText: string
  sending: boolean
}

interface ThreadActionSheetState {
  tid: string
}

interface ThreadFeatureState {
  authorOnly: boolean
  favDone: boolean
}

interface LightboxState {
  urls: string[]
  index: number
}

interface ComposeSheetState {
  to: string
  subject: string
  content: string
  sending: boolean
}

interface UiState {
  profileCard: ProfileCardState | null
  openProfileCard: (uid: string, anchor: HTMLElement) => void
  closeProfileCard: () => void
  replyModal: ReplyModalState | null
  openReplyModal: (tid: string, fid: string, replyTarget?: { pid: string; lou: number } | null) => void
  closeReplyModal: () => void
  setReplyModalText: (text: string) => void
  setReplyModalSending: (sending: boolean) => void
  threadActionSheet: ThreadActionSheetState | null
  openThreadActionSheet: (tid: string) => void
  closeThreadActionSheet: () => void
  threadFeatures: Record<string, ThreadFeatureState>
  getThreadFeature: (tid: string) => ThreadFeatureState
  toggleThreadAuthorOnly: (tid: string) => void
  markThreadFavDone: (tid: string) => void
  lightbox: LightboxState | null
  openLightbox: (urls: string[], index: number) => void
  closeLightbox: () => void
  composeSheet: ComposeSheetState | null
  openComposeSheet: (to?: string) => void
  closeComposeSheet: () => void
  setComposeField: (field: 'to' | 'subject' | 'content', value: string) => void
  setComposeSending: (sending: boolean) => void
  blacklistAddDialog: boolean
  openBlacklistAddDialog: () => void
  closeBlacklistAddDialog: () => void
}

export const useUiStore = create<UiState>((set) => ({
  profileCard: null,
  openProfileCard: (uid, anchor) => {
    const r = anchor.getBoundingClientRect()
    set({ profileCard: { uid, anchorRect: { x: r.x, y: r.y, width: r.width, height: r.height, top: r.top, right: r.right, bottom: r.bottom, left: r.left } } })
  },
  closeProfileCard: () => set({ profileCard: null }),

  replyModal: null,
  openReplyModal: (tid, fid, replyTarget = null) => set({
    replyModal: { tid, fid, replyTarget, replyText: '', sending: false }
  }),
  closeReplyModal: () => set({ replyModal: null }),
  setReplyModalText: (text) => set((s) => s.replyModal ? { replyModal: { ...s.replyModal, replyText: text } } : s),
  setReplyModalSending: (sending) => set((s) => s.replyModal ? { replyModal: { ...s.replyModal, sending } } : s),

  threadActionSheet: null,
  openThreadActionSheet: (tid) => set({
    threadActionSheet: { tid }
  }),
  closeThreadActionSheet: () => set({ threadActionSheet: null }),
  threadFeatures: {},
  getThreadFeature: (tid): ThreadFeatureState => {
    const s = useUiStore.getState()
    return s.threadFeatures[tid] ?? { authorOnly: false, favDone: false }
  },
  toggleThreadAuthorOnly: (tid) => set((s) => {
    const prev = s.threadFeatures[tid] ?? { authorOnly: false, favDone: false }
    return { threadFeatures: { ...s.threadFeatures, [tid]: { ...prev, authorOnly: !prev.authorOnly } } }
  }),
  markThreadFavDone: (tid) => set((s) => {
    const prev = s.threadFeatures[tid] ?? { authorOnly: false, favDone: false }
    return { threadFeatures: { ...s.threadFeatures, [tid]: { ...prev, favDone: true } } }
  }),

  lightbox: null,
  openLightbox: (urls, index) => set({ lightbox: { urls, index } }),
  closeLightbox: () => set({ lightbox: null }),

  composeSheet: null,
  openComposeSheet: (to = '') => set({
    composeSheet: { to, subject: '', content: '', sending: false }
  }),
  closeComposeSheet: () => set({ composeSheet: null }),
  setComposeField: (field, value) => set((s) => s.composeSheet ? {
    composeSheet: { ...s.composeSheet, [field]: value }
  } : s),
  setComposeSending: (sending) => set((s) => s.composeSheet ? {
    composeSheet: { ...s.composeSheet, sending }
  } : s),

  blacklistAddDialog: false,
  openBlacklistAddDialog: () => set({ blacklistAddDialog: true }),
  closeBlacklistAddDialog: () => set({ blacklistAddDialog: false }),
}))
