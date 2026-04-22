import { useRef, useEffect } from 'react'
import { createPortal } from 'react-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { MessageCircle } from 'lucide-react'
import { api } from '@/api/client'
import { useUiStore } from '@/stores/ui'
import { useToastStore } from '@/components/Toast'
import { useQueryClient } from '@tanstack/react-query'

export default function ReplyModal() {
  const replyModal = useUiStore((s) => s.replyModal)
  const closeReplyModal = useUiStore((s) => s.closeReplyModal)
  const openReplyModal = useUiStore((s) => s.openReplyModal)
  const setReplyModalText = useUiStore((s) => s.setReplyModalText)
  const setReplyModalSending = useUiStore((s) => s.setReplyModalSending)
  const showToast = useToastStore((s) => s.showToast)
  const queryClient = useQueryClient()
  const replyInputRef = useRef<HTMLTextAreaElement>(null)

  useEffect(() => {
    if (replyModal && replyInputRef.current) {
      replyInputRef.current.focus()
    }
  }, [replyModal])

  useEffect(() => {
    if (!replyModal) return
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeReplyModal()
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [replyModal, closeReplyModal])

  const handleSend = async () => {
    if (!replyModal || !replyModal.replyText.trim()) return

    setReplyModalSending(true)
    try {
      const authRes = await api.post<{ ok: boolean; fid?: string }>(
        `/post/auth`,
        { fid: replyModal.fid, action: 'reply', tid: replyModal.tid }
      )
      if (!authRes.ok) throw new Error('无权回复')

      if (replyModal.replyTarget) {
        const res = await api.post<{ ok: boolean; error?: string }>(`/post/comment`, {
          tid: replyModal.tid,
          pid: replyModal.replyTarget.pid,
          fid: replyModal.fid,
          content: replyModal.replyText.trim(),
          anony: '0',
        })
        if (!res.ok) throw new Error(res.error ?? '评论失败')
        showToast('评论成功')
      } else {
        const res = await api.post<{ ok: boolean; error?: string }>(`/post/reply`, {
          tid: replyModal.tid,
          fid: replyModal.fid,
          content: replyModal.replyText.trim(),
          anony: '0',
        })
        if (!res.ok) throw new Error(res.error ?? '回复失败')
        showToast('回复成功')
      }

      queryClient.invalidateQueries({ queryKey: ['thread', replyModal.tid] })
      closeReplyModal()
    } catch (err: any) {
      showToast(err.message ?? '操作失败')
    } finally {
      setReplyModalSending(false)
    }
  }

  return createPortal(
    <AnimatePresence>
      {replyModal && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-black/40"
            onClick={closeReplyModal}
          />
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 28, stiffness: 360 }}
            className="fixed bottom-0 left-0 right-0 z-50 bg-bg-tertiary rounded-t-2xl pb-[env(safe-area-inset-bottom,0px)] desktop-sheet"
          >
            <div className="w-10 h-1 rounded-full bg-separator mx-auto mt-2" />
            <div className="px-4 pt-2 pb-3">
              <div className="flex items-center justify-between mb-2">
                <span className="text-[16px] font-semibold">
                  {replyModal.replyTarget ? `回复 #${replyModal.replyTarget.lou}` : '写回复'}
                </span>
                <button
                  onClick={closeReplyModal}
                  className="w-8 h-8 flex items-center justify-center rounded-full bg-bg-secondary"
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <line x1="18" y1="6" x2="6" y2="18" />
                    <line x1="6" y1="6" x2="18" y2="18" />
                  </svg>
                </button>
              </div>
              {replyModal.replyTarget && (
                <div className="flex items-center gap-1 text-[13px] text-primary mb-2">
                  <MessageCircle size={14} />
                  <span>回复 #{replyModal.replyTarget.lou} 的帖子</span>
                  <button
                    onClick={() => openReplyModal(replyModal.tid, replyModal.fid, null)}
                    className="ml-auto text-text-tertiary"
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                  </button>
                </div>
              )}
              <textarea
                ref={replyInputRef}
                value={replyModal.replyText}
                onChange={(e) => setReplyModalText(e.target.value)}
                placeholder={replyModal.replyTarget ? `回复 #${replyModal.replyTarget.lou}...` : '写回复...'}
                rows={4}
                autoFocus
                className="w-full bg-bg-secondary rounded-xl px-3 py-2.5 text-[15px] outline-none resize-none min-h-[100px] placeholder:text-text-tertiary"
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
                    handleSend()
                  }
                }}
              />
              <div className="flex items-center justify-between mt-2.5">
                <span className="text-[12px] text-text-tertiary">Ctrl+Enter 发送</span>
                <button
                  onClick={handleSend}
                  disabled={!replyModal.replyText.trim() || replyModal.sending}
                  className="px-5 py-2 bg-primary text-white text-[15px] font-medium rounded-xl active:scale-95 transition-transform disabled:opacity-40 disabled:cursor-not-allowed"
                >
                  {replyModal.sending ? '发送中...' : '发送'}
                </button>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>,
    document.body
  )
}
