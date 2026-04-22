import { useEffect, useState, useCallback } from 'react'
import { createPortal } from 'react-dom'
import { useNav } from '@/hooks/useNav'
import { useQuery } from '@tanstack/react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { api } from '@/api/client'
import { escHtml, fmtNum, formatTime } from '@/lib/utils'
import Avatar from '@/components/Avatar'
import { useSettingsStore } from '@/stores/settings'
import { useUiStore } from '@/stores/ui'
import type { UserProfile } from '../../../shared/types/index.ts'

const CARD_WIDTH = 300
const ARROW_SIZE = 8
const GAP = 6

export default function ProfileCardPopup() {
  const profileCard = useUiStore((s) => s.profileCard)
  const closeProfileCard = useUiStore((s) => s.closeProfileCard)
  const { pushDetail } = useNav()
  const addBlacklist = useSettingsStore((s) => s.addBlacklist)
  const blacklist = useSettingsStore((s) => s.blacklist)
  const [toast, setToast] = useState('')
  const [position, setPosition] = useState<{ top: number; left: number; showBelow: boolean } | null>(null)

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['profile', profileCard?.uid],
    queryFn: async () => {
      const res = await api.get<{ ok: boolean; data: UserProfile }>(`/user/${profileCard!.uid}`)
      return res.data
    },
    enabled: !!profileCard,
  })

  const showToast = useCallback((msg: string) => {
    setToast(msg)
    setTimeout(() => setToast(''), 2500)
  }, [])

  useEffect(() => {
    if (!profileCard) {
      setPosition(null)
      return
    }
    const rect = profileCard.anchorRect
    const vh = window.innerHeight
    const estimatedHeight = 380
    const spaceBelow = vh - rect.bottom
    const spaceAbove = rect.top
    const showBelow = spaceBelow >= estimatedHeight + GAP + ARROW_SIZE || spaceBelow >= spaceAbove

    let top: number
    if (showBelow) {
      top = rect.bottom + GAP + ARROW_SIZE
    } else {
      top = rect.top - estimatedHeight - GAP - ARROW_SIZE
    }

    let left = rect.left + rect.width / 2 - CARD_WIDTH / 2
    if (left < GAP) left = GAP
    if (left + CARD_WIDTH > window.innerWidth - GAP) left = window.innerWidth - GAP - CARD_WIDTH

    setPosition({ top, left, showBelow })
  }, [profileCard])

  useEffect(() => {
    if (!profileCard) return
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeProfileCard()
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [profileCard, closeProfileCard])

  if (!profileCard || !position) return null

  const profile = data
  const isBlacklisted = blacklist.some((u) => u.userId === profileCard.uid)

  const arrowStyle = position.showBelow
    ? { top: -(ARROW_SIZE - 1), borderBottom: `${ARROW_SIZE}px solid var(--color-bg-tertiary, hsl(0 0% 100%))` }
    : { bottom: -(ARROW_SIZE - 1), borderTop: `${ARROW_SIZE}px solid var(--color-bg-tertiary, hsl(0 0% 100%))` }

  const arrowLeft = Math.max(
    ARROW_SIZE + 4,
    Math.min(
      profileCard.anchorRect.left + profileCard.anchorRect.width / 2 - position.left - ARROW_SIZE,
      CARD_WIDTH - ARROW_SIZE * 2 - 4
    )
  )

  return createPortal(
    <AnimatePresence>
      <motion.div
        key="pc-overlay"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-[500]"
        onClick={closeProfileCard}
      />
      <motion.div
        key="pc-card"
        initial={{ opacity: 0, scale: 0.92, y: 4 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.92, y: 4 }}
        transition={{ duration: 0.18, ease: [0.2, 0.9, 0.3, 1] }}
        className="fixed z-[501] w-[300px] overflow-hidden rounded-2xl shadow-[0_8px_40px_rgba(0,0,0,0.18),0_0_0_0.5px_var(--color-separator,rgba(0,0,0,0.1))]"
        style={{
          top: position.top,
          left: position.left,
          backgroundColor: 'var(--color-bg-tertiary, #fff)',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div
          className="absolute w-0 h-0"
          style={{
            left: arrowLeft,
            borderLeft: `${ARROW_SIZE}px solid transparent`,
            borderRight: `${ARROW_SIZE}px solid transparent`,
            filter: 'drop-shadow(0 -1px 0 var(--color-separator, rgba(0,0,0,0.1)))',
            ...arrowStyle,
          }}
        />

        {isLoading && (
          <div className="flex items-center justify-center gap-2 py-12 text-text-secondary text-[14px]">
            <div className="w-4 h-4 border-2 border-separator border-t-primary rounded-full animate-spin" />
            加载中
          </div>
        )}

        {isError && (
          <div className="py-10 text-center text-destructive text-[14px]">
            {(error as Error)?.message ?? '获取失败'}
          </div>
        )}

        {profile && (
          <>
            <div className="h-[52px] relative bg-gradient-to-br from-primary to-[#5856D6] dark:from-[#1c1c3a] dark:to-[#2c2c4e]">
              <div className="absolute -bottom-[22px] left-4">
                <Avatar
                  avatar={profile.avatarUrl}
                  uid={profile.uid}
                  name={profile.userName}
                  size={44}
                  className="ring-3 ring-bg-tertiary"
                />
              </div>
              <div className="absolute -bottom-[22px] right-3 flex gap-1 items-end">
                {profile.group && (
                  <span className="text-[10px] px-1.5 py-0.5 rounded bg-bg-secondary/90 text-text-secondary font-medium leading-tight">
                    {escHtml(profile.group)}
                  </span>
                )}
                {profile.muteTime && (
                  <span className="text-[10px] px-1.5 py-0.5 rounded bg-[#FF3B30] text-white font-medium leading-tight">
                    禁言中
                  </span>
                )}
              </div>
            </div>

            <div className="px-4 pt-7 pb-1">
              <div className="text-[15px] font-semibold text-text leading-tight">
                {escHtml(profile.userName)}
              </div>
              {(profile.title || profile.honor) && (
                <div className="text-[12px] text-text-secondary mt-0.5 leading-tight">
                  {[profile.title, profile.honor].filter(Boolean).join(' · ')}
                </div>
              )}
              <div className="text-[10px] text-text-tertiary mt-0.5">UID: {escHtml(profile.uid)}</div>

              {(() => {
                const stats: { label: string; value: string }[] = []
                if (profile.posts) stats.push({ label: '发帖', value: fmtNum(profile.posts) })
                if (profile.fame) stats.push({ label: '威望', value: fmtNum(profile.fame) })
                if (profile.rvrc) stats.push({ label: 'RVRC', value: fmtNum(profile.rvrc) })
                if (profile.money) stats.push({ label: '金钱', value: fmtNum(profile.money) })
                if (!stats.length) return null
                return (
                  <div
                    className="grid gap-0.5 mt-2 bg-bg-secondary rounded-md p-1"
                    style={{ gridTemplateColumns: `repeat(${Math.min(stats.length, 4)}, 1fr)` }}
                  >
                    {stats.map((s) => (
                      <div key={s.label} className="text-center px-1 py-1">
                        <div className="text-[13px] font-semibold text-text leading-tight">{s.value}</div>
                        <div className="text-[10px] text-text-tertiary mt-px">{s.label}</div>
                      </div>
                    ))}
                  </div>
                )
              })()}

              {(() => {
                const rows: [string, string][] = []
                if (profile.regdate) rows.push(['注册日期', formatTime(profile.regdate)])
                if (profile.ipLoc) rows.push(['IP属地', profile.ipLoc])
                if (profile.followByNum) rows.push(['被关注', String(profile.followByNum)])
                if (profile.adminForums && typeof profile.adminForums !== 'string' && profile.adminForums.length) {
                  rows.push(['管理版面', profile.adminForums.map((f: { name: string }) => f.name).join(', ')])
                }
                if (!rows.length) return null
                return (
                  <div className="mt-1">
                    {rows.map(([label, value]) => (
                      <div
                        key={label}
                        className="flex justify-between items-center py-[5px] text-[12px] border-t border-separator first:border-t-0"
                      >
                        <span className="text-text-secondary">{label}</span>
                        <span className="text-text font-medium text-right max-w-[60%] overflow-hidden text-ellipsis whitespace-nowrap">
                          {escHtml(value)}
                        </span>
                      </div>
                    ))}
                  </div>
                )
              })()}

              {profile.sign && (
                <div className="mt-1 pt-1 border-t border-separator text-[12px] text-text-tertiary leading-relaxed max-h-[54px] overflow-hidden">
                  {escHtml(profile.sign)}
                </div>
              )}
            </div>

            <div className="flex border-t border-separator mt-1">
              <button
                className="flex-1 py-2.5 text-center text-[12px] font-medium text-primary active:bg-bg-secondary transition-colors border-r border-separator"
                onClick={() => {
                  closeProfileCard()
                  pushDetail({ type: 'authorPosts', authorid: profile.uid, name: profile.userName + '的主题' })
                }}
              >
                主题
              </button>
              <button
                className="flex-1 py-2.5 text-center text-[12px] font-medium text-primary active:bg-bg-secondary transition-colors border-r border-separator"
                onClick={() => {
                  closeProfileCard()
                  pushDetail({ type: 'authorPosts', authorid: profile.uid, name: profile.userName + '的回帖', searchpost: true })
                }}
              >
                回帖
              </button>
              <button
                className="flex-1 py-2.5 text-center text-[12px] font-medium text-primary active:bg-bg-secondary transition-colors border-r border-separator"
                onClick={() => {
                  closeProfileCard()
                  pushDetail({ type: 'messages' })
                }}
              >
                私信
              </button>
              <button
                className={`flex-1 py-2.5 text-center text-[12px] font-medium active:bg-bg-secondary transition-colors ${
                  isBlacklisted ? 'text-text-tertiary' : 'text-destructive'
                }`}
                onClick={() => {
                  if (isBlacklisted) {
                    showToast('已在黑名单中')
                    return
                  }
                  addBlacklist({ userId: String(profile.uid), nickName: profile.userName || `User${profile.uid}` })
                  showToast('已加入黑名单')
                }}
              >
                {isBlacklisted ? '已拉黑' : '拉黑'}
              </button>
            </div>
          </>
        )}

        <AnimatePresence>
          {toast && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 10 }}
              className="absolute bottom-2 left-1/2 -translate-x-1/2 bg-black/80 text-white text-[12px] px-3 py-1.5 rounded-full whitespace-nowrap pointer-events-none z-10"
            >
              {toast}
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </AnimatePresence>,
    document.body
  )
}
