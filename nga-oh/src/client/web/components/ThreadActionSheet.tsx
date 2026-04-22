import { createPortal } from 'react-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { api } from '@/api/client'
import { useUiStore } from '@/stores/ui'
import { useToastStore } from '@/components/Toast'

export default function ThreadActionSheet() {
  const sheet = useUiStore((s) => s.threadActionSheet)
  const threadFeatures = useUiStore((s) => s.threadFeatures)
  const close = useUiStore((s) => s.closeThreadActionSheet)
  const toggleAuthorOnly = useUiStore((s) => s.toggleThreadAuthorOnly)
  const markFavDone = useUiStore((s) => s.markThreadFavDone)
  const showToast = useToastStore((s) => s.showToast)

  if (!sheet) return null

  const tid = sheet.tid
  const feature = threadFeatures[tid] ?? { authorOnly: false, favDone: false }

  const handleFavorite = async () => {
    if (feature.favDone) return
    try {
      const res = await api.post<{ ok: boolean; error?: string }>(`/favorite/add`, { tid })
      if (res.ok) {
        markFavDone(tid)
        showToast('收藏成功')
        close()
      } else {
        showToast(res.error ?? '收藏失败')
      }
    } catch (err: any) {
      showToast(err.message ?? '收藏失败')
    }
  }

  if (typeof document === 'undefined') return null

  return createPortal(
    <AnimatePresence>
      {sheet && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-black/40"
            onClick={close}
          />
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 28, stiffness: 360 }}
            className="fixed bottom-0 left-0 right-0 z-50 bg-bg-tertiary rounded-t-2xl pb-[env(safe-area-inset-bottom,0px)] desktop-sheet"
          >
            <div className="w-10 h-1 rounded-full bg-separator mx-auto mt-2" />
            <div className="py-1">
              <button
                onClick={() => {
                  toggleAuthorOnly(tid)
                  close()
                }}
                className="w-full px-4 py-3.5 text-[17px] text-center text-primary active:bg-bg-secondary transition-colors"
              >
                {feature.authorOnly ? '查看全部' : '只看作者'}
              </button>
              <button
                onClick={handleFavorite}
                className="w-full px-4 py-3.5 text-[17px] text-center text-primary active:bg-bg-secondary transition-colors"
              >
                {feature.favDone ? '已收藏' : '收藏主题'}
              </button>
              <button
                onClick={close}
                className="w-full px-4 py-3.5 text-[17px] text-center text-text-secondary active:bg-bg-secondary transition-colors border-t border-separator"
              >
                取消
              </button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>,
    document.body
  )
}
