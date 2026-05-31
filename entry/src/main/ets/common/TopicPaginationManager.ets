class TopicPrefetchData {
  threads: object[] = []
  totalPages: number = 0
}

@Observed
export class TopicPaginationManager {
  threads: object[] = []
  currentPage: number = 1
  totalPages: number = 0
  hasMore: boolean = true

  prefetchInProgress: boolean = false
  private prefetchedPages: Map<number, TopicPrefetchData> = new Map()

  private generation: number = 0

  nextGeneration(): number {
    this.generation++
    return this.generation
  }

  getGeneration(): number {
    return this.generation
  }

  reset(): void {
    this.threads = []
    this.currentPage = 1
    this.totalPages = 0
    this.hasMore = true
    this.prefetchedPages.clear()
    this.generation = 0
  }

  replaceWith(list: object[], page: number, totalPages: number): void {
    this.threads = list
    this.currentPage = page
    this.totalPages = totalPages
    this.hasMore = page < totalPages
  }

  appendWith(list: object[], page: number, totalPages: number): object[] {
    const existingTids: Set<number> = new Set()
    for (let i: number = 0; i < this.threads.length; i++) {
      const t: number = Number((this.threads[i] as Record<string, Object>)['tid'] ?? 0)
      if (t) existingTids.add(t)
    }
    const deduped: object[] = []
    for (let i: number = 0; i < list.length; i++) {
      const t: number = Number((list[i] as Record<string, Object>)['tid'] ?? 0)
      if (!existingTids.has(t)) {
        deduped.push(list[i])
        existingTids.add(t)
      }
    }
    if (deduped.length > 0) {
      const arr: object[] = []
      for (let i: number = 0; i < this.threads.length; i++) arr.push(this.threads[i])
      for (let i: number = 0; i < deduped.length; i++) arr.push(deduped[i])
      this.threads = arr
    }
    this.currentPage = page
    this.totalPages = totalPages
    this.hasMore = page < totalPages
    return deduped
  }

  hasPrefetchedPage(page: number): boolean {
    return this.prefetchedPages.has(page)
  }

  setPrefetchedPage(page: number, threads: object[], totalPages: number): void {
    const data: TopicPrefetchData = new TopicPrefetchData()
    for (let i = 0; i < threads.length; i++) {
      data.threads.push(threads[i])
    }
    data.totalPages = totalPages
    this.prefetchedPages.set(page, data)
  }

  commitPrefetchedPage(page: number): object[] {
    const data: TopicPrefetchData | undefined = this.prefetchedPages.get(page)
    if (data === undefined || data.threads.length === 0) return []
    const added: object[] = this.appendWith(data.threads, page, data.totalPages)
    this.prefetchedPages.delete(page)
    return added
  }

  clearPrefetchedPages(): void {
    this.prefetchedPages.clear()
  }
}
