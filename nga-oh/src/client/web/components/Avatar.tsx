import { useState, useMemo } from 'react'
import { cn, getAvatarUrl } from '@/lib/utils'

export default function Avatar({
  avatar,
  uid,
  name,
  size = 40,
  className,
  onClick,
}: {
  avatar?: string
  uid?: number | string
  name?: string
  size?: number
  className?: string
  onClick?: (e: React.MouseEvent) => void
}) {
  const [imgError, setImgError] = useState(false)
  const avatarUrl = getAvatarUrl(avatar || '', uid)

  const initial = useMemo(() => {
    const ch = String(name || '?').charAt(0).toUpperCase()
    return ch || '?'
  }, [name])

  const hue = useMemo(() => {
    const n = String(name || '?')
    return n.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0) % 360
  }, [name])

  const showImg = avatarUrl && !imgError

  return (
    <div
      className={cn(
        'rounded-full overflow-hidden shrink-0 bg-bg-secondary flex items-center justify-center',
        className,
      )}
      style={{ width: size, height: size }}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
    >
      {showImg ? (
        <img
          src={avatarUrl}
          alt=""
          className="w-full h-full object-cover"
          onError={() => setImgError(true)}
        />
      ) : (
        <div
          className="w-full h-full flex items-center justify-center text-white font-semibold"
          style={{
            fontSize: size * 0.4,
            backgroundColor: `hsl(${hue}, 55%, 55%)`,
          }}
        >
          {initial}
        </div>
      )}
    </div>
  )
}
