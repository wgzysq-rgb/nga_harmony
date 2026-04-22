import { useQuery } from '@tanstack/react-query'
import { useNav } from '@/hooks/useNav'
import { motion } from 'framer-motion'
import { api } from '@/api/client'
import { cn, escHtml, formatTime } from '@/lib/utils'
import NavBar from '@/components/layout/NavBar'
import { useUiStore } from '@/stores/ui'
import { Mail, ChevronRight, PenSquare, Loader2 } from 'lucide-react'
import type { MessageThreadInfo } from '../../../shared/types/index.ts'

interface MessagesResponse {
  ok: boolean
  data: {
    messageEntryList: MessageThreadInfo[]
  }
}

const ease: [number, number, number, number] = [0.25, 0.46, 0.45, 0.94]

const cardVariants = {
  hidden: { opacity: 0, y: 12 },
  visible: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: {
      delay: Math.min(i * 0.04, 0.4),
      duration: 0.3,
      ease,
    },
  }),
}

function ThreadCard({
  thread,
  index,
  onClick,
}: {
  thread: MessageThreadInfo
  index: number
  onClick: () => void
}) {
  const displayName = thread.last_from_username || thread.from_username
  const initial = displayName ? displayName.charAt(0).toUpperCase() : '?'
  const hue = displayName
    ? displayName.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0) % 360
    : 0

  return (
    <motion.button
      custom={index}
      variants={cardVariants}
      initial="hidden"
      animate="visible"
      onClick={onClick}
      className="w-full flex items-center gap-3 px-4 py-3 bg-bg active:bg-bg-secondary transition-colors border-b border-separator text-left"
    >
      <div
        className="w-11 h-11 rounded-full flex items-center justify-center shrink-0 text-white font-semibold text-[17px]"
        style={{ backgroundColor: `hsl(${hue}, 55%, 55%)` }}
      >
        {initial}
      </div>
      <div className="flex-1 min-w-0">
        <div className="text-[15px] font-medium text-text truncate">
          {escHtml(thread.subject)}
        </div>
        <div className="text-[13px] text-text-tertiary mt-0.5 truncate">
          {escHtml(displayName)} · {thread.posts}条消息 · {formatTime(thread.lasttime)}
        </div>
      </div>
      <ChevronRight size={18} className="text-text-tertiary shrink-0" />
    </motion.button>
  )
}

export default function MessageListPage() {
  const { pushDetail } = useNav()
  const openComposeSheet = useUiStore((s) => s.openComposeSheet)

  const query = useQuery({
    queryKey: ['messages'],
    queryFn: async () => {
      const res = await api.get<MessagesResponse>('/messages?page=1')
      return res
    },
  })

  const threads = query.data?.data?.messageEntryList ?? []
  const isLoading = query.isLoading
  const isEmpty = !isLoading && threads.length === 0

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
      className="min-h-dvh flex flex-col bg-bg-tertiary"
    >
      <NavBar
        title="私信"
        showBack
      />

      <div className="flex-1 flex flex-col bg-bg-tertiary rounded-t-xl mt-1 overflow-hidden pb-safe">
        {isLoading && (
          <div className="flex-1 flex flex-col items-center justify-center">
            <Loader2 size={28} className="text-text-tertiary animate-spin" />
            <span className="mt-3 text-[14px] text-text-tertiary">加载中...</span>
          </div>
        )}

        {!isLoading && threads.length > 0 && (
          <div>
            {threads.map((thread, i) => (
              <ThreadCard
                key={thread.mid}
                thread={thread}
                index={i}
                onClick={() => pushDetail({ type: 'messageDetail', mid: String(thread.mid) })}
              />
            ))}
          </div>
        )}

        {isEmpty && !query.isError && (
          <div className="flex-1 flex flex-col items-center justify-center text-text-tertiary">
            <Mail size={40} strokeWidth={1.2} className="mb-3 opacity-40" />
            <span className="text-[15px]">暂无私信</span>
          </div>
        )}

        {query.isError && (
          <div className="flex-1 flex flex-col items-center justify-center text-text-tertiary">
            <span className="text-[15px] mb-3">加载失败</span>
            <button
              onClick={() => query.refetch()}
              className="px-5 py-2 text-[14px] text-primary bg-bg-secondary rounded-lg active:opacity-60"
            >
              重试
            </button>
          </div>
        )}
      </div>

      <div className="sticky bottom-6 z-40 flex justify-end pointer-events-none pr-6">
        <button
          onClick={() => openComposeSheet()}
          className="pointer-events-auto w-12 h-12 flex items-center justify-center rounded-full bg-primary text-white shadow-lg shadow-primary/30 active:scale-90 transition-transform"
        >
          <PenSquare size={22} className="text-white" />
        </button>
      </div>
    </motion.div>
  )
}
