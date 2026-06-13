import type { PostInfo } from '../../model/PostInfo'
import { PaginationManager } from './PaginationManager'

/**
 * 帖子详情（Thread）分页管理器。继承共性基类 PaginationManager，额外维护：
 * - posts / pageOfIndex / loadedLouSet：楼层去重 + 每条帖子所属页码索引
 * - 反向预取（prefetchedPrevPosts / prefetchedPrevPage）：向上滚动加载上一页
 *
 * @Observed 装饰器在本子类上，确保 ArkUI 能观测到本类实例的字段变化。
 */
@Observed
export class ThreadPaginationManager extends PaginationManager {
  /** 当前已加载的帖子列表（主帖 + 回复）。 */
  posts: PostInfo[] = []
  /** 与 posts 一一对应的页码索引，用于计算显示页码。 */
  pageOfIndex: number[] = []
  /** 已加载楼层的 lou 集合，用于追加时去重。 */
  loadedLouSet: Set<number> = new Set()
  /** 当前连续加载段的起始页（向上预取会前移）。 */
  loadedPageStart: number = 1

  /** 反向预取缓存的上一页帖子。 */
  prefetchedPrevPosts: PostInfo[] = []
  /** 反向预取对应的页码，0 表示无缓存。 */
  prefetchedPrevPage: number = 0

  reset(): void {
    this.posts = []
    this.pageOfIndex = []
    this.loadedLouSet.clear()
    this.loadedPageStart = 1
    this.currentPage = 1
    this.totalPages = 0
    this.hasMore = true
    this.clearPrefetchedPages()
    this.prefetchedPrevPosts = []
    this.prefetchedPrevPage = 0
    this.resetGeneration()
  }

  /**
   * 用新的一页帖子整体替换当前内容（跳页/首次加载场景）。
   * @param newPosts - 该页帖子
   * @param page - 页码
   * @param totalPages - 总页数
   */
  replaceWith(newPosts: PostInfo[], page: number, totalPages: number): void {
    this.loadedLouSet.clear()
    for (let i = 0; i < newPosts.length; i++) {
      this.loadedLouSet.add(newPosts[i].lou)
    }
    this.posts = newPosts
    this.pageOfIndex = newPosts.map(() => page)
    this.loadedPageStart = page
    this.applyState(page, totalPages)
  }

  /**
   * 向后追加一页帖子，按 lou 去重。
   * @param rawPosts - 待追加的帖子
   * @param page - 页码
   * @param totalPages - 总页数
   * @returns 实际新增（去重后）的帖子
   */
  appendPosts(rawPosts: PostInfo[], page: number, totalPages: number): PostInfo[] {
    const deduped: PostInfo[] = []
    for (let i = 0; i < rawPosts.length; i++) {
      if (!this.loadedLouSet.has(rawPosts[i].lou)) {
        deduped.push(rawPosts[i])
      }
      this.loadedLouSet.add(rawPosts[i].lou)
    }
    if (deduped.length === 0) {
      this.applyState(page, totalPages)
      return []
    }
    const combined: PostInfo[] = []
    for (let i = 0; i < this.posts.length; i++) {
      combined.push(this.posts[i])
    }
    for (let i = 0; i < deduped.length; i++) {
      combined.push(deduped[i])
    }
    this.posts = combined

    const newPageOfIndex: number[] = []
    for (let i = 0; i < this.pageOfIndex.length; i++) {
      newPageOfIndex.push(this.pageOfIndex[i])
    }
    for (let i = 0; i < deduped.length; i++) {
      newPageOfIndex.push(page)
    }
    this.pageOfIndex = newPageOfIndex

    this.applyState(page, totalPages)
    return deduped
  }

