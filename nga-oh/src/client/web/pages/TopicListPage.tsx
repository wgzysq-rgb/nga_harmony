import { useState, useEffect, useRef, useCallback } from 'react'
import { useNav } from '@/hooks/useNav'
import { useInfiniteQuery } from '@tanstack/react-query'
import { useVirtualizer } from '@tanstack/react-virtual'
import { motion } from 'framer-motion'
import { api } from '@/api/client'
import { useSettingsStore } from '@/stores/settings'
import { cn, escHtml, escAttr, proxyUrl, formatTime } from '@/lib/utils'
import NavBar from '@/components/layout/NavBar'
import { MessageSquare, RefreshCw, Star } from 'lucide-react'
import type { ThreadPageInfo } from '../../../shared/types/index.ts'

interface TopicResponse {
  ok: boolean
  _page: number
  data: {
    threadPageList: ThreadPageInfo[]
    pagination: { totalPages: number }
  }
}

const FONT_COLORS: Record<number, string> = {
  1: 'text-red-500',
  2: 'text-teal-600',
  4: 'text-green-600',
  8: 'text-orange-500',
  16: 'text-gray-400',
}

const SORT_MODES = [
  { key: 'latest', label: '最新', params: () => ({}) },
  { key: 'recommend', label: '推荐', params: () => ({ recommend: '1' }) },
  { key: 'hot', label: '24h热门', params: () => ({ recommend: '1', twentyfour: '1' }) },
]

function getSubjectClasses(titleFont: number): string {
  const cls: string[] = []
  const color = titleFont & 0x1f
  if (FONT_COLORS[color]) cls.push(FONT_COLORS[color])
  if (titleFont & 32) cls.push('font-bold')
  if (titleFont & 64) cls.push('italic')
  if (titleFont & 128) cls.push('underline')
  return cls.join(' ')
}

function getTypeTags(type: number): string[] {
  const tags: string[] = []
  if (type & 1024) tags.push('[锁定]')
  if (type & 8192) tags.push('[附件]')
  return tags
}

function SkeletonCard({ index }: { index: number }) {
  return (
    <div className={cn('px-4 py-4 border-b border-separator/40', index % 2 === 0 ? 'bg-bg' : 'bg-bg-secondary/50')}>
      <div className="flex flex-col gap-3 animate-pulse">
        <div className="h-[16px] bg-bg-secondary rounded-md w-3/4" />
        <div className="h-[13px] bg-bg-secondary rounded-md w-full" />
        <div className="h-[13px] bg-bg-secondary rounded-md w-4/5" />
        <div className="flex gap-2 mt-1">
          <div className="h-16 w-16 bg-bg-secondary rounded-xl shrink-0" />
          <div className="h-16 w-16 bg-bg-secondary rounded-xl shrink-0" />
          <div className="h-16 w-16 bg-bg-secondary rounded-xl shrink-0" />
        </div>
        <div className="flex justify-between items-center">
          <div className="h-3 bg-bg-secondary rounded-md w-24" />
          <div className="h-3 bg-bg-secondary rounded-md w-10" />
        </div>
      </div>
    </div>
  )
}

const scrollMemory = new Map<string, number>()

function TopicCard({
  thread,
  onClick,
  active,
  index,
}: {
  thread: ThreadPageInfo
  onClick: () => void
  active?: boolean
  index: number
}) {
  const subjectCls = getSubjectClasses(thread.titleFont)
  const tags = getTypeTags(thread.type)
  const images = (thread.previewImages ?? []).slice(0, 3)
  const snippet = thread.previewSnippet ?? thread.replyInfo?.content ?? ''

  return (
    <button
      onClick={onClick}
      title={escAttr(thread.subject)}
      className={cn(
        'w-full text-left px-4 py-4 border-b border-separator/40 transition-colors duration-150',
        active
          ? 'bg-primary-light'
          : index % 2 === 0
            ? 'bg-bg'
            : 'bg-bg-secondary/50',
        !active && 'hover:bg-bg-secondary active:bg-bg-secondary',
      )}
    >
      <div className={cn('text-[15px] leading-snug line-clamp-2', subjectCls || 'text-text')}>
        {tags.length > 0 && (
          <span className="text-text-tertiary mr-0.5">{tags.join('')}</span>
        )}
        {escHtml(thread.subject)}
      </div>

      {snippet && (
        <p className="mt-1.5 text-[13px] text-text-secondary leading-snug line-clamp-2">
          {escHtml(snippet)}
        </p>
      )}

      {images.length > 0 && (
        <div className="flex gap-2 mt-2.5">
          {images.map((src, i) => (
            <img
              key={i}
              src={proxyUrl(src)}
              alt={escAttr(thread.subject)}
              className="h-[72px] w-[72px] rounded-xl object-cover bg-bg-secondary shrink-0"
              loading="lazy"
            />
          ))}
        </div>
      )}

      <div className="flex items-center justify-between mt-2.5 text-[12px] text-text-tertiary">
        <span className="flex items-center gap-1">
          {thread.board && <span className="mr-0.5">{escHtml(thread.board)}</span>}
          {escHtml(thread.author)} · {formatTime(thread.postDate)}
        </span>
        <span className="flex items-center gap-1">
          <MessageSquare size={11} />
          {thread.replies}
        </span>
      </div>
    </button>
  )
}

