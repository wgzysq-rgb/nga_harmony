import { motion } from 'framer-motion'
import { cn } from '@/lib/utils'

interface ActionSheetOption {
  label: string
  value: number | string
}

export function ActionSheet({
  options,
  selected,
  onSelect,
  onClose,
  title,
}: {
  options: ActionSheetOption[]
  selected: number | string
  onSelect: (value: number | string) => void
  onClose: () => void
  title?: string
}) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.15 }}
      className="fixed inset-0 z-[100] flex items-end justify-center bg-overlay"
      onClick={onClose}
    >
      <motion.div
        initial={{ y: '100%' }}
        animate={{ y: 0 }}
        exit={{ y: '100%' }}
        transition={{ type: 'spring', damping: 30, stiffness: 400 }}
        className="w-full max-w-lg bg-bg-tertiary rounded-t-2xl safe-bottom"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex justify-center pt-3 pb-1">
          <div className="w-9 h-1 rounded-full bg-separator" />
        </div>
        {title && (
          <div className="text-[13px] text-text-secondary text-center py-2">{title}</div>
        )}
        <div className="py-2">
          {options.map((opt) => (
            <button
              key={opt.value}
              onClick={() => {
                onSelect(opt.value)
                onClose()
              }}
              className={cn(
                'w-full px-6 py-3.5 text-[17px] text-center transition-colors',
                opt.value === selected ? 'text-primary font-semibold' : 'text-text'
              )}
            >
              {opt.label}
            </button>
          ))}
        </div>
        <div className="h-[8px] bg-bg-secondary" />
        <button
          onClick={onClose}
          className="w-full px-6 py-3.5 text-[17px] font-semibold text-primary text-center"
        >
          取消
        </button>
      </motion.div>
    </motion.div>
  )
}
