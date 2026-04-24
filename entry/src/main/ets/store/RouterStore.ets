/**
 * 路由状态管理 - 复刻 React router.ts
 * 三列适配模式: boardSlot(中间列) + activityStack(右侧列)
 * 使用 AppStorage 驱动 UI 响应式更新
 */

// ============== 类型定义 ==============

export type LayoutMode = 'sm' | 'md' | 'lg'
export type SidebarTab = 'community' | 'me'

export class BoardSlot {
  fid: number = 0
  name: string = ''
  stid: string = ''

  constructor(fid: number, name: string, stid: string = '') {
    this.fid = fid
    this.name = name
    this.stid = stid
  }
}

export type ScreenType =
  | 'thread'
  | 'profile'
  | 'notifications'
  | 'messages'
  | 'messageDetail'
  | 'search'
  | 'blacklist'

export class Screen {
  type: ScreenType = 'thread'
  // thread
  tid: string = ''
  threadPage: number = 1
  pid: string = ''
  // profile
  uid: string = ''
  // messageDetail
  mid: string = ''
  messagePage: number = 1

  static thread(tid: string, page: number = 1, pid: string = ''): Screen {
    const s = new Screen()
    s.type = 'thread'
    s.tid = tid
    s.threadPage = page
    s.pid = pid
    return s
  }

  static profile(uid: string): Screen {
    const s = new Screen()
    s.type = 'profile'
    s.uid = uid
    return s
  }

  static messageDetail(mid: string, page: number = 1): Screen {
    const s = new Screen()
    s.type = 'messageDetail'
    s.mid = mid
    s.messagePage = page
    return s
  }

  static search(): Screen {
    const s = new Screen()
    s.type = 'search'
    return s
  }

  static notifications(): Screen {
    const s = new Screen()
    s.type = 'notifications'
    return s
  }

  static messages(): Screen {
    const s = new Screen()
    s.type = 'messages'
    return s
  }

  static blacklist(): Screen {
    const s = new Screen()
    s.type = 'blacklist'
    return s
  }

  getTitle(): string {
    switch (this.type) {
      case 'thread': return '帖子'
      case 'profile': return '个人主页'
      case 'notifications': return '通知'
      case 'messages': return '私信'
      case 'messageDetail': return '私信'
      case 'search': return '搜索'
      case 'blacklist': return '黑名单管理'
      default: return ''
    }
  }
}

export class NavEntry {
  id: number = 0
  screen: Screen = new Screen()

  constructor(id: number, screen: Screen) {
    this.id = id
    this.screen = screen
  }
}

// ============== 路由 Store 单例 ==============

let nextNavId = 0

class RouterStoreClass {
  // 当前侧边栏 tab
  private _sidebarTab: SidebarTab = 'community'
  get sidebarTab(): SidebarTab { return this._sidebarTab }

  // 中间列: 选中的板块
  private _boardSlot: BoardSlot | null = null
  get boardSlot(): BoardSlot | null { return this._boardSlot }

  // 右侧列: 活动栈
  private _activityStack: NavEntry[] = []
  get activityStack(): NavEntry[] { return this._activityStack }
  get topActivity(): NavEntry | null {
    return this._activityStack.length > 0 ? this._activityStack[this._activityStack.length - 1] : null
  }

  // 版本号，用于触发 AppStorage 刷新
  private _version: number = 0
  get version(): number { return this._version }

  private bump(): void {
    this._version++
    AppStorage.setOrCreate('routerVersion', this._version)
  }

  // ============== Navigation ==============

  setSidebarTab(tab: SidebarTab): void {
    if (this._sidebarTab === tab) return
    this._sidebarTab = tab
    this.bump()
  }

  setBoardSlot(board: BoardSlot | null): void {
    this._boardSlot = board
    this.bump()
  }

  /**
   * 导航到板块 (填充中间列)
   */
  navigateForum(fid: number, name: string, stid: string = ''): void {
    this._boardSlot = new BoardSlot(fid, name, stid)
    // 清空活动栈
    this._activityStack = []
    this.bump()
  }

  /**
   * 导航到收藏主题 (填充中间列)
   */
  navigateFavorites(): void {
    this._boardSlot = new BoardSlot(-9999, '我的收藏')
    this._activityStack = []
    this.bump()
  }

  /**
   * 导航到活动页面 (填充右侧列)
   */
  navigateActivity(screen: Screen, replace: boolean = false): void {
    const stack = [...this._activityStack]
    const entry = new NavEntry(++nextNavId, screen)

    if (replace && stack.length > 0) {
      stack[stack.length - 1] = entry
    } else if (screen.type === 'thread') {
      // thread: 如果栈顶也是 thread, 替换
      const top = stack.length > 0 ? stack[stack.length - 1] : null
      if (top && top.screen.type === 'thread') {
        stack[stack.length - 1] = entry
      } else {
        stack.push(entry)
      }
    } else {
      stack.push(entry)
    }
    this._activityStack = stack
    this.bump()
  }

  /**
   * 返回: 弹出活动栈 或 清空板块
   */
  back(): void {
    if (this._activityStack.length > 0) {
      this._activityStack = this._activityStack.slice(0, -1)
      this.bump()
      return
    }
    if (this._boardSlot) {
      this._boardSlot = null
      this.bump()
    }
  }

  /**
   * 重置到初始状态
   */
  reset(tab: SidebarTab = 'community'): void {
    this._sidebarTab = tab
    this._boardSlot = null
    this._activityStack = []
    this.bump()
  }
}

export const routerStore = new RouterStoreClass()
