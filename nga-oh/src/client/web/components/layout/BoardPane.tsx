import { useRouterStore } from '@/stores/router'
import TopicListPage from '@/pages/TopicListPage'

export default function BoardPane() {
  const board = useRouterStore((s) => s.board)
  const detailStack = useRouterStore((s) => s.detailStack)
  if (!board) return null

  const topDetail = detailStack[detailStack.length - 1]
  const activeTid = topDetail?.screen.type === 'thread' ? topDetail.screen.tid : undefined

  return <TopicListPage fid={String(board.fid)} name={board.name} activeTid={activeTid} />
}
