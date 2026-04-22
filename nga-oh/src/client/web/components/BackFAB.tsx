import { useRouterStore } from '@/stores/router'
import { ArrowLeft } from 'lucide-react'

export default function BackFAB() {
  const goBack = useRouterStore((s) => s.goBack)
  const board = useRouterStore((s) => s.board)
  const detailStack = useRouterStore((s) => s.detailStack)

  const canBack = detailStack.length > 0 || !!board

  if (!canBack) return null

  return (
    <button
      onClick={goBack}
      className="fab-back-btn fixed z-[200] w-12 h-12 rounded-full bg-primary text-white shadow-lg
        flex items-center justify-center active:scale-90 transition-transform"
      aria-label="返回"
    >
      <ArrowLeft size={22} />
    </button>
  )
}
