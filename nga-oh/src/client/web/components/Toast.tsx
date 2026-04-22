import { create } from 'zustand'
import { motion, AnimatePresence } from 'framer-motion'

interface ToastState {
  message: string
  showToast: (msg: string) => void
}

let _timer: ReturnType<typeof setTimeout>

export const useToastStore = create<ToastState>((set) => ({
  message: '',
  showToast: (msg: string) => {
    clearTimeout(_timer)
    set({ message: msg })
    _timer = setTimeout(() => set({ message: '' }), 2500)
  },
}))

export function Toast() {
  const message = useToastStore((s) => s.message)

  return (
    <AnimatePresence>
      {message && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 20 }}
          className="fixed bottom-24 left-1/2 -translate-x-1/2 z-[70] bg-black/80 text-white text-[14px] px-4 py-2 rounded-full whitespace-nowrap pointer-events-none"
        >
          {message}
        </motion.div>
      )}
    </AnimatePresence>
  )
}
