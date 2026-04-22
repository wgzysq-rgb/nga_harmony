import { useState, useEffect } from 'react'
import { useNav } from '@/hooks/useNav'
import { useRouterStore } from '@/stores/router'
import { useQuery } from '@tanstack/react-query'
import { useAuthStore } from '@/stores/auth'
import { useThemeStore } from '@/stores/theme'
import { useSettingsStore } from '@/stores/settings'
import { api } from '@/api/client'
import { Sun, Moon, ChevronRight, Users, User, Star, StarOff } from 'lucide-react'
import { cn, escHtml } from '@/lib/utils'
import Avatar from '@/components/Avatar'
import CommunityPage from '@/pages/CommunityPage'
import type { Category } from '../../../../shared/types/index.ts'

function DesktopSidebar() {
  const { openBoard, pushDetail } = useNav()
  const user = useAuthStore((s) => s.currentUser)
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const theme = useThemeStore((s) => s.theme)
  const toggleTheme = useThemeStore((s) => s.toggleTheme)
  const favorites = useSettingsStore((s) => s.favorites)
  const fetchFavorites = useSettingsStore((s) => s.fetchFavorites)
  const addFavorite = useSettingsStore((s) => s.addFavorite)
  const removeFavorite = useSettingsStore((s) => s.removeFavorite)
  const board = useRouterStore((s) => s.board)
  const [collapsed, setCollapsed] = useState<Set<string>>(new Set())

  const favFids = new Set(favorites.map(f => f.fid))

  useEffect(() => {
    if (isAuthenticated) {
      fetchFavorites()
    }
  }, [isAuthenticated, fetchFavorites])

  const { data: categories } = useQuery({
    queryKey: ['forum-categories'],
    queryFn: async () => {
      const res = await api.get<{ ok: boolean; data: Category[] }>('/forum/categories')
      return res.data ?? []
    },
    staleTime: 24 * 60 * 60 * 1000,
    enabled: isAuthenticated,
  })

  const collectBoards = (cat: Category) => {
    const seen = new Set<number>()
    const boards: { fid: number; name: string }[] = []
    if (cat.sub && Array.isArray(cat.sub)) {
      for (const sub of cat.sub) {
        if (sub.content && Array.isArray(sub.content)) {
          for (const b of sub.content) {
            if (!seen.has(b.fid)) {
              seen.add(b.fid)
              boards.push(b)
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

  const boardIcon = (fid: number) =>
    `/api/image-proxy?url=${encodeURIComponent(`http://img4.nga.178.com/ngabbs/nga_classic/f/app/${fid}.png`)}`

  const isActive = (fid: number) =>
    board?.type === 'forum' && board.fid === fid

  const handleBoardClick = (fid: number, name: string) => {
    openBoard({ type: 'forum', fid, name })
  }

  const handleToggleFav = async (fid: number, name: string, e: React.MouseEvent) => {
    e.stopPropagation()
    if (favFids.has(fid)) {
      removeFavorite(fid)
    } else {
      addFavorite({ fid, stid: fid, name })
    }
  }

  return (
    <aside className="hidden lg:flex sticky top-0 h-dvh w-[280px] shrink-0 flex-col bg-bg-tertiary border-r border-separator-light overflow-y-auto z-30 safe-top">
      {user && (
        <button
          onClick={() => pushDetail({ type: 'profile', uid: user.uid })}
          className="flex items-center gap-3 px-5 py-5 w-full hover:bg-primary-light transition-colors duration-200"
        >
          <Avatar
            avatar={user.avatarUrl}
            uid={user.uid}
            name={user.nickName}
            size={44}
          />
          <div className="text-left min-w-0">
            <div className="text-[15px] font-semibold truncate">{escHtml(user.nickName || '未登录')}</div>
            <div className="text-[12px] text-text-tertiary mt-0.5">查看个人资料</div>
          </div>
        </button>
      )}

      <div className="flex-1 px-2">
        {favorites.length > 0 && (
          <div className="py-2">
            <div className="px-3 py-2 text-[11px] font-semibold text-text-tertiary uppercase tracking-wider">
              收藏板块
            </div>
            {favorites.map((f) => (
              <div key={f.fid} className="relative group">
                <button
                  onClick={() => handleBoardClick(f.fid, f.name)}
                  className={cn(
                    'flex items-center gap-2.5 w-full px-3 py-2 text-[13px] text-text rounded-lg transition-all duration-150 pr-9',
                    isActive(f.fid)
                      ? 'bg-primary-light text-primary font-medium'
                      : 'hover:bg-bg-secondary',
                  )}
                >
                  <img
                    src={boardIcon(f.fid)}
                    alt=""
                    className="w-5 h-5 rounded-md object-cover shrink-0"
                    onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }}
                  />
                  <span className="truncate">{escHtml(f.name)}</span>
                </button>
                <button
                  onClick={(e) => handleToggleFav(f.fid, f.name, e)}
                  className="absolute right-2 top-1/2 -translate-y-1/2 p-1 rounded-md opacity-0 group-hover:opacity-100 transition-opacity duration-150 text-text-tertiary hover:text-primary hover:bg-bg-secondary"
                  title="取消收藏"
                >
                  <StarOff size={13} />
                </button>
              </div>
            ))}
          </div>
        )}

        {categories?.map((cat) => {
          const boards = collectBoards(cat)
          if (!boards.length) return null
          const catId = cat.id || cat.name
          const isCollapsed = collapsed.has(catId)
          return (
            <div key={catId} className="py-0.5">
              <button
                onClick={() => toggleCat(catId)}
                className="flex items-center w-full py-2 px-3 text-left rounded-lg hover:bg-bg-secondary transition-colors duration-150"
              >
                <ChevronRight
                  size={13}
                  className={cn('mr-1.5 text-text-tertiary transition-transform duration-200', !isCollapsed && 'rotate-90')}
                />
                <span className="text-[13px] font-semibold">{escHtml(cat.name)}</span>
                <span className="text-[11px] text-text-tertiary ml-auto bg-bg-secondary px-1.5 py-0.5 rounded-md">{boards.length}</span>
              </button>
              {!isCollapsed && (
                <div className="pb-1">
                  {boards.map((b) => (
                    <div key={b.fid} className="relative group">
                      <button
                        onClick={() => handleBoardClick(b.fid, b.name)}
                        className={cn(
                          'flex items-center gap-2 w-full pl-7 pr-8 py-[6px] text-[13px] text-text rounded-lg transition-all duration-150',
                          isActive(b.fid)
                            ? 'bg-primary-light text-primary font-medium'
                            : 'hover:bg-bg-secondary',
                        )}
                      >
                        <img
                          src={boardIcon(b.fid)}
                          alt=""
                          className="w-[18px] h-[18px] rounded object-cover shrink-0"
                          onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }}
                        />
                        <span className="truncate">{escHtml(b.name)}</span>
                      </button>
                      <button
                        onClick={(e) => handleToggleFav(b.fid, b.name, e)}
                        className={cn(
                          'absolute right-2 top-1/2 -translate-y-1/2 p-1 rounded-md opacity-0 group-hover:opacity-100 transition-opacity duration-150',
                          favFids.has(b.fid)
                            ? 'text-primary'
                            : 'text-text-tertiary hover:text-primary hover:bg-bg-secondary'
                        )}
                        title={favFids.has(b.fid) ? '取消收藏' : '收藏板块'}
                      >
                        <Star size={12} fill={favFids.has(b.fid) ? 'currentColor' : 'none'} />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )
        })}
      </div>

      <div className="p-3">
        <button
          onClick={toggleTheme}
          className="w-full py-2.5 rounded-xl bg-bg-secondary text-[13px] flex items-center justify-center gap-2 hover:bg-bg-secondary/80 transition-colors duration-200"
        >
          {theme === 'dark' ? <Sun size={15} /> : <Moon size={15} />}
          {theme === 'dark' ? '亮色模式' : '深色模式'}
        </button>
      </div>
    </aside>
  )
}

function MobileTabBar() {
  const { pushDetail } = useNav()
  const currentUser = useAuthStore((s) => s.currentUser)

  return (
    <nav className="fixed bottom-0 left-0 right-0 h-[calc(49px+env(safe-area-inset-bottom,0px))] safe-bottom bg-bg-tertiary/85 backdrop-blur-xl border-t border-separator flex lg:hidden z-50">
      <button
        className="flex-1 flex flex-col items-center justify-center gap-0.5 text-primary"
      >
        <Users size={22} strokeWidth={2.2} />
        <span className="text-[11px]">社区</span>
      </button>
      <button
        onClick={() => currentUser && pushDetail({ type: 'profile', uid: currentUser.uid })}
        className="flex-1 flex flex-col items-center justify-center gap-0.5 text-text-secondary"
      >
        <User size={22} strokeWidth={1.8} />
        <span className="text-[11px]">我的</span>
      </button>
    </nav>
  )
}

function MobileTabContent() {
  return <CommunityPage />
}

export default DesktopSidebar
export { MobileTabBar, MobileTabContent }
