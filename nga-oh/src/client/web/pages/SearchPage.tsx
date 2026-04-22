import { useState, useEffect, useRef, useCallback } from 'react'
import { useNav } from '@/hooks/useNav'
import { useQuery, useInfiniteQuery } from '@tanstack/react-query'
import { useVirtualizer } from '@tanstack/react-virtual'
import { motion, AnimatePresence } from 'framer-motion'
import { Search, X, Clock, MessageSquare, Hash } from 'lucide-react'
import { api } from '@/api/client'
import { cn, escHtml, escAttr, proxyUrl, formatTime } from '@/lib/utils'
import NavBar from '@/components/layout/NavBar'
import type { ThreadPageInfo, ForumInfo } from '../../../shared/types/index.ts'

type SearchTab = 'topic' | 'content' | 'forum' | 'author'

const TABS: { key: SearchTab; label: string }[] = [
  { key: 'topic', label: '主题' },
  { key: 'content', label: '内容' },
  { key: 'forum', label: '板块' },
  { key: 'author', label: '作者' },
]

interface TopicResponse {
  ok: boolean
  data: {
    threadPageList: ThreadPageInfo[]
    pagination: { totalPages: number }
  }
}

interface ForumSearchResponse {
  ok: boolean
  data: ForumInfo[]
}

function loadHistory(): string[] {
  try {
    return JSON.parse(localStorage.getItem('nga_search_history') ?? '[]')
  } catch {
    return []
  }
}

function saveHistory(keyword: string) {
  const list = loadHistory().filter((k) => k !== keyword)
  list.unshift(keyword)
  if (list.length > 20) list.length = 20
  localStorage.setItem('nga_search_history', JSON.stringify(list))
}

function removeHistory(keyword: string) {
  const list = loadHistory().filter((k) => k !== keyword)
  localStorage.setItem('nga_search_history', JSON.stringify(list))
}

function clearHistory() {
  localStorage.setItem('nga_search_history', '[]')
}

