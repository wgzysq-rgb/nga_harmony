import { useEffect, useLayoutEffect, useRef } from 'react'
import { useRouterStore, type DetailScreen, type DetailEntry } from '@/stores/router'
import { useAuthStore } from '@/stores/auth'
import { cn } from '@/lib/utils'
import ProfileCardPopup from '@/components/ProfileCardPopup'
import { Toast } from '@/components/Toast'
import BackFAB from '@/components/BackFAB'
import ReplyModal from '@/components/ReplyModal'
import LightboxLayer from '@/components/LightboxLayer'
import ThreadActionSheet from '@/components/ThreadActionSheet'
import ComposeSheet from '@/components/ComposeSheet'
import BlacklistAddDialog from '@/components/BlacklistAddDialog'
import LoginPage from '@/pages/LoginPage'
import DesktopSidebar, { MobileTabBar, MobileTabContent } from '@/components/layout/NavPane'
import BoardPane from '@/components/layout/BoardPane'
import DetailPane from '@/components/layout/DetailPane'
import { MessageSquare } from 'lucide-react'

const EMPTY_HINT = (
  <div className="flex flex-col items-center justify-center h-full text-text-tertiary">
    <MessageSquare size={56} strokeWidth={1.0} className="mb-4 opacity-20" />
    <p className="text-[15px]">从左侧选择一个板块</p>
    <p className="text-[12px] mt-1 opacity-60">浏览收藏或探索更多板块</p>
  </div>
)

export default function AppShell() {
  const initialized = useAuthStore((s) => s.initialized)
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const fetchUser = useAuthStore((s) => s.fetchUser)
  const layoutMode = useRouterStore((s) => s.layoutMode)
  const board = useRouterStore((s) => s.board)
  const detailStack = useRouterStore((s) => s.detailStack)
  const pushDetail = useRouterStore((s) => s.pushDetail)

  useEffect(() => {
    if (!initialized) fetchUser()
  }, [initialized, fetchUser])

  useEffect(() => {
    const mq2 = window.matchMedia('(min-width: 1024px)')
    const mq3 = window.matchMedia('(min-width: 1400px)')
    const update = () => {
      if (window.matchMedia('(min-width: 1400px)').matches) {
        useRouterStore.getState().setLayoutMode('threecol')
      } else if (window.matchMedia('(min-width: 1024px)').matches) {
        useRouterStore.getState().setLayoutMode('twocol')
      } else {
        useRouterStore.getState().setLayoutMode('mobile')
      }
    }
    mq2.addEventListener('change', update)
    mq3.addEventListener('change', update)
    return () => {
      mq2.removeEventListener('change', update)
      mq3.removeEventListener('change', update)
    }
  }, [])

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      const target = (e.target as HTMLElement).closest('a[href^="#/"]')
      if (!target) return
      e.preventDefault()
      const href = target.getAttribute('href')!
      try {
        const url = new URL(href.replace('#/', '/'), 'http://x')
        const path = url.pathname
        const params = url.searchParams
        if (path === '/thread') {
          const tid = params.get('tid')
          if (tid) {
            const screen: DetailScreen = {
              type: 'thread',
              tid,
              page: params.get('page') ? Number(params.get('page')) : undefined,
              pid: params.get('pid') ?? undefined,
            }
            const { detailStack } = useRouterStore.getState()
            if (detailStack.length > 0 && detailStack[detailStack.length - 1].screen.type === 'thread') {
              useRouterStore.getState().replaceDetail(screen)
            } else {
              pushDetail(screen)
            }
          }
        } else if (path === '/profile') {
          const uid = params.get('uid')
          if (uid) pushDetail({ type: 'profile', uid })
        }
      } catch {}
    }
    document.addEventListener('click', handler, true)
    return () => document.removeEventListener('click', handler, true)
  }, [pushDetail])

  if (!initialized) {
    return (
      <div className="flex items-center justify-center min-h-dvh bg-bg-secondary">
        <div className="w-7 h-7 border-[2.5px] border-text-tertiary/20 border-t-primary rounded-full animate-spin" />
      </div>
    )
  }

  if (!isAuthenticated) {
    return (
      <>
        <LoginPage />
        <BackFAB />
      </>
    )
  }

  const hasBoard = !!board
  const hasDetail = detailStack.length > 0
  const isMobile = layoutMode === 'mobile'
  const isTabPage = !hasDetail && !hasBoard

  const boardColVisible = layoutMode === 'threecol' || !hasDetail
  const detailColVisible = hasDetail

  const boardFlexStyle: React.CSSProperties = {
    flex: layoutMode === 'threecol' && hasDetail ? '0 0 40%' : '1 1 0%',
    ...(layoutMode === 'threecol' && { transition: 'flex 0.25s ease-in-out' }),
  }

  const globalOverlays = (
    <>
      <ProfileCardPopup />
      <Toast />
      <BackFAB />
      <ReplyModal />
      <LightboxLayer />
      <ThreadActionSheet />
      <ComposeSheet />
      <BlacklistAddDialog />
    </>
  )

  return (
    <>
      <div
        className={cn(
          'flex h-dvh overflow-hidden',
          layoutMode === 'threecol' ? 'w-full' : 'mx-auto max-w-[1200px] w-full',
        )}
      >
        <DesktopSidebar />

        <BoardColumn
          visible={boardColVisible}
          detailAlsoVisible={detailColVisible}
          isTabPage={isTabPage}
          isMobile={isMobile}
          flexStyle={boardFlexStyle}
        />

        <DetailColumn
          visible={detailColVisible}
          stack={detailStack}
        />
      </div>

      {isMobile && isTabPage && <MobileTabBar />}
      {globalOverlays}
    </>
  )
}

