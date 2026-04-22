import { useNav } from '@/hooks/useNav'

interface NavBarProps {
  title?: string
  showBack?: boolean
  onBack?: () => void
  right?: React.ReactNode
}

export default function NavBar({ title, showBack, onBack, right }: NavBarProps) {
  const { goBack } = useNav()

  return (
    <div className="sticky top-0 z-50 h-[calc(44px+env(safe-area-inset-top,0px))] safe-top bg-bg-tertiary/80 backdrop-blur-xl border-b border-separator-light flex items-center shrink-0 px-4">
      <div className="min-w-[60px] flex items-center">
        {showBack && (
          <button
            onClick={() => onBack ? onBack() : goBack()}
            className="flex items-center gap-0.5 text-primary text-[15px] hover:opacity-70 transition-opacity duration-150"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="15 18 9 12 15 6" />
            </svg>
            返回
          </button>
        )}
      </div>
      <div className="flex-1 text-center text-[16px] font-semibold truncate px-2">
        {title}
      </div>
      <div className="min-w-[60px] flex items-center justify-end">
        {right}
      </div>
    </div>
  )
}