  /**
   * 向前插入上一页帖子（反向预取），按 lou 去重。
   * @param rawPosts - 待前置的帖子
   * @param page - 该批对应的页码
   * @returns 实际新增（去重后）的帖子
   */
  prependPosts(rawPosts: PostInfo[], page: number): PostInfo[] {
    const deduped: PostInfo[] = []
    for (let i = 0; i < rawPosts.length; i++) {
      if (!this.loadedLouSet.has(rawPosts[i].lou)) {
        deduped.push(rawPosts[i])
      }
      this.loadedLouSet.add(rawPosts[i].lou)
    }
    if (deduped.length === 0) {
      this.loadedPageStart = page
      return []
    }
    const combined: PostInfo[] = []
    for (let i = 0; i < deduped.length; i++) {
      combined.push(deduped[i])
    }
    for (let i = 0; i < this.posts.length; i++) {
      combined.push(this.posts[i])
    }
    this.posts = combined

    const newPageOfIndex: number[] = []
    for (let i = 0; i < deduped.length; i++) {
      newPageOfIndex.push(page)
    }
    for (let i = 0; i < this.pageOfIndex.length; i++) {
      newPageOfIndex.push(this.pageOfIndex[i])
    }
    this.pageOfIndex = newPageOfIndex

    this.loadedPageStart = page
    return deduped
  }

  /**
   * 缓存一页预取帖子。将 PostInfo[] 暂存进基类预取 Map。
   * @param page - 页码
   * @param posts - 该页帖子
   * @param totalPages - 总页数
   */
  setPrefetchedPage(page: number, posts: PostInfo[], totalPages: number): void {
    const items: object[] = []
    for (let i = 0; i < posts.length; i++) {
      items.push(posts[i])
    }
    this.setPrefetchedRaw(page, items, totalPages)
  }

  /**
   * 提交某页预取缓存，合并进 posts（按 lou 去重）。
   * @param page - 页码
   * @returns 实际新增的帖子（空数组表示无缓存或全部去重）
   */
  commitPrefetchedPage(page: number): PostInfo[] {
    const holder = this.getPrefetchedRaw(page)
    if (holder === undefined) return []
    const posts: PostInfo[] = []
    for (let i = 0; i < holder.items.length; i++) {
      posts.push(holder.items[i] as PostInfo)
    }
    if (posts.length === 0) {
      this.deletePrefetched(page)
      return []
    }
    const added: PostInfo[] = this.appendPosts(posts, page, holder.totalPages)
    this.deletePrefetched(page)
    return added
  }

  /**
   * 反向预取是否就绪。
   * @returns 是否有可提交的上一页缓存
   */
  isPrefetchedPrevReady(): boolean {
    return this.prefetchedPrevPosts.length > 0 && this.prefetchedPrevPage > 0
  }

  /**
   * 提交反向预取缓存，前置合并进 posts。
   * @returns 实际新增的帖子
   */
  commitPrefetchedPrev(): PostInfo[] {
    if (!this.isPrefetchedPrevReady()) return []
    const added: PostInfo[] = this.prependPosts(
      this.prefetchedPrevPosts,
      this.prefetchedPrevPage
    )
    this.prefetchedPrevPosts = []
    this.prefetchedPrevPage = 0
    return added
  }

  /**
   * 根据列表中心索引计算当前应显示的页码。
   * @param centerIndex - 中心条目索引
   * @returns 对应页码
   */
  getDisplayPage(centerIndex: number): number {
    if (centerIndex >= 0 && centerIndex < this.pageOfIndex.length) {
      return this.pageOfIndex[centerIndex]
    }
    return this.currentPage
  }

  /**
   * 按 pid 查找帖子索引。
   * @param pid - 帖子 pid
   * @returns 索引，未找到返回 -1
   */
  findPostIndex(pid: number): number {
    for (let i = 0; i < this.posts.length; i++) {
      if (this.posts[i].pid === pid) {
        return i
      }
    }
    return -1
  }

  /**
   * 给指定 pid 的帖子累加投票分数（用于投票后即时更新 UI）。
   * @param pid - 帖子 pid
   * @param scoreDelta - score 增量
   * @param score2Delta - score_2 增量
   * @returns 被更新帖子的索引，未找到返回 -1
   */
  updateVoteScore(pid: number, scoreDelta: number, score2Delta: number): number {
    for (let i = 0; i < this.posts.length; i++) {
      if (this.posts[i].pid === pid) {
        this.posts[i].score += scoreDelta
        this.posts[i].score_2 += score2Delta
        return i
      }
    }
    return -1
  }
}