function BoardColumn({
  visible,
  detailAlsoVisible,
  isTabPage,
  isMobile,
  flexStyle,
}: {
  visible: boolean
  detailAlsoVisible: boolean
  isTabPage: boolean
  isMobile: boolean
  flexStyle: React.CSSProperties
}) {
  const board = useRouterStore((s) => s.board)
  const ref = useRef<HTMLDivElement>(null)
  const savedScroll = useRef(0)
  const wasVisible = useRef(true)

  useEffect(() => {
    const el = ref.current
    if (!el) return
    const handler = () => { savedScroll.current = el.scrollTop }
    el.addEventListener('scroll', handler, { passive: true })
    return () => el.removeEventListener('scroll', handler)
  }, [])

  useLayoutEffect(() => {
    if (wasVisible.current || !visible || savedScroll.current <= 0) {
      wasVisible.current = visible
      return
    }
    const scroll = savedScroll.current
    requestAnimationFrame(() => {
      if (ref.current) ref.current.scrollTop = scroll
    })
    wasVisible.current = visible
  }, [visible])

  return (
    <div
      ref={ref}
      className={cn(
        'overflow-y-auto bg-bg relative min-w-0',
        detailAlsoVisible && visible && 'border-r border-separator-light',
        !visible && 'hidden',
        isTabPage && isMobile && 'pb-[calc(49px+env(safe-area-inset-bottom,0px))]',
      )}
      data-scroll-container
      style={flexStyle}
    >
      {isTabPage && isMobile ? <MobileTabContent /> : board ? <BoardPane /> : EMPTY_HINT}
    </div>
  )
}

const MAX_DETAIL_DEPTH = 5

function DetailColumn({
  visible,
  stack,
}: {
  visible: boolean
  stack: DetailEntry[]
}) {
  const rendered = stack.slice(-MAX_DETAIL_DEPTH)

  return (
    <div className={cn('relative min-w-0 flex-1', !visible && 'hidden')}>
      {rendered.map((entry, i) => (
        <DetailLayer
          key={entry.id}
          entry={entry}
          isTop={i === rendered.length - 1}
        />
      ))}
    </div>
  )
}

function DetailLayer({ entry, isTop }: { entry: DetailEntry; isTop: boolean }) {
  const ref = useRef<HTMLDivElement>(null)
  const savedScroll = useRef(0)
  const wasTop = useRef(isTop)

  useEffect(() => {
    const el = ref.current
    if (!el) return
    const handler = () => { savedScroll.current = el.scrollTop }
    el.addEventListener('scroll', handler, { passive: true })
    return () => el.removeEventListener('scroll', handler)
  }, [])

  useLayoutEffect(() => {
    if (wasTop.current || !isTop || savedScroll.current <= 0) {
      wasTop.current = isTop
      return
    }
    const scroll = savedScroll.current
    requestAnimationFrame(() => {
      if (ref.current) ref.current.scrollTop = scroll
    })
    wasTop.current = isTop
  }, [isTop])

  return (
    <div
      ref={ref}
      className={cn(
        'absolute inset-0 overflow-y-auto overflow-x-hidden bg-bg',
        !isTop && 'hidden',
      )}
      data-scroll-container
    >
      <DetailPane entry={entry} />
    </div>
  )
}
