import { useState, useMemo, useCallback } from 'react'
import { useNav } from '@/hooks/useNav'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import { Bell, ThumbsUp, MessageCircle, AtSign, Mail, Shield, Eye, Search } from 'lucide-react'
import { api } from '@/api/client'
import { escHtml, formatTime, cn } from '@/lib/utils'
import NavBar from '@/components/layout/NavBar'
import { useUiStore } from '@/stores/ui'
import type { BaseNotification as NgaNotif, NotificationData, NotiType as NotiTypeEnum } from '../../../shared/types/index.ts'

const NotiType = {
  ReplyTopic: 1, ReplyReply: 2, CommentTopic: 3, CommentReply: 4,
  KeywordWatchTopic: 5, KeywordWatchReply: 6, MentionTopic: 7, MentionReply: 8,
  IpChange: 9, MessageNew: 10, MessageReply: 11, MessageAdd: 12,
  ReportTopic: 13, ReportReply: 14, RecommendPost: 15, KeywordWatch: 16, Upvote: 17,
} as const

type NotiTypeValue = NotiTypeEnum | (typeof NotiType)[keyof typeof NotiType]

type NotiCategory = 'thread' | 'message' | 'system' | 'mod'

interface NotiMeta {
  icon: React.ReactNode
  label: string
  category: NotiCategory
}

const NOTI_TYPE_MAP: Record<number, NotiMeta> = {
  [NotiType.ReplyTopic]:       { icon: <MessageCircle size={16} />, label: '回复了你的主题', category: 'thread' },
  [NotiType.ReplyReply]:       { icon: <MessageCircle size={16} />, label: '回复了你的帖子', category: 'thread' },
  [NotiType.CommentTopic]:     { icon: <MessageCircle size={16} />, label: '评论了你的主题', category: 'thread' },
  [NotiType.CommentReply]:     { icon: <MessageCircle size={16} />, label: '评论了你的帖子', category: 'thread' },
  [NotiType.KeywordWatchTopic]:{ icon: <Search size={16} />, label: '触发关键词监控', category: 'system' },
  [NotiType.KeywordWatchReply]:{ icon: <Search size={16} />, label: '触发关键词监控', category: 'system' },
  [NotiType.MentionTopic]:     { icon: <AtSign size={16} className="text-teal-600" />, label: '在主题中提到了你', category: 'thread' },
  [NotiType.MentionReply]:     { icon: <AtSign size={16} className="text-teal-600" />, label: '在帖子中提到了你', category: 'thread' },
  [NotiType.IpChange]:         { icon: <Shield size={16} className="text-red-500" />, label: '账号记录到新IP', category: 'system' },
  [NotiType.MessageNew]:       { icon: <Mail size={16} className="text-green-500" />, label: '给你发了私信', category: 'message' },
  [NotiType.MessageReply]:     { icon: <Mail size={16} className="text-green-500" />, label: '回复了你的私信', category: 'message' },
  [NotiType.MessageAdd]:       { icon: <Mail size={16} className="text-green-500" />, label: '邀请新用户加入对话', category: 'message' },
  [NotiType.ReportTopic]:      { icon: <Eye size={16} />, label: '举报主题', category: 'mod' },
  [NotiType.ReportReply]:      { icon: <Eye size={16} />, label: '举报回复', category: 'mod' },
  [NotiType.RecommendPost]:    { icon: <ThumbsUp size={16} className="text-amber-500" />, label: '推荐帖子', category: 'thread' },
  [NotiType.KeywordWatch]:     { icon: <Search size={16} />, label: '关键词监控', category: 'system' },
  [NotiType.Upvote]:           { icon: <ThumbsUp size={16} className="text-amber-500" />, label: '你的回复获得了支持', category: 'thread' },
}

const FILTERS = [
  { label: '全部', value: 'all' },
  { label: '回复', value: 'reply' },
  { label: '@我', value: 'at' },
  { label: '赞', value: 'vote' },
  { label: '私信', value: 'message' },
]

const FILTER_MAP: Record<string, NotiTypeValue[]> = {
  all: [],
  reply: [NotiType.ReplyTopic, NotiType.ReplyReply, NotiType.CommentTopic, NotiType.CommentReply],
  at: [NotiType.MentionTopic, NotiType.MentionReply],
  vote: [NotiType.Upvote, NotiType.RecommendPost],
  message: [NotiType.MessageNew, NotiType.MessageReply, NotiType.MessageAdd],
}

