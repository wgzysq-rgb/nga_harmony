import { useState, useCallback, useRef, useEffect } from 'react'
import { useNav } from '@/hooks/useNav'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { api } from '@/api/client'
import { cn, escHtml, formatTime, sanitize } from '@/lib/utils'
import NavBar from '@/components/layout/NavBar'
import { useToastStore } from '@/components/Toast'
import { Send, Loader2, MessageSquare } from 'lucide-react'
import type { MessageArticle, MessageDetailData } from '../../../shared/types/index.ts'

const ease: [number, number, number, number] = [0.25, 0.46, 0.45, 0.94]

const msgVariants = {
  hidden: { opacity: 0, y: 10 },
  visible: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: {
      delay: Math.min(i * 0.05, 0.5),
      duration: 0.3,
      ease,
    },
  }),
}

function MessageBubble({ msg, index }: { msg: MessageArticle; index: number }) {
  const author = msg.author || msg.from || '未知'
  const initial = author.charAt(0).toUpperCase()
  const hue = author.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0) % 360
  const htmlContent = msg.formated_html_data || msg.content || ''

  return (
    <motion.div
      custom={index}
      variants={msgVariants}
      initial="hidden"
      animate="visible"
      className="flex gap-2.5 px-4 py-3"
    >
      <div
        className="w-9 h-9 rounded-full flex items-center justify-center shrink-0 text-white font-semibold text-[14px] mt-0.5"
        style={{ backgroundColor: `hsl(${hue}, 55%, 55%)` }}
      >
        {initial}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-baseline gap-2">
          <span className="text-[14px] font-medium text-primary">{escHtml(author)}</span>
          <span className="text-[12px] text-text-tertiary">
            {formatTime(msg.time)}
          </span>
        </div>
        <div className="mt-1 text-[15px] text-text leading-relaxed break-words [&_a]:text-primary [&_a]:underline">
          {htmlContent.includes('<') ? (
            <div dangerouslySetInnerHTML={{ __html: sanitize(htmlContent) }} />
          ) : (
            escHtml(htmlContent)
          )}
        </div>
      </div>
    </motion.div>
  )
}

export default function MessageDetailPage({ mid }: { mid: string }) {
  const { goBack } = useNav()
  const queryClient = useQueryClient()
  const scrollRef = useRef<HTMLDivElement>(null)
  const bottomRef = useRef<HTMLDivElement>(null)

  const [replyText, setReplyText] = useState('')
  const [sending, setSending] = useState(false)

  const query = useQuery({
    queryKey: ['message-detail', mid],
    queryFn: async () => {
      const res = await api.get<{ ok: boolean; data: MessageDetailData }>(`/messages/${mid}?page=1`)
      return res
    },
    enabled: !!mid,
  })

  useEffect(() => {
    if (query.data?.data?.messageEntryList?.length) {
      setTimeout(() => {
        bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
      }, 300)
    }
  }, [query.data?.data?.messageEntryList?.length])

  const showToast = useToastStore((s) => s.showToast)

  const handleReply = useCallback(async () => {
    const content = replyText.trim()
    if (!content || !mid || sending) return

    setSending(true)
    try {
      const res = await api.post<{ ok: boolean; error?: string }>('/messages/send', {
        mid,
        content,
      })
      if (!res.ok) throw new Error(res.error ?? '回复失败')
      setReplyText('')
      showToast('回复成功')
      queryClient.invalidateQueries({ queryKey: ['message-detail', mid] })
    } catch (err: any) {
      showToast(err.message ?? '回复失败')
    } finally {
      setSending(false)
    }
  }, [replyText, mid, sending, queryClient, showToast])

  const messages = query.data?.data?.messageEntryList ?? []
  const title = query.data?.data?.title ?? '私信详情'
  const isLoading = query.isLoading
  const isEmpty = !isLoading && messages.length === 0

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
      className="min-h-dvh flex flex-col"
    >
      <NavBar title="私信详情" showBack />

      <div
        ref={scrollRef}
        className="flex-1 pb-[calc(56px+env(safe-area-inset-bottom,0px))] overflow-y-auto"
      >
        {title && title !== '私信详情' && (
          <div className="px-4 pt-3 pb-2 bg-bg-tertiary border-b border-separator">
            <h1 className="text-[17px] font-semibold leading-snug">{escHtml(title)}</h1>
          </div>
        )}

        {isLoading && (
          <div className="flex flex-col items-center justify-center py-20">
            <Loader2 size={28} className="text-text-tertiary animate-spin" />
            <span className="mt-3 text-[14px] text-text-tertiary">加载中...</span>
          </div>
        )}

        {!isLoading && messages.length > 0 && (
          <div className="divide-y divide-separator">
            {messages.map((msg: MessageArticle, i: number) => (
              <MessageBubble key={i} msg={msg} index={i} />
            ))}
            <div ref={bottomRef} />
          </div>
        )}

        {isEmpty && !query.isError && (
          <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
            <MessageSquare size={40} strokeWidth={1.2} className="mb-3 opacity-40" />
            <span className="text-[15px]">暂无消息</span>
          </div>
        )}

        {query.isError && (
          <div className="flex flex-col items-center justify-center py-16 text-text-tertiary">
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

      <div className="fixed bottom-0 left-0 right-0 z-40 bg-bg-tertiary/95 backdrop-blur-xl border-t border-separator desktop-sheet">
        <div className="flex items-center gap-2 px-3 py-2 safe-bottom">
          <input
            type="text"
            value={replyText}
            onChange={(e) => setReplyText(e.target.value)}
            placeholder="写回复..."
            className="flex-1 bg-bg-secondary rounded-xl px-3 py-2 text-[15px] outline-none placeholder:text-text-tertiary"
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault()
                handleReply()
              }
            }}
          />
          <button
            onClick={handleReply}
            disabled={!replyText.trim() || sending}
            className="shrink-0 px-4 py-2 bg-primary text-white text-[14px] font-medium rounded-xl active:scale-95 transition-transform disabled:opacity-40 disabled:cursor-not-allowed flex items-center gap-1.5"
          >
            {sending ? (
              <Loader2 size={16} className="animate-spin" />
            ) : (
              <Send size={16} />
            )}
            发送
          </button>
        </div>
      </div>

    </motion.div>
  )
}