export default function SearchPage() {
  const { pushDetail, openBoard, goBack } = useNav()
  const inputRef = useRef<HTMLInputElement>(null)

  const [keyword, setKeyword] = useState('')
  const [submitted, setSubmitted] = useState('')
  const [tab, setTab] = useState<SearchTab>('topic')
  const [history, setHistory] = useState<string[]>(loadHistory)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  const handleSubmit = useCallback(() => {
    const kw = keyword.trim()
    if (!kw) return
    saveHistory(kw)
    setHistory(loadHistory())
    setSubmitted(kw)
  }, [keyword])

  const handleHistoryClick = useCallback((kw: string) => {
    setKeyword(kw)
    setSubmitted(kw)
    saveHistory(kw)
    setHistory(loadHistory())
  }, [])

  const handleRemoveHistory = useCallback((kw: string) => {
    removeHistory(kw)
    setHistory(loadHistory())
  }, [])

  const handleClearHistory = useCallback(() => {
    clearHistory()
    setHistory([])
  }, [])

  const threadSearchQuery = useInfiniteQuery({
    queryKey: ['search', 'threads', submitted, tab],
    queryFn: async ({ pageParam }) => {
      const p = new URLSearchParams()
      p.set('page', String(pageParam))
      if (tab === 'content') p.set('searchpost', '1')
      if (tab === 'author') {
        p.set('author', submitted)
      } else {
        p.set('key', submitted)
      }
      const res = await api.get<TopicResponse>(`/topics?${p.toString()}`)
      return { ...res, _page: pageParam as number }
    },
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      if (!lastPage?.ok) return undefined
      const totalPages = lastPage.data?.pagination?.totalPages ?? 0
      const next = (lastPage._page ?? 1) + 1
      return next <= totalPages ? next : undefined
    },
    enabled: submitted.length > 0 && tab !== 'forum',
  })

  const forumQuery = useQuery({
    queryKey: ['search', 'forum', submitted],
    queryFn: async () => {
      const res = await api.get<ForumSearchResponse>(`/forum/search?key=${encodeURIComponent(submitted)}`)
      return res
    },
    enabled: submitted.length > 0 && tab === 'forum',
  })

  const allSearchThreads: ThreadPageInfo[] = []
  const seenTids = new Set<number>()
  if (threadSearchQuery.data) {
    for (const page of threadSearchQuery.data.pages) {
      if (!page?.ok) continue
      for (const t of page.data.threadPageList) {
        if (!seenTids.has(t.tid)) {
          seenTids.add(t.tid)
          allSearchThreads.push(t)
        }
      }
    }
  }

  const scrollRef = useRef<HTMLDivElement>(null)
  const searchSentinelRef = useRef<HTMLDivElement>(null)

  const threadVirtualizer = useVirtualizer({
    count: allSearchThreads.length,
    getScrollElement: () => scrollRef.current,
    estimateSize: (index) => {
      const thread = allSearchThreads[index]
      if (!thread) return 90
      let h = 65
      if (thread.previewSnippet) h += 35
      h += 30
      return h
    },
    overscan: 5,
  })

  useEffect(() => {
    const el = searchSentinelRef.current
    if (!el) return
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && threadSearchQuery.hasNextPage && !threadSearchQuery.isFetchingNextPage) {
          threadSearchQuery.fetchNextPage()
        }
      },
      { root: scrollRef.current, rootMargin: '400px' }
    )
    observer.observe(el)
    return () => observer.disconnect()
  }, [threadSearchQuery.hasNextPage, threadSearchQuery.isFetchingNextPage, threadSearchQuery.fetchNextPage])

  const activeQuery = tab === 'forum' ? forumQuery : threadSearchQuery

  const forums = tab === 'forum'
    ? (activeQuery.data as ForumSearchResponse | undefined)?.data ?? []
    : []

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
      className="h-full flex flex-col"
    >
      <NavBar
        showBack
        title="搜索"
      />

      <div className="flex items-center gap-2 px-4 py-2 bg-bg-tertiary border-b border-separator">
        <div className="flex-1 flex items-center gap-2 bg-bg-secondary rounded-lg px-3 py-2">
          <Search size={16} className="text-text-tertiary shrink-0" />
          <input
            ref={inputRef}
            value={keyword}
            onChange={(e) => setKeyword(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSubmit()
            }}
            placeholder="搜索板块、主题、内容..."
            className="flex-1 bg-transparent text-[15px] outline-none placeholder:text-text-tertiary"
          />
          {keyword.length > 0 && (
            <button onClick={() => { setKeyword(''); setSubmitted('') }} className="shrink-0">
              <X size={16} className="text-text-tertiary" />
            </button>
          )}
        </div>
        <button
          onClick={() => goBack()}
          className="text-primary text-[15px] shrink-0"
        >
          取消
        </button>
      </div>

      <div className="flex border-b border-separator bg-bg-tertiary">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={cn(
              'flex-1 py-2.5 text-[14px] text-center relative transition-colors',
              tab === t.key ? 'text-primary font-semibold' : 'text-text-secondary'
            )}
          >
            {t.label}
            {tab === t.key && (
              <motion.div
                layoutId="search-tab-indicator"
                className="absolute bottom-0 left-1/4 right-1/4 h-[2px] bg-primary rounded-full"
                transition={{ type: 'spring', stiffness: 400, damping: 30 }}
              />
            )}
          </button>
        ))}
      </div>

      <div ref={scrollRef} className="flex-1 overflow-y-auto min-h-0">
        {submitted.length === 0 ? (
          <div className="px-4 pt-4">
            {history.length > 0 && (
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-[13px] font-semibold text-text-secondary">搜索历史</span>
                  <button
                    onClick={handleClearHistory}
                    className="text-[13px] text-text-tertiary active:text-text-secondary"
                  >
                    清空
                  </button>
                </div>
                <div className="flex flex-wrap gap-2">
                  {history.map((kw) => (
                    <div
                      key={kw}
                      className="flex items-center gap-1 bg-bg-secondary rounded-full px-3 py-1.5"
                    >
                      <button
                        onClick={() => handleHistoryClick(kw)}
                        className="text-[14px] text-text active:text-primary"
                      >
                        {escHtml(kw)}
                      </button>
                      <button onClick={() => handleRemoveHistory(kw)} className="shrink-0">
                        <X size={12} className="text-text-tertiary" />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
            {history.length === 0 && (
              <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
                <Clock size={36} strokeWidth={1.2} className="mb-3 opacity-40" />
                <span className="text-[14px]">暂无搜索历史</span>
              </div>
            )}
          </div>
        ) : (
          <AnimatePresence mode="wait">
            {activeQuery.isLoading && (
              <motion.div
                key="loading"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="text-center py-10 text-text-secondary"
              >
                搜索中...
              </motion.div>
            )}

            {!activeQuery.isLoading && (tab === 'topic' || tab === 'content' || tab === 'author') && (
              <motion.div
                key={`threads-${tab}`}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.15 }}
              >
                {allSearchThreads.length === 0 && !threadSearchQuery.isError && (
                  <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
                    <Search size={36} strokeWidth={1.2} className="mb-3 opacity-40" />
                    <span className="text-[14px]">未找到相关结果</span>
                  </div>
                )}
                {allSearchThreads.length === 0 && threadSearchQuery.isError && (
                  <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
                    <span className="text-[14px] mb-3">搜索失败</span>
                    <button
                      onClick={() => threadSearchQuery.refetch()}
                      className="px-5 py-2 text-[14px] text-primary bg-bg-secondary rounded-lg active:opacity-60"
                    >
                      重试
                    </button>
                  </div>
                )}
                {allSearchThreads.length > 0 && (
                  <div
                    style={{
                      height: threadVirtualizer.getTotalSize(),
                      width: '100%',
                      position: 'relative',
                    }}
                  >
                    {threadVirtualizer.getVirtualItems().map((virtualItem) => {
                      const thread = allSearchThreads[virtualItem.index]
                      return (
                        <div
                          key={thread.tid}
                          ref={threadVirtualizer.measureElement}
                          data-index={virtualItem.index}
                          style={{
                            position: 'absolute',
                            top: 0,
                            left: 0,
                            width: '100%',
                            transform: `translateY(${virtualItem.start}px)`,
                          }}
                        >
                          <button
                            onClick={() => pushDetail({ type: 'thread', tid: String(thread.tid) })}
                            className="w-full text-left px-4 py-3 border-b border-separator bg-bg active:bg-bg-secondary transition-colors"
                          >
                            <div className="text-[15px] leading-snug line-clamp-2 text-text">
                              {escHtml(thread.subject)}
                            </div>
                            {thread.previewSnippet && (
                              <p className="mt-1 text-[13px] text-text-secondary leading-snug line-clamp-2">
                                {escHtml(thread.previewSnippet)}
                              </p>
                            )}
                            <div className="flex items-center justify-between mt-2 text-[12px] text-text-tertiary">
                              <span>
                                {escHtml(thread.author)} · {formatTime(thread.postDate)}
                              </span>
                              <span className="flex items-center gap-0.5">
                                <MessageSquare size={12} />
                                {thread.replies}
                              </span>
                            </div>
                          </button>
                        </div>
                      )
                    })}
                  </div>
                )}
                <div ref={searchSentinelRef} className="h-1" />
                {threadSearchQuery.isFetchingNextPage && (
                  <div className="text-center py-4 text-[13px] text-text-tertiary">加载更多...</div>
                )}
                {allSearchThreads.length > 0 && !threadSearchQuery.hasNextPage && !threadSearchQuery.isFetchingNextPage && (
                  <div className="text-center py-4 text-[13px] text-text-tertiary">— 已到底 —</div>
                )}
              </motion.div>
            )}

            {!activeQuery.isLoading && tab === 'forum' && (
              <motion.div
                key="forums"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.15 }}
              >
                {forums.length === 0 && (
                  <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
                    <Hash size={36} strokeWidth={1.2} className="mb-3 opacity-40" />
                    <span className="text-[14px]">未找到相关板块</span>
                  </div>
                )}
                {forums.map((forum) => (
                  <button
                    key={forum.fid}
                    onClick={() => openBoard({ type: 'forum', fid: forum.fid, name: forum.name })}
                    className="w-full text-left flex items-center gap-3 px-4 py-3 border-b border-separator bg-bg active:bg-bg-secondary transition-colors"
                  >
                    <div className="w-10 h-10 rounded-[10px] bg-bg-secondary flex items-center justify-center overflow-hidden shrink-0">
                      <img
                        src={`/api/image-proxy?url=${encodeURIComponent(`http://img4.nga.178.com/ngabbs/nga_classic/f/app/${forum.fid}.png`)}`}
                        alt=""
                        className="w-10 h-10 rounded-[10px] object-cover"
                        onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }}
                      />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-[15px] text-text truncate">{escHtml(forum.name)}</div>
                      {forum.info && (
                        <div className="text-[12px] text-text-tertiary mt-0.5 truncate">{escHtml(forum.info)}</div>
                      )}
                    </div>
                  </button>
                ))}
              </motion.div>
            )}
          </AnimatePresence>
        )}
      </div>
    </motion.div>
  )
}
