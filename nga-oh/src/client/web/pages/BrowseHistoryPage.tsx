import { useState, useCallback, useEffect } from 'react'
import { useNav } from '@/hooks/useNav'
import { motion, AnimatePresence } from 'framer-motion'
import { Clock, Trash2, MessageSquare } from 'lucide-react'
import { escHtml, formatTime } from '@/lib/utils'
import NavBar from '@/components/layout/NavBar'
import { useBrowseHistoryStore } from '@/stores/browse-history'
import { useToastStore } from '@/components/Toast'
import { ConfirmDialog } from '@/components/ConfirmDialog'

export default function BrowseHistoryPage() {
  const { pushDetail, removeByCategory } = useNav()
  const items = useBrowseHistoryStore((s) => s.items)
  const fetch = useBrowseHistoryStore((s) => s.fetch)
  const remove = useBrowseHistoryStore((s) => s.remove)
  const clear = useBrowseHistoryStore((s) => s.clear)
  const showToast = useToastStore((s) => s.showToast)
  const [showConfirm, setShowConfirm] = useState(false)

  useEffect(() => { fetch() }, [fetch])

  const handleClear = useCallback(() => {
    clear()
    showToast('已清空浏览记录')
    setShowConfirm(false)
  }, [clear, showToast])

  const handleClick = useCallback((tid: string) => {
    removeByCategory('thread')
    pushDetail({ type: 'thread', tid })
  }, [pushDetail, removeByCategory])

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
      className="flex flex-col h-full"
    >
      <NavBar
        showBack
        title={`浏览历史 (${items.length})`}
        right={
          items.length > 0 ? (
            <button
              onClick={() => setShowConfirm(true)}
              className="text-destructive text-[14px] px-2"
            >
              清空
            </button>
          ) : undefined
        }
      />

      <div className="flex-1 pb-4 overflow-y-auto">
        {items.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
            <Clock size={40} strokeWidth={1.2} className="mb-3 opacity-40" />
            <span className="text-[15px]">暂无浏览记录</span>
          </div>
        )}

        <div className="divide-y divide-separator">
          {items.map((item, i) => (
            <motion.button
              key={item.tid}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.25, delay: Math.min(i * 0.03, 0.3) }}
              onClick={() => handleClick(item.tid)}
              className="relative w-full text-left px-4 py-3 bg-bg active:bg-bg-secondary transition-colors pr-10"
            >
              <div className="text-[15px] leading-snug line-clamp-2 text-text">
                {escHtml(item.subject)}
              </div>
              <div className="flex items-center justify-between mt-1.5 text-[12px] text-text-tertiary">
                <span>
                  {item.board && <span className="mr-1">{escHtml(item.board)}</span>}
                  {escHtml(item.author)} · {formatTime(item.ts / 1000)}
                </span>
                <span className="flex items-center gap-0.5">
                  <MessageSquare size={12} />
                  {item.replies}
                </span>
              </div>
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  remove(item.tid)
                }}
                className="absolute right-3 top-1/2 -translate-y-1/2 p-2 text-text-tertiary active:text-destructive transition-colors"
              >
                <Trash2 size={16} />
              </button>
            </motion.button>
          ))}
        </div>
      </div>

      <AnimatePresence>
        {showConfirm && (
          <ConfirmDialog
            title="清空浏览记录"
            message="确定清空所有浏览记录？此操作不可撤销。"
            confirmLabel="清空"
            destructive
            onConfirm={handleClear}
            onCancel={() => setShowConfirm(false)}
          />
        )}
      </AnimatePresence>
    </motion.div>
  )
}
