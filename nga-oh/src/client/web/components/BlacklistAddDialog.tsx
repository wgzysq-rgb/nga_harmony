import { createPortal } from 'react-dom'
import { useState, useEffect, useCallback } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useUiStore } from '@/stores/ui'
import { useSettingsStore } from '@/stores/settings'

export default function BlacklistAddDialog() {
  const show = useUiStore((s) => s.blacklistAddDialog)
  const close = useUiStore((s) => s.closeBlacklistAddDialog)
  const addBlacklist = useSettingsStore((s) => s.addBlacklist)

  const [uid, setUid] = useState('')

  const handleConfirm = useCallback(() => {
    const trimmed = uid.trim()
    if (!trimmed) return
    addBlacklist({ userId: trimmed, nickName: `User${trimmed}` })
    setUid('')
    close()
  }, [uid, addBlacklist, close])

  const handleCancel = useCallback(() => {
    setUid('')
    close()
  }, [close])

  useEffect(() => {
    if (!show) return
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleCancel()
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [show, handleCancel])

  return createPortal(
    <AnimatePresence>
      {show && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.15 }}
          className="fixed inset-0 z-[100] flex items-center justify-center bg-overlay"
          onClick={handleCancel}
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.9, opacity: 0 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="w-[300px] bg-bg-tertiary rounded-xl overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="pt-6 px-4 pb-2 text-center">
              <div className="text-[17px] font-semibold">添加黑名单</div>
              <div className="text-[13px] text-text-secondary mt-1">输入用户 UID</div>
            </div>
            <div className="px-4 py-3">
              <input
                value={uid}
                onChange={(e) => setUid(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && uid.trim()) handleConfirm()
                }}
                placeholder="输入 UID"
                autoFocus
                className="w-full bg-bg-secondary rounded-lg px-3 py-2.5 text-[15px] outline-none placeholder:text-text-tertiary"
              />
            </div>
            <div className="h-[0.5px] bg-separator mx-0" />
            <div className="flex">
              <button
                onClick={handleCancel}
                className="flex-1 py-3 text-[17px] text-primary font-normal border-r-[0.5px] border-separator"
              >
                取消
              </button>
              <button
                onClick={handleConfirm}
                className="flex-1 py-3 text-[17px] text-primary font-semibold disabled:opacity-40"
                disabled={!uid.trim()}
              >
                确定
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>,
    document.body,
  )
}