export default function NotificationPage() {
  const { pushDetail } = useNav()
  const queryClient = useQueryClient()
  const openProfileCard = useUiStore((s) => s.openProfileCard)
  const [activeFilter, setActiveFilter] = useState('all')
  const [clearing, setClearing] = useState(false)

  const { data: notificationData, isLoading, isError, error } = useQuery({
    queryKey: ['notifications'],
    queryFn: async () => {
      const res = await api.get<{ ok: boolean; data: NotificationData }>('/notifications')
      if (!res.ok) throw new Error('加载失败')
      return res.data ?? { items: [], unread: 0, lasttime: 0 }
    },
  })

  const notifications = notificationData?.items ?? []

  const filtered = useMemo(() => {
    const typeFilter = FILTER_MAP[activeFilter] ?? []
    return typeFilter.length
      ? notifications.filter((n) => typeFilter.includes(n.type))
      : notifications
  }, [notifications, activeFilter])

  const handleClearAll = useCallback(async () => {
    if (clearing) return
    setClearing(true)
    try {
      await api.post<{ ok: boolean }>('/notifications/clear', {})
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
    } catch {} finally {
      setClearing(false)
    }
  }, [clearing, queryClient])

  const handleClickNoti = useCallback((n: NgaNotif) => {
    const cat = NOTI_TYPE_MAP[n.type]?.category ?? 'thread'
    if (cat === 'message') {
      pushDetail({ type: 'messages' })
    } else if (n.tid && Number(n.tid) > 0) {
      pushDetail({ type: 'thread', tid: n.tid, pid: n.pid || undefined, page: n.page ? Number(n.page) || undefined : undefined })
    } else if (n.fromUid) {
      pushDetail({ type: 'authorPosts', authorid: n.fromUid, name: n.fromName + '的主题' })
    }
  }, [pushDetail])

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
      className="min-h-dvh flex flex-col"
    >
      <NavBar
        title="通知"
        showBack
        right={
          <button
            onClick={handleClearAll}
            disabled={clearing}
            className="text-primary text-[14px] active:opacity-60 disabled:opacity-40"
          >
            全部已读
          </button>
        }
      />

      <div className="flex mx-4 mt-2 mb-1 bg-bg-secondary rounded-lg p-[3px]">
        {FILTERS.map((f) => (
          <button
            key={f.value}
            onClick={() => setActiveFilter(f.value)}
            className={cn(
              'flex-1 py-[5px] text-[13px] rounded-[7px] transition-all duration-200',
              activeFilter === f.value
                ? 'bg-bg-tertiary text-text font-semibold shadow-sm'
                : 'text-text-tertiary'
            )}
          >
            {f.label}
          </button>
        ))}
      </div>

      <div className="flex-1 mt-1 pb-safe">
        {isLoading && (
          <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
            <div className="w-6 h-6 border-2 border-text-tertiary/30 border-t-text-tertiary rounded-full animate-spin mb-3" />
            <span className="text-[14px]">加载中...</span>
          </div>
        )}

        {isError && (
          <div className="flex flex-col items-center justify-center py-16 text-text-tertiary">
            <span className="text-[14px] mb-3">{(error as Error)?.message ?? '加载失败'}</span>
            <button
              onClick={() => queryClient.invalidateQueries({ queryKey: ['notifications'] })}
              className="px-5 py-2 text-[14px] text-primary bg-bg-secondary rounded-lg active:opacity-60"
            >
              重试
            </button>
          </div>
        )}

        {!isLoading && !isError && filtered.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
            <Bell size={40} strokeWidth={1.2} className="mb-3 opacity-40" />
            <span className="text-[14px]">暂无通知</span>
          </div>
        )}

        {!isLoading && filtered.length > 0 && (
          <div className="bg-bg-tertiary overflow-hidden">
            {filtered.map((n, idx) => {
              const meta = NOTI_TYPE_MAP[n.type] ?? { icon: <Bell size={16} />, label: '通知', category: 'system' as const }
              return (
                <motion.button
                  key={`${n.type}-${n.timeStamp}-${idx}`}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.2, delay: Math.min(idx * 0.03, 0.3) }}
                  onClick={() => handleClickNoti(n)}
                  className="flex items-center gap-3 w-full px-4 py-3 text-left active:bg-bg-secondary transition-colors border-b border-separator"
                >
                  <span className="text-[18px] shrink-0 w-8 text-center leading-none flex items-center justify-center text-text-secondary">
                    {meta.icon}
                  </span>
                  <div className="flex-1 min-w-0">
                    <div className="text-[14px] leading-snug">
                      {n.fromName && (
                        <span
                          className="text-primary font-medium"
                          onClick={(e) => {
                            e.stopPropagation()
                            openProfileCard(n.fromUid, e.currentTarget as HTMLElement)
                          }}
                        >
                          {escHtml(n.fromName)}
                        </span>
                      )}
                      <span className="ml-1 text-text-secondary">{escHtml(meta.label)}</span>
                    </div>
                    {n.text && (
                      <div className="text-[13px] text-text-tertiary mt-0.5 truncate">
                        {escHtml(n.text)}
                      </div>
                    )}
                    <div className="text-[12px] text-text-tertiary/60 mt-0.5">
                      {formatTime(n.timeStamp)}
                    </div>
                  </div>
                </motion.button>
              )
            })}
          </div>
        )}
      </div>
    </motion.div>
  )
}
