import { useState, useEffect } from 'react'
import { api } from '@/api/client'

export function useUnreadCounts(enabled = true) {
  const [unreadNotifications, setUnreadNotifications] = useState(0)
  const [unreadMessages, setUnreadMessages] = useState(0)

  useEffect(() => {
    if (!enabled) return
    api.get<{ ok: boolean; data: { unread: number } }>('/notifications')
      .then((res) => {
        if (res.data) setUnreadNotifications(res.data.unread ?? 0)
      })
      .catch(() => {})
    api.get<{ ok: boolean; data: { messageEntryList: { unread?: boolean }[]; unreadCount?: number } }>('/messages?page=1')
      .then((res) => {
        if (res.data) {
          if (typeof res.data.unreadCount === 'number') {
            setUnreadMessages(res.data.unreadCount)
          } else if (res.data.messageEntryList) {
            setUnreadMessages(res.data.messageEntryList.filter((m: any) => m.unread).length)
          }
        }
      })
      .catch(() => {})
  }, [enabled])

  return { unreadNotifications, unreadMessages }
}
