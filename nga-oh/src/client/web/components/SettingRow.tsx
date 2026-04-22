import { cn } from '@/lib/utils'

export default function SettingRow({
  icon,
  iconColor,
  label,
  right,
  onClick,
  destructive,
}: {
  icon: React.ReactNode
  iconColor: string
  label: string
  right?: React.ReactNode
  onClick?: () => void
  destructive?: boolean
}) {
  return (
    <button
      onClick={onClick}
      className={cn(
        'flex items-center w-full px-4 py-2.5 min-h-[44px] active:bg-bg-secondary transition-colors text-left',
        destructive && 'text-destructive'
      )}
    >
      <div
        className={cn(
          'w-[29px] h-[29px] rounded-[6px] flex items-center justify-center shrink-0 mr-3',
          iconColor
        )}
      >
        {icon}
      </div>
      <span className="flex-1 text-[17px]">{label}</span>
      {right}
    </button>
  )
}