export default function TopicListPage({
  fid: propFid,
  name: propName,
  authorid: propAuthorid,
  searchpost: propSearchpost,
  activeTid,
  showBack: propShowBack,
}: {
  fid?: string
  name?: string
  authorid?: string
  searchpost?: boolean
  activeTid?: string
  showBack?: boolean
} = {}) {
  const { pushDetail, removeByCategory } = useNav()

  const favorites = useSettingsStore((s) => s.favorites)
  const addFavorite = useSettingsStore((s) => s.addFavorite)
  const removeFavorite = useSettingsStore((s) => s.removeFavorite)

  const isFavorites = propFid === '__favorites__'
  const fid = isFavorites ? undefined : propFid
  const name = propName ?? (isFavorites ? '我的收藏' : '主题列表')
  const authorid = propAuthorid ?? ''
  const searchpost = propSearchpost ?? false

  const numericFid = fid ? Number(fid) : 0
  const isFav = numericFid !== 0 && favorites.some(f => f.fid === numericFid)
  const canFav = numericFid !== 0 && !authorid && !isFavorites

  const handleToggleFav = async () => {
    if (isFav) {
      removeFavorite(numericFid)
    } else {
      const existingFav = favorites.find(f => f.fid === numericFid)
      addFavorite({
        fid: numericFid,
        stid: existingFav?.stid ?? numericFid,
        name: name || '',
      })
    }
  }

  const [sortMode, setSortMode] = useState('latest')
  const [pullY, setPullY] = useState(0)
  const [refreshing, setRefreshing] = useState(false)

  const touchRef = useRef({ startY: 0, canPull: false })
  const sentinelRef = useRef<HTMLDivElement>(null)
  const scrollRef = useRef<HTMLDivElement>(null)
  const showSort = !authorid && !isFavorites

  const buildUrl = useCallback(
    (page: number) => {
      const p = new URLSearchParams()
      if (fid) p.set('fid', fid)
      p.set('page', String(page))
      if (authorid) p.set('authorid', authorid)
      if (searchpost) p.set('searchpost', '1')
      if (isFavorites) p.set('favor', '1')
      if (showSort) {
        const mode = SORT_MODES.find((m) => m.key === sortMode)
        if (mode) {
          Object.entries(mode.params()).forEach(([k, v]) => p.set(k, String(v)))
        }
      }
      return `/topics?${p.toString()}`
    },
    [fid, authorid, searchpost, isFavorites, sortMode, showSort],
  )

  const query = useInfiniteQuery({
    queryKey: [
      'topics',
      {
        fid: fid ?? '',
        authorid,
        searchpost: searchpost ? '1' : '',
        favor: isFavorites ? '1' : '',
        sortMode: showSort ? sortMode : '',
      },
    ],
    queryFn: async ({ pageParam }) => {
      const res = await api.get<TopicResponse>(buildUrl(pageParam as number))
      res._page = pageParam as number
      return res
    },
    staleTime: Infinity,
    initialPageParam: 1,
    getNextPageParam: (lastPage) => {
      if (!lastPage?.ok) return undefined
      const totalPages = lastPage.data?.pagination?.totalPages ?? 0
      const next = (lastPage._page ?? 1) + 1
      return next <= totalPages ? next : undefined
    },
  })

  const allThreads: ThreadPageInfo[] = []
  const seen = new Set<number>()
  if (query.data) {
    for (const page of query.data.pages) {
      if (!page?.ok) continue
      for (const t of page.data.threadPageList) {
        if (!seen.has(t.tid)) {
          seen.add(t.tid)
          allThreads.push(t)
        }
      }
    }
  }

  const virtualizer = useVirtualizer({
    count: allThreads.length,
    getScrollElement: () => scrollRef.current,
    estimateSize: (index) => {
      const thread = allThreads[index]
      if (!thread) return 100
      let h = 60
      const snippet = thread.previewSnippet ?? thread.replyInfo?.content
      if (snippet) h += 40
      if (thread.previewImages?.length) h += 80
      h += 30
      return h
    },
    overscan: 5,
  })

  const scrollKey = `${fid ?? ''}/${authorid}/${searchpost}/${isFavorites}/${showSort ? sortMode : ''}`
  const scrollRestoreDone = useRef(false)
  const virtualizerRef = useRef(virtualizer)
  virtualizerRef.current = virtualizer

  const saveScroll = useCallback(() => {
    const items = virtualizerRef.current.getVirtualItems()
    if (items.length > 0) {
      scrollMemory.set(scrollKey, items[0].index)
    }
  }, [scrollKey])

  useEffect(() => {
    scrollRestoreDone.current = false
    if (scrollMemory.get(scrollKey) === undefined) {
      requestAnimationFrame(() => {
        if (scrollRef.current) scrollRef.current.scrollTo(0, 0)
      })
    }
  }, [scrollKey])

  useEffect(() => {
    if (scrollRestoreDone.current) return
    if (!query.data?.pages?.length) return
    const savedIndex = scrollMemory.get(scrollKey)
    if (savedIndex === undefined) {
      requestAnimationFrame(() => {
        if (scrollRef.current) scrollRef.current.scrollTo(0, 0)
      })
      scrollRestoreDone.current = true
      return
    }
    requestAnimationFrame(() => {
      virtualizer.scrollToIndex(savedIndex, { align: 'start' })
      scrollRestoreDone.current = true
    })
  }, [query.data, scrollKey, virtualizer])

  useEffect(() => {
    const el = sentinelRef.current
    if (!el) return
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (
          entry.isIntersecting &&
          query.hasNextPage &&
          !query.isFetchingNextPage
        ) {
          query.fetchNextPage()
        }
      },
      { root: scrollRef.current, rootMargin: '400px' },
    )
    observer.observe(el)
    return () => observer.disconnect()
  }, [query.hasNextPage, query.isFetchingNextPage, query.fetchNextPage])

  const getScrollEl = useCallback(() => scrollRef.current, [])

  const handleTouchStart = useCallback(
    (e: React.TouchEvent) => {
      if (refreshing) return
      const scroll = getScrollEl() as HTMLElement | null
      if (scroll && scroll.scrollTop <= 0) {
        touchRef.current = {
          startY: e.touches[0].clientY,
          canPull: true,
        }
      } else {
        touchRef.current.canPull = false
      }
    },
    [refreshing, getScrollEl],
  )

  const handleTouchMove = useCallback(
    (e: React.TouchEvent) => {
      if (!touchRef.current.canPull || refreshing) return
      const scroll = getScrollEl() as HTMLElement | null
      if (scroll && scroll.scrollTop > 0) {
        touchRef.current.canPull = false
        setPullY(0)
        return
      }
      const diff = e.touches[0].clientY - touchRef.current.startY
      if (diff > 0) {
        setPullY(Math.min(diff * 0.4, 80))
      }
    },
    [refreshing, getScrollEl],
  )

  const handleTouchEnd = useCallback(async () => {
    if (!touchRef.current.canPull) return
    touchRef.current.canPull = false
    if (pullY > 50 && !refreshing) {
      setRefreshing(true)
      try {
        await query.refetch()
      } finally {
        setRefreshing(false)
      }
    }
    setPullY(0)
  }, [pullY, refreshing, query])

  const isLoading = query.isLoading
  const isEmpty = !isLoading && allThreads.length === 0
  const isFetchingMore = query.isFetchingNextPage

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
      className="h-full flex flex-col relative"
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      <NavBar
        title={name}
        showBack={propShowBack}
        right={canFav ? (
          <button onClick={handleToggleFav} className="p-1" title={isFav ? '取消收藏板块' : '收藏板块'}>
            <Star
              size={20}
              className={cn(
                'transition-colors',
                isFav ? 'text-primary fill-primary' : 'text-text-tertiary',
              )}
            />
          </button>
        ) : undefined}
      />

      {(pullY > 10 || refreshing) && (
        <div className="flex justify-center py-2">
          <RefreshCw
            size={20}
            className={cn(
              'text-text-tertiary transition-transform',
              (refreshing || pullY > 50) && 'animate-spin',
            )}
          />
          <span className="ml-2 text-[13px] text-text-tertiary">
            {refreshing ? '刷新中...' : pullY > 50 ? '松开刷新' : '下拉刷新'}
          </span>
        </div>
      )}

      {showSort && (
        <div className="flex mx-4 mt-3 mb-1 bg-bg-secondary rounded-xl p-[3px]">
          {SORT_MODES.map((mode) => (
            <button
              key={mode.key}
              onClick={() => setSortMode(mode.key)}
              className={cn(
                'flex-1 py-[6px] text-[13px] rounded-[9px] transition-all duration-200',
                sortMode === mode.key
                  ? 'bg-bg-tertiary text-text font-semibold shadow-sm'
                  : 'text-text-tertiary',
              )}
            >
              {mode.label}
            </button>
          ))}
        </div>
      )}

      <div ref={scrollRef} className="flex-1 overflow-y-auto min-h-0 bg-bg-tertiary rounded-t-2xl mt-1">
        {isLoading && (
          <div>
            {Array.from({ length: 8 }, (_, i) => <SkeletonCard key={i} index={i} />)}
          </div>
        )}

        {!isLoading && allThreads.length > 0 && (
          <div
            style={{
              height: virtualizer.getTotalSize(),
              width: '100%',
              position: 'relative',
            }}
          >
            {virtualizer.getVirtualItems().map((virtualItem) => {
              const thread = allThreads[virtualItem.index]
              return (
                <div
                  key={thread.tid}
                  ref={virtualizer.measureElement}
                  data-index={virtualItem.index}
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    transform: `translateY(${virtualItem.start}px)`,
                  }}
                >
                  <TopicCard
                    thread={thread}
                    index={virtualItem.index}
                    active={activeTid === String(thread.tid)}
                    onClick={() => {
                      saveScroll()
                      removeByCategory('thread')
                      pushDetail({ type: 'thread', tid: String(thread.tid) })
                    }}
                  />
                </div>
              )
            })}
          </div>
        )}

        {isEmpty && !query.isError && (
          <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
            <MessageSquare size={40} strokeWidth={1.2} className="mb-3 opacity-40" />
            <span className="text-[15px]">暂无主题</span>
          </div>
        )}

        {query.isError && (
          <div className="flex flex-col items-center justify-center py-20 text-text-tertiary">
            <span className="text-[15px] mb-3">加载失败</span>
            <button
              onClick={() => query.refetch()}
              className="px-5 py-2 text-[14px] text-primary bg-bg-secondary rounded-lg active:opacity-60"
            >
              重试
            </button>
          </div>
        )}

        <div ref={sentinelRef} className="h-1" />

        {isFetchingMore && (
          <div className="flex justify-center py-4 text-[13px] text-text-tertiary">
            <RefreshCw size={16} className="animate-spin mr-2" />
            加载更多...
          </div>
        )}

        {!query.hasNextPage && allThreads.length > 0 && !isLoading && (
          <div className="text-center py-4 text-[12px] text-text-tertiary">
            — 已到底 —
          </div>
        )}
      </div>

      <div className="absolute bottom-6 right-6 z-40 pointer-events-none">
        <button
          onClick={() => query.refetch()}
          className="pointer-events-auto w-11 h-11 flex items-center justify-center rounded-full bg-bg-tertiary shadow-lg border border-separator active:scale-90 transition-transform"
        >
          <RefreshCw
            size={20}
            className={cn('text-primary', query.isFetching && 'animate-spin')}
          />
        </button>
      </div>
    </motion.div>
  )
}
