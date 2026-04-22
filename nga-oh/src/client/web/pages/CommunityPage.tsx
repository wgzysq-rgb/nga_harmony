import { useNav } from '@/hooks/useNav'
import { useQuery } from '@tanstack/react-query'
import { api } from '@/api/client'
import { motion } from 'framer-motion'
import { Search } from 'lucide-react'
import { escHtml } from '@/lib/utils'
import { useSettingsStore } from '@/stores/settings'
import { useState } from 'react'
import type { Category } from '../../../shared/types/index.ts'

export default function CommunityPage() {
  const { openBoard, pushDetail } = useNav()
  const favorites = useSettingsStore((s) => s.favorites)
  const [collapsed, setCollapsed] = useState<Set<string>>(new Set())

  const { data: categories, isLoading } = useQuery({
    queryKey: ['forum-categories'],
    queryFn: async () => {
      const res = await api.get<{ ok: boolean; data: Category[] }>('/forum/categories')
      return res.data ?? []
    },
    staleTime: 24 * 60 * 60 * 1000,
  })

  const collectBoards = (cat: Category) => {
    const seen = new Set<number>()
    const boards: { fid: number; name: string }[] = []
    if (cat.sub && Array.isArray(cat.sub)) {
      for (const sub of cat.sub) {
        if (sub.content && Array.isArray(sub.content)) {
          for (const board of sub.content) {
            if (!seen.has(board.fid)) {
              seen.add(board.fid)
              boards.push(board)
            }
          }
        }
      }
    }
    return boards
  }

  const toggleCat = (id: string) => {
    setCollapsed((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
    >
      <div className="sticky top-0 z-50 h-[calc(44px+env(safe-area-inset-top,0px))] safe-top bg-bg-tertiary/80 backdrop-blur-xl border-b border-separator-light flex items-center px-4">
        <div className="flex-1" />
        <div className="text-[16px] font-semibold">社区</div>
        <div className="flex-1 flex justify-end" />
      </div>

      <div
        onClick={() => pushDetail({ type: 'search' })}
        className="flex items-center gap-2.5 bg-bg-secondary rounded-xl px-4 py-2.5 mx-4 my-4 cursor-pointer active:bg-bg transition-colors"
      >
        <Search size={17} className="text-text-tertiary shrink-0" />
        <span className="text-[15px] text-text-tertiary">搜索板块、主题...</span>
      </div>

      {favorites.length > 0 && (
        <div className="mx-4 mb-4 bg-bg-tertiary rounded-2xl overflow-hidden shadow-sm">
          <div className="flex items-center justify-between px-4 pt-3.5 pb-2">
            <span className="text-[13px] font-semibold text-primary">我的收藏</span>
            <span className="text-[11px] text-text-tertiary">{favorites.length} 个板块</span>
          </div>
          <div className="grid grid-cols-4 max-[374px]:grid-cols-4 min-[375px]:grid-cols-5 min-[428px]:grid-cols-6 min-[768px]:grid-cols-8 min-[1280px]:grid-cols-10 gap-0 px-2.5 pb-3.5">
            {favorites.map((f) => (
              <button
                key={f.fid}
                onClick={() => openBoard({ type: 'forum', fid: f.fid, name: f.name })}
                className="flex flex-col items-center gap-1.5 py-2 px-0.5 rounded-xl active:bg-bg-secondary transition-colors"
              >
                 <div className="w-11 h-11 rounded-xl bg-bg-secondary flex items-center justify-center overflow-hidden">
                   <img
                     src={`/api/image-proxy?url=${encodeURIComponent(`http://img4.nga.178.com/ngabbs/nga_classic/f/app/${f.fid}.png`)}`}
                     alt=""
                     className="w-11 h-11 rounded-xl object-cover"
                     onError={(e) => {
                       const img = e.target as HTMLImageElement
                       img.style.display = 'none'
                       const parent = img.parentElement
                       if (parent) parent.textContent = f.name.charAt(0)
                     }}
                   />
                 </div>
                <span className="text-[11px] text-text truncate max-w-full">{escHtml(f.name)}</span>
              </button>
            ))}
          </div>
        </div>
      )}

      <div className="pb-4">
        {isLoading && (
          <div className="text-center py-10 text-text-secondary">加载中...</div>
        )}
        {categories?.map((cat) => {
          const boards = collectBoards(cat)
          if (!boards.length) return null
          const catId = cat.id || cat.name
          const isCollapsed = collapsed.has(catId)
          return (
            <div key={catId} className="mx-4 mb-3">
              <button
                onClick={() => toggleCat(catId)}
                className="flex items-center w-full py-2.5 px-1 text-left"
              >
                <span className="text-[13px] font-semibold">{escHtml(cat.name)}</span>
                <span className="text-[11px] text-text-tertiary ml-1.5 bg-bg-secondary px-1.5 py-0.5 rounded-md">{boards.length}</span>
                <svg
                  className={`w-4 h-4 text-text-tertiary ml-auto transition-transform duration-200 ${isCollapsed ? '-rotate-90' : ''}`}
                  viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
                >
                  <polyline points="6 9 12 15 18 9" />
                </svg>
              </button>
              <motion.div
                initial={false}
                animate={{ height: isCollapsed ? 0 : 'auto', opacity: isCollapsed ? 0 : 1 }}
                transition={{ duration: 0.25, ease: 'easeInOut' }}
                className="overflow-hidden"
              >
                <div className="grid grid-cols-4 max-[374px]:grid-cols-4 min-[375px]:grid-cols-5 min-[428px]:grid-cols-6 min-[768px]:grid-cols-8 min-[1280px]:grid-cols-10 gap-0 bg-bg-tertiary rounded-2xl p-2">
                  {boards.map((board) => {
                    const isFav = favorites.some(f => f.fid === board.fid)
                    return (
                      <button
                        key={board.fid}
                        onClick={() => openBoard({ type: 'forum', fid: board.fid, name: board.name })}
                        className="flex flex-col items-center gap-1.5 py-2.5 px-0.5 rounded-xl active:bg-bg-secondary transition-colors relative"
                      >
                         <div className="w-10 h-10 rounded-xl bg-bg-secondary flex items-center justify-center overflow-hidden">
                           <img
                             src={`/api/image-proxy?url=${encodeURIComponent(`http://img4.nga.178.com/ngabbs/nga_classic/f/app/${board.fid}.png`)}`}
                             alt=""
                             className="w-10 h-10 rounded-xl object-cover"
                             onError={(e) => {
                               const img = e.target as HTMLImageElement
                               img.style.display = 'none'
                               const parent = img.parentElement
                               if (parent) parent.textContent = board.name.charAt(0)
                             }}
                           />
                         </div>
                        {isFav && (
                          <div className="absolute top-1.5 right-[calc(50%-22px+2px)] w-2 h-2 rounded-full bg-warning" />
                        )}
                        <span className="text-[11px] text-text truncate max-w-full">{escHtml(board.name)}</span>
                      </button>
                    )
                  })}
                </div>
              </motion.div>
            </div>
          )
        })}
      </div>
    </motion.div>
  )
}
