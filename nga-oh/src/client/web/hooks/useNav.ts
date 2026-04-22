import { useRouterStore } from '@/stores/router'

export function useNav() {
  const openBoard = useRouterStore((s) => s.openBoard)
  const pushDetail = useRouterStore((s) => s.pushDetail)
  const goBack = useRouterStore((s) => s.goBack)
  const resetAll = useRouterStore((s) => s.resetAll)
  const removeByCategory = useRouterStore((s) => s.removeByCategory)

  return { openBoard, pushDetail, goBack, resetAll, removeByCategory }
}
