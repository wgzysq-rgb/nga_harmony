import { motion } from 'framer-motion'

export function ConfirmDialog({
  title,
  message,
  confirmLabel = '确定',
  destructive = false,
  onConfirm,
  onCancel,
}: {
  title: string
  message: string
  confirmLabel?: string
  destructive?: boolean
  onConfirm: () => void
  onCancel: () => void
}) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.15 }}
      className="fixed inset-0 z-[100] flex items-center justify-center bg-overlay"
      onClick={onCancel}
    >
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.9, opacity: 0 }}
        transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        className="w-[270px] bg-bg-tertiary rounded-xl overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="pt-6 px-4 pb-2 text-center">
          <div className="text-[17px] font-semibold">{title}</div>
          <div className="text-[13px] text-text-secondary mt-1">{message}</div>
        </div>
        <div className="h-[0.5px] bg-separator mx-0 mt-3" />
        <div className="flex">
          <button
            onClick={onCancel}
            className="flex-1 py-3 text-[17px] text-primary font-normal border-r-[0.5px] border-separator"
          >
            取消
          </button>
          <button
            onClick={onConfirm}
            className={`flex-1 py-3 text-[17px] font-semibold ${destructive ? 'text-destructive' : 'text-primary'}`}
          >
            {confirmLabel}
          </button>
        </div>
      </motion.div>
    </motion.div>
  )
}
