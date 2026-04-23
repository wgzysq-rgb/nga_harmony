/**
 * 主页面 - 完整三列适配布局
 * 复刻 React RouterProvider.tsx 的三列模式
 *
 * sm (一列): 底部 Tabs, 全屏页面堆叠 (与 React mobile 模式一致)
 * md (两列): 左侧 SidebarContent + 右侧 TopicList 或 Activity (与 React twocol 一致)
 * lg (三列): 左侧 SidebarContent + 中间 TopicList + 右侧 Activity (与 React threecol 一致)
 *
 * 核心差异:
 * - React 用 CSS flex + media query; 鸿蒙用 SideBarContainer + Row 布局
 * - React 用 Zustand router store; 鸿蒙用 routerStore 单例 + AppStorage 驱动刷新
 * - React 用 AnimatePresence; 鸿蒙直接条件渲染
 */

import { appStore } from '../store/AppStore'
import { routerStore, type BoardSlot, type NavEntry, Screen } from '../store/RouterStore'
import { getCurrentUser, getForumCategories } from '../service/NgaApi'
import { AppColors } from '../common/Constants'
import { TopicListPanel } from './TopicListPanel'
import { ThreadPanel } from './ThreadPanel'
import { ProfilePanel } from './ProfilePanel'
import { Avatar } from '../common/Avatar'
import router from '@ohos.router'

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0
  @State authInitialized: boolean = false
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @StorageProp('routerVersion') @Watch('onRouterVersionChange') routerVersion: number = 0
  // @State 中转: routerStore 是外部单例, ArkUI 无法追踪其属性变化
  // 通过 @Watch 监听 routerVersion 变化, 同步到 @State 变量驱动条件渲染
  @State boardSlot: BoardSlot | null = null
  @State topActivity: NavEntry | null = null

  aboutToAppear(): void {
    this.syncRouterState()
    this.checkAuth()
  }

  /**
   * 拦截系统返回键 (完美还原 React 三列模式返回行为)
   * - sm 模式: 使用页面栈 (router.pushUrl), 由系统路由处理
   * - md/lg 模式: 面板导航由 RouterStore 管理, 返回键弹出活动栈;
   *   boardSlot 在桌面模式下持久保留 (与 React 一致: 用户从侧边栏切换板块)
   */
  onBackPress(): boolean {
    if (this.currentBreakpoint === 'sm') {
      return false // sm 模式使用 router 页面栈, 交给系统处理
    }
    // md/lg 模式: 所有导航由 RouterStore 面板管理
    if (routerStore.activityStack.length > 0) {
      routerStore.back() // 弹出活动 (如帖子详情), 返回帖子列表
      return true
    }
    // 桌面模式下 boardSlot 持久保留, 与 React BackFAB 行为一致:
    // React 桌面模式中 boardSlot 不会被 back() 清除, 用户通过侧边栏切换板块
    if (routerStore.boardSlot) {
      return true // 消费事件防止退出, 但不改变 boardSlot 状态
    }
    // 无任何面板内容, 允许退出应用
    return false
  }

  private onRouterVersionChange(): void {
    this.syncRouterState()
  }

  private syncRouterState(): void {
    this.boardSlot = routerStore.boardSlot
    this.topActivity = routerStore.topActivity
  }

  private async checkAuth(): Promise<void> {
    if (!appStore.auth.isAuthenticated) {
      router.replaceUrl({ url: 'pages/LoginPage' })
      return
    }

    try {
      await getCurrentUser(appStore.auth.token)
    } catch (e) {
      // 使用缓存信息继续
    }
    appStore.fetchFavorites()
    this.authInitialized = true
  }

  build() {
    if (this.currentBreakpoint === 'sm') {
      this.SmLayout()
    } else if (this.currentBreakpoint === 'md') {
      this.MdLayout()
    } else {
      this.LgLayout()
    }
  }

  // ============== 一列模式 (sm) ==============
  // 复刻 React mobile: 底部 Tabs + 页面堆叠

  // 复刻 React MobileTabBar: "社区" 始终高亮, "我的" 导航到 ProfilePage
  @Builder
  SmLayout() {
    Tabs({ index: this.currentIndex }) {
      TabContent() {
        CommunityTabContent({ currentBreakpoint: 'sm' })
      }
      .tabBar(this.TabBuilder(0, '社区'))

      TabContent() {
        // 占位: 点击"我的"时通过 onChange 导航到 ProfilePage
        Column()
      }
      .tabBar(this.TabBuilder(1, '我的'))
    }
    .width('100%')
    .height('100%')
    .barPosition(BarPosition.End)
    .barHeight(49)
    .onChange((index: number) => {
      if (index === 1 && appStore.auth.uid) {
        // 复刻 React: pushDetail({ type: 'profile', uid })
        router.pushUrl({
          url: 'pages/ProfilePage',
          params: { uid: appStore.auth.uid }
        })
        this.currentIndex = 0 // 切回社区 Tab
      }
    })
  }

  // ============== 两列模式 (md) ==============
  // 复刻 React twocol: 侧边栏 + 单列内容区
  // 有 activity 时显示 activity, 否则显示 board, 否则显示空提示

  @Builder
  MdLayout() {
    Row() {
      // 左侧侧边栏
      this.SidebarContent()

      // 右侧内容区: 二选一显示 (activity > board > 空提示)
      Column() {
        if (this.topActivity) {
          this.ActivityPanel()
        } else if (this.boardSlot) {
          this.BoardPanel()
        } else {
          this.EmptyHint()
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  // ============== 三列模式 (lg) ==============
  //   hasBoard + hasActivity → 三列: 侧边栏 | TopicList(40%剩余) | Activity(60%剩余)
  //   hasBoard + noActivity  → 两列: 侧边栏 | TopicList(全部剩余)
  //   noBoard + hasActivity  → 两列: 侧边栏 | Activity(全部剩余)
  //   noBoard + noActivity   → 两列: 侧边栏 | 空提示

  @Builder
  LgLayout() {
    Row() {
      this.SidebarContent()

      Row() {
        if (this.boardSlot || !this.topActivity) {
          Column() {
            if (this.boardSlot) {
              this.BoardPanel()
            } else {
              this.EmptyHint()
            }
          }
          .layoutWeight(this.topActivity ? 4 : 1)
          .height('100%')
        }

        if (this.topActivity) {
          Column() {
            this.ActivityPanel()
          }
          .layoutWeight(6)
          .height('100%')
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  // ============== 内容面板 ==============

  @Builder
  BoardPanel() {
    TopicListPanel({
      boardFid: this.boardSlot!.fid,
      boardName: this.boardSlot!.name,
      boardStid: this.boardSlot!.stid,
      isFavorites: this.boardSlot!.fid === -9999
    })
  }

  @Builder
  ActivityPanel() {
    if (this.topActivity!.screen.type === 'thread') {
      ThreadPanel({ threadTid: this.topActivity!.screen.tid })
    } else if (this.topActivity!.screen.type === 'profile') {
      Column() {
        Row() {
          Text('←').fontSize(22).fontColor(AppColors.primary)
            .onClick(() => routerStore.back()).padding({ left: 8, right: 8 })
          Text(this.topActivity!.screen.getTitle()).fontSize(17).fontWeight(FontWeight.Bold).layoutWeight(1)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%').height(44).backgroundColor(AppColors.bgTertiary)
        .border({ width: { bottom: 0.5 }, color: AppColors.separator }).alignItems(VerticalAlign.Center)

        Column() {
          ProfilePanel({ uid: this.topActivity!.screen.uid })
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%').height('100%')
    } else {
      Column() {
        Row() {
          Text('←').fontSize(22).fontColor(AppColors.primary)
            .onClick(() => routerStore.back()).padding({ left: 8, right: 8 })
          Text(this.topActivity!.screen.getTitle()).fontSize(17).fontWeight(FontWeight.Bold).layoutWeight(1)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%').height(44).backgroundColor(AppColors.bgTertiary)
        .border({ width: { bottom: 0.5 }, color: AppColors.separator }).alignItems(VerticalAlign.Center)

        Column() {
          Text('📋').fontSize(40).opacity(0.4).margin({ bottom: 8 })
          Text('此页面将在全屏打开').fontSize(14).fontColor(AppColors.textTertiary).margin({ bottom: 16 })

          Button('打开页面')
            .fontSize(14).fontColor(Color.White).backgroundColor(AppColors.primary).borderRadius(10)
            .onClick(() => {
              this.openActivityAsPage(this.topActivity!.screen)
            })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      }
      .width('100%').height('100%').backgroundColor(AppColors.bg)
    }
  }

  private openActivityAsPage(screen: Screen): void {
    switch (screen.type) {
      case 'profile':
        router.pushUrl({ url: 'pages/ProfilePage', params: { uid: screen.uid } })
        break
      case 'notifications':
        router.pushUrl({ url: 'pages/NotificationPage' })
        break
      case 'messages':
        router.pushUrl({ url: 'pages/MessageListPage' })
        break
      case 'messageDetail':
        router.pushUrl({ url: 'pages/MessageDetailPage', params: { mid: screen.mid } })
        break
      case 'search':
        router.pushUrl({ url: 'pages/SearchPage' })
        break
      case 'blacklist':
        router.pushUrl({ url: 'pages/BlacklistPage' })
        break
      default:
        break
    }
  }

  @Builder
  EmptyHint() {
    Column() {
      Text('💬').fontSize(48).opacity(0.3).margin({ bottom: 12 })
      Text('从左侧选择一个板块').fontSize(15).fontColor(AppColors.textTertiary)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(AppColors.bg)
  }

  // ============== 侧边栏内容 ==============
  // 复刻 React DesktopSidebar: 用户卡片 + 自定义Tab下划线 + 社区列表/我的设置

  // 复刻 React DesktopSidebar: 纯板块列表, 无 Tab 切换器
  @Builder
  SidebarContent() {
    Column() {
      // 用户卡片 (复刻 React: Avatar + nickName + "查看个人资料")
      Column() {
        Avatar({
          avatar: appStore.auth.avatarUrl,
          uid: appStore.auth.uid,
          name: appStore.auth.nickName,
          avatarSize: 36
        })
        Text(appStore.auth.nickName || '未登录')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({ top: 14, bottom: 14 })
      .alignItems(HorizontalAlign.Center)
      .border({ width: { bottom: 0.5 }, color: AppColors.separator })
      .onClick(() => {
        if (appStore.auth.uid) {
          routerStore.navigateActivity(Screen.profile(appStore.auth.uid))
        }
      })

      // 板块列表 (始终显示, 复刻 React DesktopSidebar)
      Column() {
        CommunityTabContent({ currentBreakpoint: this.currentBreakpoint })
      }
      .layoutWeight(1)

      // 深色模式切换 (始终显示, 固定底部, 复刻 React DesktopSidebar 底部按钮)
      Row() {
        Text(appStore.settings.theme === 'dark' ? '☀️' : '🌙')
          .fontSize(15)
          .margin({ right: 8 })
        Text(appStore.settings.theme === 'dark' ? '亮色模式' : '深色模式')
          .fontSize(13)
          .fontColor(AppColors.textSecondary)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .height(44)
      .backgroundColor(AppColors.bgSecondary)
      .borderRadius(12)
      .margin({ left: 6, right: 6, top: 8, bottom: 12 })
      .onClick(() => {
        appStore.toggleTheme()
      })
    }
    .width(180)
    .height('100%')
    .backgroundColor(AppColors.bgTertiary)
    .border({ width: { right: 0.5 }, color: AppColors.separator })
  }

  @Builder
  TabBuilder(index: number, title: string) {
    Column() {
      Text(index === 0 ? '👥' : '👤')
        .fontSize(22)

      Text(title)
        .fontSize(11)
        .fontColor(this.currentIndex === index ? '#007AFF' : '#8E8E93')
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

// ============== 社区 Tab 内容 ==============
// 侧边栏 (md/lg): 列表模式 + 可折叠分类 (复刻 React DesktopSidebar)
// 移动端 (sm): 网格模式 (复刻 React CommunityPage)

@Component
struct CommunityTabContent {
  @State isLoading: boolean = true
  @State collapsedCatIds: string[] = []
  @State favoritesVersion: number = 0
  @Prop currentBreakpoint: string = 'sm'
  @StorageProp('routerVersion') routerVersion: number = 0
  @StorageProp('favVersion') @Watch('onFavVersionChange') favVersion: number = 0
  categories: import('../model/Forum').Category[] = []

  aboutToAppear(): void {
    this.loadCategories()
  }

  private onFavVersionChange(): void {
    this.favoritesVersion = this.favVersion
  }

  private get favorites(): import('../store/AppStore').FavBoard[] {
    return appStore.settings.favorites ?? []
  }

  private get favCount(): number {
    return this.favorites.length
  }

  private async loadCategories(): Promise<void> {
    try {
      const result = await getForumCategories(appStore.auth.token)
      if (result.ok) {
        this.categories = result.data
      }
    } catch (e) {
      // ignore
    }
    this.isLoading = false
  }

  build() {
    Scroll() {
      Column() {
        if (this.currentBreakpoint === 'sm') {
          this.MobileContent()
        } else {
          this.SidebarListContent()
        }
      }
      .width('100%')
      .padding({ bottom: 8 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  // ============== 侧边栏列表模式 (md/lg) ==============
  // 复刻 React DesktopSidebar: 板块以列表形式展示, 分类可折叠, 高亮当前选中

  private isFavBoard(fid: number): boolean {
    const favs: import('../store/AppStore').FavBoard[] = this.favorites
    if (favs === null || favs === undefined) {
      return false
    }
    for (const f of favs) {
      if (f.fid === fid) return true
    }
    return false
  }

  private handleToggleFav(fid: number, name: string): void {
    if (this.isFavBoard(fid)) {
      appStore.removeFavorite(fid)
    } else {
      appStore.addFavorite({ fid: fid, stid: fid, name: name })
    }
  }

  @Builder
  SidebarListContent() {
    if (this.favCount > 0) {
      Column() {
        Text('收藏板块')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.textSecondary)
          .width('100%')
          .padding({ left: 8, top: 8, bottom: 4 })

        ForEach(this.favorites, (fav: import('../store/AppStore').FavBoard) => {
          Row() {
            Image(`https://img4.nga.178.com/ngabbs/nga_classic/f/app/${fav.fid}.png`)
              .width(20).height(20).borderRadius(5).objectFit(ImageFit.Cover)
              .onError(() => {})
            Text(fav.name)
              .fontSize(12).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 6 }).layoutWeight(1)
            Text('★')
              .fontSize(14)
              .fontColor(AppColors.primary)
              .margin({ left: 4 })
              .onClick(() => {
                this.handleToggleFav(fav.fid, fav.name)
              })
          }
          .width('100%').height(32)
          .padding({ left: 8, right: 8 })
          .alignItems(VerticalAlign.Center)
          .borderRadius(8)
          .backgroundColor(this.isActiveBoard(fav.fid) ? AppColors.bgSecondary : Color.Transparent)
          .onClick(() => {
            routerStore.navigateForum(fav.fid, fav.name, String(fav.stid))
          })
        })
      }
      .width('100%')
    }

    // 版块分类 (可折叠列表)
    if (this.isLoading) {
      Column() {
        LoadingProgress().width(24).height(24).color(AppColors.textTertiary)
      }
      .width('100%').height(60)
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    } else {
      ForEach(this.categories, (cat: import('../model/Forum').Category) => {
        this.SidebarCategorySection(cat)
      })
    }
  }

  @Builder
  SidebarCategorySection(cat: import('../model/Forum').Category) {
    Column() {
      // 分类标题 (可折叠, 复刻 React: ChevronRight + name + count)
      Row() {
        Text('›')
          .fontSize(14)
          .fontColor(AppColors.textTertiary)
          .margin({ right: 6 })
          .rotate({ angle: this.isCatCollapsed(cat) ? 0 : 90 })
        Text(cat.name)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
        Text(this.collectBoardCount(cat).toString())
          .fontSize(11)
          .fontColor(AppColors.textTertiary)
          .margin({ left: 6 })
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.toggleCat(cat.name)
      })

      if (!this.isCatCollapsed(cat)) {
        ForEach(this.collectBoards(cat), (board: import('../model/Forum').BoardContent) => {
          Row() {
            Image(`https://img4.nga.178.com/ngabbs/nga_classic/f/app/${board.fid}.png`)
              .width(18).height(18).borderRadius(4).objectFit(ImageFit.Cover)
              .onError(() => {})
            Text(board.name)
              .fontSize(12).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 6 }).layoutWeight(1)
            Text(this.isFavBoard(board.fid) ? '★' : '☆')
              .fontSize(12)
              .fontColor(this.isFavBoard(board.fid) ? AppColors.primary : AppColors.textTertiary)
              .margin({ left: 4 })
              .onClick(() => {
                this.handleToggleFav(board.fid, board.name)
              })
          }
          .width('100%').height(30)
          .padding({ left: 22, right: 8 })
          .alignItems(VerticalAlign.Center)
          .borderRadius(8)
          .backgroundColor(this.isActiveBoard(board.fid) ? AppColors.bgSecondary : Color.Transparent)
          .onClick(() => {
            routerStore.navigateForum(board.fid, board.name)
          })
        })
      }
    }
    .width('100%')
    .border({ width: { top: 0.5 }, color: AppColors.separator })
  }

  // ============== 移动端网格模式 (sm) ==============
  // 复刻 React CommunityPage: 搜索栏 + 网格板块

  @Builder
  MobileContent() {
    // 搜索栏
    Row() {
      Text('🔍')
        .fontSize(16)
        .margin({ right: 8 })
      Text('搜索板块、主题...')
        .fontSize(15)
        .fontColor(AppColors.textTertiary)
    }
    .width('92%')
    .height(40)
    .padding({ left: 12, right: 12 })
    .backgroundColor(AppColors.bgSecondary)
    .borderRadius(10)
    .margin({ top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: 'pages/SearchPage' })
    })

    // 收藏板块 (网格)
    if (this.favCount > 0) {
      this.FavoritesGrid()
    }

    // 版块分类 (网格)
    if (this.isLoading) {
      Column() {
        LoadingProgress().width(24).height(24).color(AppColors.textTertiary)
        Text('加载中...')
          .fontSize(14)
          .fontColor(AppColors.textTertiary)
          .margin({ top: 12 })
      }
      .width('100%')
      .height(200)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      List() {
        ForEach(this.categories, (cat: import('../model/Forum').Category) => {
          ListItem() {
            this.CategoryGrid(cat)
          }
        })
      }
      .width('100%')
      .divider({ strokeWidth: 8, color: Color.Transparent })
    }
  }

  @Builder
  FavoritesGrid() {
    Column() {
      Row() {
        Text('我的收藏')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
        Text(`${this.favCount} 个板块`)
          .fontSize(11)
          .fontColor(AppColors.textTertiary)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 6 })
      .justifyContent(FlexAlign.SpaceBetween)

      GridRow({ columns: { sm: 4, md: 4, lg: 3 }, gutter: 8 }) {
        ForEach(this.favorites, (fav: import('../store/AppStore').FavBoard) => {
          GridCol() {
            Column() {
              Stack() {
                Image(`https://img4.nga.178.com/ngabbs/nga_classic/f/app/${fav.fid}.png`)
                  .width(44)
                  .height(44)
                  .borderRadius(12)
                  .objectFit(ImageFit.Cover)
                  .onError(() => {})
              }
              .width(44)
              .height(44)
              .borderRadius(12)
              .backgroundColor(AppColors.bgSecondary)

              Text(fav.name)
                .fontSize(11)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 56 })
            }
            .padding({ top: 8, bottom: 8 })
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/TopicListPage',
                params: { fid: String(fav.fid), stid: String(fav.stid), name: fav.name }
              })
            })
          }
        })
      }
      .width('100%')
      .padding({ left: 8, right: 8, bottom: 14 })
    }
    .width('92%')
    .backgroundColor(AppColors.bgTertiary)
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder
  CategoryGrid(cat: import('../model/Forum').Category) {
    Column() {
      Row() {
        Text(cat.name)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)

        Text(this.collectBoardCount(cat).toString())
          .fontSize(11)
          .fontColor(AppColors.textTertiary)
          .margin({ left: 6 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      GridRow({ columns: { sm: 4, md: 4, lg: 3 }, gutter: 8 }) {
        ForEach(this.collectBoards(cat), (board: import('../model/Forum').BoardContent) => {
          GridCol() {
            Column() {
              Stack() {
                Image(`https://img4.nga.178.com/ngabbs/nga_classic/f/app/${board.fid}.png`)
                  .width(40)
                  .height(40)
                  .borderRadius(10)
                  .objectFit(ImageFit.Cover)
                  .onError(() => {})
              }
              .width(40)
              .height(40)
              .borderRadius(10)
              .backgroundColor(AppColors.bgSecondary)

              Text(board.name)
                .fontSize(11)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 52 })
                .fontColor(AppColors.textPrimary)
            }
            .padding({ top: 10, bottom: 10 })
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/TopicListPage',
                params: { fid: String(board.fid), name: board.name }
              })
            })
          }
        })
      }
      .width('100%')
      .padding({ left: 6, right: 6 })
      .backgroundColor(AppColors.bgTertiary)
      .borderRadius(12)
    }
    .width('92%')
  }

  // ============== 工具方法 ==============

  private isActiveBoard(fid: number): boolean {
    return routerStore.boardSlot !== null && routerStore.boardSlot.fid === fid
  }

  private isCatCollapsed(cat: import('../model/Forum').Category): boolean {
    return this.collapsedCatIds.indexOf(cat.name) >= 0
  }

  private toggleCat(catId: string): void {
    const idx = this.collapsedCatIds.indexOf(catId)
    if (idx >= 0) {
      const next = [...this.collapsedCatIds]
      next.splice(idx, 1)
      this.collapsedCatIds = next
    } else {
      this.collapsedCatIds = [...this.collapsedCatIds, catId]
    }
  }

  private collectBoards(cat: import('../model/Forum').Category): import('../model/Forum').BoardContent[] {
    const seen = new Set<number>()
    const boards: import('../model/Forum').BoardContent[] = []
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

  private collectBoardCount(cat: import('../model/Forum').Category): number {
    return this.collectBoards(cat).length
  }
}

