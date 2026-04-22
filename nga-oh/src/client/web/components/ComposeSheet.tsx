import { createPortal } from 'react-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { useUiStore } from '@/stores/ui'
import { useQueryClient } from '@tanstack/react-query'
import { useCallback, useEffect } from 'react'
import { api } from '@/api/client'
import { useToastStore } from '@/components/Toast'
import { X, Send, Loader2 } from 'lucide-react'

export default function ComposeSheet() {
  const composeSheet = useUiStore((s) => s.composeSheet)
  const closeComposeSheet = useUiStore((s) => s.closeComposeSheet)
  const setComposeField = useUiStore((s) => s.setComposeField)
  const setComposeSending = useUiStore((s) => s.setComposeSending)

  const queryClient = useQueryClient()
  const showToast = useToastStore((s) => s.showToast)

  const handleSend = useCallback(async () => {
    if (!composeSheet) return
    const to = composeSheet.to.trim()
    const subject = composeSheet.subject.trim()
    const content = composeSheet.content.trim()
    if (!to || !subject || !content) return

    setComposeSending(true)
    try {
      const res = await api.post<{ ok: boolean; error?: string }>('/messages/send', {
        to,
        subject,
        content,
      })
      if (!res.ok) throw new Error(res.error ?? '发送失败')
      showToast('发送成功')
      closeComposeSheet()
      queryClient.invalidateQueries({ queryKey: ['messages'] })
    } catch (err: any) {
      showToast(err.message ?? '发送失败')
    } finally {
      setComposeSending(false)
    }
  }, [composeSheet, queryClient, showToast, closeComposeSheet, setComposeSending])

  useEffect(() => {
    if (!composeSheet) return
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeComposeSheet()
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [composeSheet, closeComposeSheet])

  return createPortal(
    <AnimatePresence>
      {composeSheet && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-40 bg-black/40"
            onClick={closeComposeSheet}
          />
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 28, stiffness: 360 }}
            className="fixed bottom-0 left-0 right-0 z-50 bg-bg-tertiary rounded-t-2xl pb-[env(safe-area-inset-bottom,0px)] desktop-sheet"
          >
            <div className="w-10 h-1 rounded-full bg-separator mx-auto mt-2" />
            <div className="flex items-center justify-between px-4 py-3">
              <span className="text-[17px] font-semibold">写私信</span>
              <button
                onClick={closeComposeSheet}
                className="p-1 text-text-tertiary active:text-text-secondary"
              >
                <X size={20} />
              </button>
            </div>

            <div className="px-4 pb-4 space-y-3">
              <input
                type="text"
                value={composeSheet.to}
                onChange={(e) => setComposeField('to', e.target.value)}
                placeholder="收件人（用户名）"
                className="w-full bg-bg-secondary rounded-xl px-3 py-2.5 text-[15px] outline-none placeholder:text-text-tertiary"
              />
              <input
                type="text"
                value={composeSheet.subject}
                onChange={(e) => setComposeField('subject', e.target.value)}
                placeholder="主题"
                className="w-full bg-bg-secondary rounded-xl px-3 py-2.5 text-[15px] outline-none placeholder:text-text-tertiary"
              />
              <textarea
                value={composeSheet.content}
                onChange={(e) => setComposeField('content', e.target.value)}
                placeholder="内容"
                rows={4}
                className="w-full bg-bg-secondary rounded-xl px-3 py-2.5 text-[15px] outline-none resize-none placeholder:text-text-tertiary"
              />
              <button
                onClick={handleSend}
                disabled={
                  !composeSheet.to.trim() ||
                  !composeSheet.subject.trim() ||
                  !composeSheet.content.trim() ||
                  composeSheet.sending
                }
                className="w-full py-2.5 bg-primary text-white text-[16px] font-semibold rounded-xl active:scale-[0.98] transition-transform disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {composeSheet.sending ? (
                  <>
                    <Loader2 size={16} className="animate-spin" />
                    发送中...
                  </>
                ) : (
                  <>
                    <Send size={16} />
                    发送
                  </>
                )}
              </button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>,
    document.body,
  )
}
