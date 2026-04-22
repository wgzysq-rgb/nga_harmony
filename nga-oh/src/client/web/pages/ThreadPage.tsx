import { useState, useEffect, useRef, useCallback, useMemo } from 'react'
import { useNav } from '@/hooks/useNav'
import { useQuery } from '@tanstack/react-query'
import { useVirtualizer } from '@tanstack/react-virtual'
import { motion, AnimatePresence } from 'framer-motion'
import { ThumbsUp, MessageCircle, Paperclip } from 'lucide-react'
import { api } from '@/api/client'
import { cn, escHtml, proxyUrl, formatTime, getOriginalUrl, sanitize } from '@/lib/utils'
import NavBar from '@/components/layout/NavBar'
import Avatar from '@/components/Avatar'
import { useUiStore } from '@/stores/ui'
import { useBrowseHistoryStore } from '@/stores/browse-history'
import { useAuthStore } from '@/stores/auth'
import type { Post, ThreadPageData, ThreadInfo } from '../../../shared/types/index.ts'

const PAGE_SIZE = 20

export default function ThreadPage({
  tid,
  page: pageProp,
  pid,
}: {
  tid: string
  page?: number
  pid?: string
} = { tid: '' }) {
  const { goBack } = useNav()
  const openProfileCard = useUiStore((s) => s.openProfileCard)
  const openReplyModal = useUiStore((s) => s.openReplyModal)
  const openThreadActionSheet = useUiStore((s) => s.openThreadActionSheet)
  const threadFeatures = useUiStore((s) => s.threadFeatures)
  const tfForThread = tid ? threadFeatures[tid] : undefined
  const openLightbox = useUiStore((s) => s.openLightbox)
  const addHistory = useBrowseHistoryStore((s) => s.add)
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)

  const [page, setPage] = useState(Number(pageProp) || 1)
  const [allPosts, setAllPosts] = useState<Post[]>([])
  const [expandedAttachments, setExpandedAttachments] = useState<Set<string>>(new Set())
  const [expandedSigs, setExpandedSigs] = useState<Set<string>>(new Set())
  const [expandedComments, setExpandedComments] = useState<Set<string>>(new Set())
  const sentinelRef = useRef<HTMLDivElement>(null)
  const contentRef = useRef<HTMLDivElement>(null)

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['thread', tid, page],
    queryFn: async () => {
      const res = await api.get<{ ok: boolean; data: ThreadPageData }>(`/thread?tid=${tid}&page=${page}`)
      if (!res.ok) throw new Error('加载失败')
      return res.data
    },
    enabled: !!tid,
  })

  const lastAccumulatedPage = useRef<number>(0)

  useEffect(() => {
    setPage(Number(pageProp) || 1)
    setAllPosts([])
    lastAccumulatedPage.current = 0
  }, [tid, pageProp])

  useEffect(() => {
    if (!data?.posts?.length) return
    if (page === 1) {
      setAllPosts(data.posts)
    } else if (page > lastAccumulatedPage.current) {
      setAllPosts((prev) => [...prev, ...data.posts])
      lastAccumulatedPage.current = page
    }
  }, [data, page])

  useEffect(() => {
    if (!data?.threadInfo || !tid || !isAuthenticated) return
    const info = data.threadInfo
    addHistory({
      tid,
      subject: info.subject,
      author: info.author,
      authorid: info.authorid,
      replies: info.replies,
      postDate: 0,
      board: data.forumName ?? '',
    })
  }, [data?.threadInfo, tid, isAuthenticated])

  const hasMore = data ? page < data.pagination.totalPages : false

  const observerRef = useRef<IntersectionObserver | null>(null)

  useEffect(() => {
    if (observerRef.current) observerRef.current.disconnect()
    if (!hasMore) return

    const el = sentinelRef.current
    if (!el) return

    observerRef.current = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setPage((p) => p + 1)
        }
      },
      { rootMargin: '600px' }
    )
    observerRef.current.observe(el)

    return () => {
      observerRef.current?.disconnect()
    }
  }, [hasMore])

  const threadInfo = data?.threadInfo
  const forumName = data?.forumName ?? ''

  const filteredPosts = useMemo(() => {
    const ao = tid ? (tfForThread?.authorOnly ?? false) : false
    if (!ao || !threadInfo) return allPosts
    return allPosts.filter((p) => p.authorid === threadInfo.authorid)
  }, [allPosts, tid, tfForThread, threadInfo])

  const collectContentImages = useCallback((post: Post): string[] => {
    const urls: string[] = []
    const container = document.createElement('div')
    container.innerHTML = post.content
    container.querySelectorAll('img').forEach((img) => {
      const src = img.getAttribute('src')
      if (src) urls.push(getOriginalUrl(src))
    })
    return urls
  }, [])

  const collectAttachImages = useCallback((post: Post): string[] => {
    if (!post.attachs?.length) return []
    return post.attachs
      .filter((att) => att.attachurl)
      .map((att) => getOriginalUrl(proxyUrl(att.attachurl)))
  }, [])

  const handleContentImageClick = useCallback((e: React.MouseEvent, post: Post) => {
    const target = e.target as HTMLElement
    if (target.tagName !== 'IMG') return
    const src = target.getAttribute('src')
    if (!src) return
    const urls = collectContentImages(post)
    if (!urls.length) return
    const clickedUrl = getOriginalUrl(src)
    const idx = urls.indexOf(clickedUrl)
    openLightbox(urls, idx >= 0 ? idx : 0)
  }, [collectContentImages, openLightbox])

  const handleAttachClick = useCallback((post: Post, attachIndex: number) => {
    const urls = collectAttachImages(post)
    if (!urls.length) return
    openLightbox(urls, attachIndex)
  }, [collectAttachImages, openLightbox])

  const handleReplyStart = useCallback((post?: Post) => {
    if (!threadInfo) return
    openReplyModal(
      tid,
      threadInfo.fid,
      post ? { pid: post.pid, lou: post.lou } : null
    )
  }, [tid, threadInfo, openReplyModal])

  const toggleSig = useCallback((pid: string) => {
    setExpandedSigs((prev) => {
      const next = new Set(prev)
      if (next.has(pid)) next.delete(pid)
      else next.add(pid)
      return next
    })
  }, [])

  const toggleComments = useCallback((pid: string) => {
    setExpandedComments((prev) => {
      const next = new Set(prev)
      if (next.has(pid)) next.delete(pid)
      else next.add(pid)
      return next
    })
  }, [])

  const parentRef = useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: filteredPosts.length,
    getScrollElement: () => parentRef.current,
    estimateSize: (index) => {
      const post = filteredPosts[index]
      if (!post) return 200
      let estimate = 120
      if (post.content && post.content.length > 200) estimate += 200
      if (post.content && post.content.length > 1000) estimate += 300
      if (post.attachs?.length) estimate += 100
      if (post.signature) estimate += 40
      if (post.comments?.length) estimate += 60
      return estimate
    },
    overscan: 5,
  })

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      className="flex flex-col h-full"
    >
      <NavBar
        title={threadInfo ? threadInfo.subject : '帖子'}
        showBack
        onBack={goBack}
        right={
          <button
            onClick={() => {
              if (tid) openThreadActionSheet(tid)
            }}
            className="text-primary text-[15px]"
          >
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="5" r="1.5" />
              <circle cx="12" cy="12" r="1.5" />
              <circle cx="12" cy="19" r="1.5" />
            </svg>
          </button>
        }
      />

      <div ref={parentRef} className="flex-1 overflow-y-auto pb-4">
        {isLoading && allPosts.length === 0 && (
          <div className="text-center py-10 text-text-secondary">加载中...</div>
        )}
        {isError && (
          <div className="text-center py-10 text-destructive">
            {(error as Error)?.message ?? '加载失败'}
          </div>
        )}

        <div
          style={{
            height: virtualizer.getTotalSize(),
            width: '100%',
            position: 'relative',
          }}
        >
          {virtualizer.getVirtualItems().map((virtualItem) => {
            const post = filteredPosts[virtualItem.index]
            return (
              <div
                key={post.pid}
                ref={virtualizer.measureElement}
                data-index={virtualItem.index}
                style={{
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  width: '100%',
                  transform: `translateY(${virtualItem.start}px)`,
                }}
                className="px-4 py-4 border-b border-separator-light"
              >
              <PostHeader post={post} threadAuthor={threadInfo?.authorid} />

              {post.isInBlackList ? (
                <div className="py-8 text-center text-[14px] text-text-tertiary">
                  该用户已被屏蔽
                </div>
              ) : (
                <>
                  <div
                    className="mt-2.5 text-[15px] leading-[1.6] break-words [&_img]:rounded-lg [&_img]:max-w-full [&_img]:h-auto [&_img]:cursor-pointer [&_a]:text-primary [&_a]:underline [&_a]:underline-offset-2 [&_blockquote]:border-l-2 [&_blockquote]:border-primary/30 [&_blockquote]:pl-3 [&_blockquote]:text-text-secondary [&_blockquote]:text-[14px] [&_blockquote]:italic [&_blockquote_img]:max-w-[200px] [&_blockquote_img]:max-h-[200px] [&_blockquote_img]:object-cover [&_blockquote_img]:rounded-lg"
                    style={{ fontSize: 'var(--font-size-base, 15px)' }}
                    onClick={(e) => handleContentImageClick(e, post)}
                    dangerouslySetInnerHTML={{ __html: sanitize(post.content) }}
                  />

                  {post.attachs?.length > 0 && (
                    <div className="mt-2">
                      <button
                        onClick={() => {
                          setExpandedAttachments((prev) => {
                            const next = new Set(prev)
                            if (next.has(post.pid)) next.delete(post.pid)
                            else next.add(post.pid)
                            return next
                          })
                        }}
                        className="flex items-center gap-1.5 text-[13px] text-text-tertiary active:text-text-secondary transition-colors px-1 py-0.5"
                      >
                        <Paperclip size={14} />
                        <span>
                          {expandedAttachments.has(post.pid)
                            ? '收起附件'
                            : `附件 (${post.attachs.length})`}
                        </span>
                      </button>
                      <AnimatePresence>
                        {expandedAttachments.has(post.pid) && (
                          <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: 'auto', opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            transition={{ duration: 0.2 }}
                            className="overflow-hidden"
                          >
                            <div className={cn(
                              'mt-1.5 grid gap-1.5',
                              post.attachs.length === 1 ? 'grid-cols-1' :
                              post.attachs.length === 2 ? 'grid-cols-2' : 'grid-cols-3'
                            )}>
                              {post.attachs.map((att, ai) => (
                                <img
                                  key={ai}
                                  src={proxyUrl(att.thumb || att.attachurl)}
                                  alt=""
                                  className="w-full aspect-square object-cover rounded-lg bg-bg-secondary cursor-pointer"
                                  onClick={() => handleAttachClick(post, ai)}
                                />
                              ))}
                            </div>
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </div>
                  )}

                  {post.signature && (
                    <div className="mt-2">
                      <button
                        onClick={() => toggleSig(post.pid)}
                        className="text-[12px] text-text-tertiary active:text-text-secondary transition-colors"
                      >
                        {expandedSigs.has(post.pid) ? '收起签名' : '查看签名'}
                      </button>
                      <AnimatePresence>
                        {expandedSigs.has(post.pid) && (
                          <motion.div
                            initial={{ height: 0, opacity: 0 }}
                            animate={{ height: 'auto', opacity: 1 }}
                            exit={{ height: 0, opacity: 0 }}
                            transition={{ duration: 0.2 }}
                            className="overflow-hidden"
                          >
                            <div
                              className="mt-1 text-[13px] text-text-tertiary border-t border-separator pt-2 [&_img]:rounded [&_img]:max-w-full [&_img]:h-auto"
                              dangerouslySetInnerHTML={{ __html: sanitize(post.signature) }}
                            />
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </div>
                  )}

                  <div className="flex items-center gap-5 mt-3">
                    <button
                      className={cn(
                        'flex items-center gap-1.5 text-[13px] transition-colors duration-150',
                        post.score > 0 ? 'text-primary' : 'text-text-tertiary active:text-text-secondary'
                      )}
                    >
                      <ThumbsUp size={14} />
                      {post.score > 0 && <span>{post.score}</span>}
                    </button>
                    <button
                      onClick={() => handleReplyStart(post)}
                      className="flex items-center gap-1.5 text-[13px] text-text-tertiary active:text-text-secondary transition-colors duration-150"
                    >
                      <MessageCircle size={14} />
                      <span>回复</span>
                    </button>
                    <span className="ml-auto text-[12px] text-text-tertiary">
                      {formatTime(post.postdate)}
                    </span>
                  </div>

                  {post.comments?.length > 0 && (
                    <div className="mt-3 bg-bg-secondary/80 rounded-xl p-3">
                      {post.comments
                        .slice(0, expandedComments.has(post.pid) ? undefined : 2)
                        .map((c, ci) => (
                          <div key={ci} className="text-[13px] leading-relaxed py-0.5">
                            <span
                              className="text-primary font-medium cursor-pointer"
                              onClick={(e) => openProfileCard(c.authorid, e.currentTarget as HTMLElement)}
                            >
                              {escHtml(c.author)}
                            </span>
                            <span className="text-text-tertiary mx-1">:</span>
                            <span className="text-text-secondary">{escHtml(c.content)}</span>
                          </div>
                        ))}
                      {post.comments.length > 2 && (
                        <button
                          onClick={() => toggleComments(post.pid)}
                          className="text-[12px] text-primary mt-1 active:opacity-70 transition-opacity"
                        >
                          {expandedComments.has(post.pid)
                            ? '收起'
                            : `查看全部 ${post.comments.length} 条评论`}
                        </button>
                      )}
                    </div>
                  )}
                </>
              )}
            </div>
            )
          })}
        </div>

        {hasMore && (
          <div ref={sentinelRef} className="py-4 text-center text-[13px] text-text-tertiary">
            加载更多...
          </div>
        )}

        {!hasMore && allPosts.length > 0 && (
          <div className="py-6 text-center text-[13px] text-text-tertiary">
            已加载全部回复
          </div>
        )}
      </div>

      <div className="sticky bottom-6 z-40 flex justify-end pointer-events-none pr-5">
        <button
          onClick={() => handleReplyStart()}
          className="pointer-events-auto w-12 h-12 flex items-center justify-center rounded-2xl bg-primary text-white shadow-lg shadow-primary/25 active:scale-90 transition-transform"
        >
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
          </svg>
        </button>
      </div>

    </motion.div>
  )
}

function PostHeader({ post, threadAuthor }: { post: Post; threadAuthor?: string }) {
  const openProfileCard = useUiStore((s) => s.openProfileCard)

  const louLabel = post.lou === 0
    ? '楼主'
    : post.lou === 1
    ? '沙发'
    : `#${post.lou}`

  const handleUserClick = useCallback((e: React.MouseEvent) => {
    openProfileCard(post.authorid, e.currentTarget as HTMLElement)
  }, [openProfileCard, post.authorid])

  return (
    <div className="flex items-center gap-3">
      <Avatar
        avatar={post.avatar}
        uid={post.authorid}
        name={post.author}
        size={42}
        onClick={handleUserClick}
      />
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-1.5">
          <span
            className="text-[15px] font-medium text-primary truncate cursor-pointer hover:opacity-70 transition-opacity"
            onClick={handleUserClick}
          >
            {escHtml(post.author)}
          </span>
          {post.isanonymous === 1 && (
            <span className="text-[12px]">🎭</span>
          )}
          {post.isMuted && (
            <span className="text-[12px]">🤐</span>
          )}
          {post.memberGroup && (
            <span className="text-[11px] px-1.5 py-0.5 rounded-md bg-primary-light text-primary font-medium truncate max-w-[80px]">
              {escHtml(post.memberGroup)}
            </span>
          )}
        </div>
        <div className="flex items-center gap-2 mt-0.5">
          <span className={cn(
            'text-[11px] px-1.5 py-[2px] rounded-md font-medium',
            post.lou === 0
              ? 'bg-primary-light text-primary'
              : 'bg-bg-secondary text-text-tertiary'
          )}>
            {louLabel}
          </span>
          {post.level > 0 && (
            <span className="text-[11px] text-text-tertiary">Lv.{post.level}</span>
          )}
          {post.fromClient && (
            <span className="text-[11px] text-text-tertiary truncate max-w-[100px]">
              {escHtml(post.fromClient)}
            </span>
          )}
        </div>
      </div>
    </div>
  )
}


