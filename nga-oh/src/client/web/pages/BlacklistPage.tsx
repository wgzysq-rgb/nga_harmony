import { useState, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { UserMinus, Plus, X, User } from 'lucide-react'
import { cn, escHtml } from '@/lib/utils'
import NavBar from '@/components/layout/NavBar'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { useSettingsStore } from '@/stores/settings'
import { useUiStore } from '@/stores/ui'

export default function BlacklistPage() {
  const blacklist = useSettingsStore((s) => s.blacklist)
  const removeBlacklist = useSettingsStore((s) => s.removeBlacklist)
  const openBlacklistAddDialog = useUiStore((s) => s.openBlacklistAddDialog)
  const [removeTarget, setRemoveTarget] = useState<{ userId: string; nickName: string } | null>(null)

  const handleConfirmRemove = useCallback(() => {
    if (removeTarget) {
      removeBlacklist(removeTarget.userId)
      setRemoveTarget(null)
    }
  }, [removeTarget, removeBlacklist])

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
      className="min-h-dvh flex flex-col"
    >
      <NavBar
        showBack
        title="黑名单管理"
        right={
          <button
            onClick={openBlacklistAddDialog}
            className="text-primary text-[15px] flex items-center gap-0.5"
          >
            <Plus size={18} />
            添加
          </button>
        }
      />

      <div className="flex-1 pb-safe">
        {blacklist.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
            <User size={36} strokeWidth={1.2} className="mb-3 opacity-40" />
            <span className="text-[15px]">黑名单为空</span>
            <span className="text-[13px] mt-1">点击右上角添加</span>
          </div>
        )}

        {blacklist.length > 0 && (
          <div className="mx-4 mt-4 bg-bg-tertiary rounded-xl overflow-hidden">
            {blacklist.map((entry, i) => (
              <div
                key={entry.userId}
                className={cn(
                  'flex items-center gap-3 px-4 py-3',
                  i > 0 && 'border-t border-separator'
                )}
              >
                <div className="w-10 h-10 rounded-full bg-bg-secondary flex items-center justify-center shrink-0">
                  <User size={20} className="text-text-tertiary" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-[15px] text-text truncate">
                    {escHtml(entry.nickName)}
                  </div>
                  <div className="text-[13px] text-text-tertiary">
                    UID: {escHtml(entry.userId)}
                  </div>
                </div>
                <button
                  onClick={() => setRemoveTarget(entry)}
                  className="shrink-0 p-2 text-destructive active:bg-bg-secondary rounded-lg transition-colors"
                >
                  <UserMinus size={18} />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      <AnimatePresence>
        {removeTarget && (
          <ConfirmDialog
            title="移除黑名单"
            message={`确定要将 ${removeTarget.nickName} 从黑名单中移除吗？`}
            confirmLabel="移除"
            destructive
            onConfirm={handleConfirmRemove}
            onCancel={() => setRemoveTarget(null)}
          />
        )}
      </AnimatePresence>
    </motion.div>
  )
}
