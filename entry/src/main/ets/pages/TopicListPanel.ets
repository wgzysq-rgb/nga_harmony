/**
 * 嵌入式主题列表面板 - 用于 md/lg 布局的中间列
 * 复刻 React TopicListPage 的 embedded 模式
 * 点击主题通过 routerStore 导航, 不使用 router.pushUrl
 */

import { appStore } from '../store/AppStore'
import { routerStore, Screen } from '../store/RouterStore'
import { getTopicList, createTopicListParams, TopicListParams, TopicListResult } from '../service/NgaApi'
import { AppColors, FONT_COLORS, SORT_MODES, SortMode, BreakpointType } from '../common/Constants'
import { formatTime, escHtml } from '../common/Utils'
import router from '@ohos.router'

@Component
export struct TopicListPanel {
  @Prop @Watch('onBoardChanged') boardFid: number = 0
  @Prop boardName: string = ''
  @Prop boardStid: string = ''
  @Prop isFavorites: boolean = false
  @State isLoading: boolean = true
  @State isLoadingMore: boolean = false
  @State hasError: boolean = false
  @State errorMsg: string = ''
  @State threads: object[] = []
  @State currentPage: number = 1
  @State totalPages: number = 0
  @State sortMode: string = 'latest'
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'

  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.loadTopics(1)
  }

  private onBoardChanged(): void {
    this.threads = []
    this.currentPage = 1
    this.totalPages = 0
    this.hasError = false
    this.sortMode = 'latest'
    this.loadTopics(1)
  }

  private async loadTopics(page: number): Promise<void> {
    if (page === 1) {
      this.isLoading = true
      this.hasError = false
    } else {
      this.isLoadingMore = true
    }

    const params: TopicListParams = createTopicListParams()
    params.page = String(page)

    if (this.isFavorites) {
      params.favor = '1'
    } else {
      if (this.boardFid) params.fid = String(this.boardFid)
      if (this.boardStid) params.stid = this.boardStid
    }

    if (this.sortMode === 'recommend') {
      params.recommend = '1'
    } else if (this.sortMode === 'hot') {
      params.recommend = '1'
      params.twentyfour = '1'
    }

    try {
      const result: TopicListResult = await getTopicList(appStore.auth.token, params)
      if (result.ok && result.data) {
        const list = result.data.threadPageList
        if (page === 1) {
          this.threads = list
        } else {
          const arr: object[] = []
          for (let i = 0; i < this.threads.length; i++) arr.push(this.threads[i])
          for (let i = 0; i < list.length; i++) arr.push(list[i])
          this.threads = arr
        }
        this.currentPage = page
        this.totalPages = result.data.pagination.totalPages
      } else if (page === 1) {
        this.hasError = true
        this.errorMsg = result.error || '加载失败'
      }
    } catch (e) {
      if (page === 1) {
        this.hasError = true
        this.errorMsg = (e as Error).message || '加载失败'
      }
    }
    this.isLoading = false
    this.isLoadingMore = false
  }

  private getSubjectFontColor(titleFont: string): string {
    const num = Number(titleFont) || 0
    const color = num & 0x1f
    if (FONT_COLORS[color]) return FONT_COLORS[color]
    return AppColors.textPrimary
  }

  private isSubjectBold(titleFont: string): boolean {
    return (Number(titleFont) & 32) !== 0
  }

  private isSubjectItalic(titleFont: string): boolean {
    return (Number(titleFont) & 64) !== 0
  }

  private getTypeTags(type: number): string {
    if (type & 1024) return '[锁定]'
    if (type & 8192) return '[附件]'
    return ''
  }

  build() {
    Column() {
      // 标题栏 (嵌入式, 不带返回按钮)
      Row() {
        Text(this.boardName)
          .fontSize(17).fontWeight(FontWeight.Bold).layoutWeight(1)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%').height(44).padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.bgTertiary)
      .border({ width: { bottom: 0.5 }, color: AppColors.separator })
      .alignItems(VerticalAlign.Center)

      // 排序栏
      Row() {
        ForEach(SORT_MODES, (mode: SortMode) => {
          Text(mode.label)
            .fontSize(13)
            .fontColor(this.sortMode === mode.key ? AppColors.textPrimary : AppColors.textTertiary)
            .fontWeight(this.sortMode === mode.key ? FontWeight.Bold : FontWeight.Normal)
            .backgroundColor(this.sortMode === mode.key ? AppColors.bg : Color.Transparent)
            .borderRadius(7)
            .padding({ left: 12, right: 12, top: 5, bottom: 5 })
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              if (this.sortMode !== mode.key) {
                this.sortMode = mode.key
                this.loadTopics(1)
              }
            })
        })
      }
      .width('92%').margin({ top: 8, bottom: 4 }).padding(3)
      .backgroundColor(AppColors.bgSecondary).borderRadius(10)

      // 内容
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(28).height(28).color(AppColors.textTertiary)
          Text('加载中...').fontSize(14).fontColor(AppColors.textTertiary).margin({ top: 8 })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else if (this.hasError) {
        Column() {
          Text(this.errorMsg || '加载失败').fontSize(14).fontColor(AppColors.textTertiary).margin({ bottom: 12 })
          Button('重试').fontSize(14).fontColor(AppColors.primary).backgroundColor(AppColors.bgSecondary).borderRadius(10)
            .onClick(() => this.loadTopics(1))
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else if (this.threads.length === 0) {
        Column() {
          Text('💬').fontSize(40).opacity(0.4).margin({ bottom: 8 })
          Text('暂无主题').fontSize(15).fontColor(AppColors.textTertiary)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.threads, (thread: object) => {
            ListItem() {
              this.TopicCard(thread as Record<string, Object>)
            }
          })
          ListItem() {
            Row() {
              if (this.isLoadingMore) {
                LoadingProgress().width(16).height(16).color(AppColors.textTertiary)
                Text('加载更多...').fontSize(13).fontColor(AppColors.textTertiary).margin({ left: 8 })
              } else if (this.currentPage >= this.totalPages) {
                Text('— 已到底 —').fontSize(12).fontColor(AppColors.textTertiary)
              }
            }.width('100%').justifyContent(FlexAlign.Center).padding({ top: 16, bottom: 16 })
          }
        }
        .width('100%').layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: AppColors.separator })
        .lanes(new BreakpointType(1, 1, 1).getValue(this.currentBreakpoint), 12)
        .edgeEffect(EdgeEffect.Spring)
        .onReachEnd(() => {
          if (!this.isLoadingMore && this.currentPage < this.totalPages) {
            this.loadTopics(this.currentPage + 1)
          }
        })
      }

      // 浮动刷新按钮 (复刻 React: floating RefreshCw FAB)
      Stack() {
        Text('🔄').fontSize(20).fontColor(AppColors.primary)
      }
      .width(44).height(44).borderRadius(22)
      .backgroundColor(AppColors.bgTertiary)
      .shadow({ radius: 6, color: '#20000000', offsetY: 2 })
      .position({ x: '100%', y: '100%' })
      .translate({ x: '-60vp', y: '-60vp' })
      .onClick(() => this.loadTopics(1))
    }
    .width('100%').height('100%').backgroundColor(AppColors.bg)
  }

  @Builder
  TopicCard(thread: Record<string, Object>) {
    Column() {
      Row() {
        Text(this.getTypeTags(Number(thread['type'] ?? 0)))
          .fontSize(15).fontColor(AppColors.textTertiary)
        Text(escHtml(String(thread['subject'] ?? '')))
          .fontSize(15)
          .fontColor(this.getSubjectFontColor(String(thread['titleFont'] ?? '')))
          .fontWeight(this.isSubjectBold(String(thread['titleFont'] ?? '')) ? FontWeight.Bold : FontWeight.Normal)
          .fontStyle(this.isSubjectItalic(String(thread['titleFont'] ?? '')) ? FontStyle.Italic : FontStyle.Normal)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
      }.width('100%').alignItems(VerticalAlign.Top)

      if (thread['previewSnippet']) {
        Text(escHtml(String(thread['previewSnippet'] ?? '')))
          .fontSize(13).fontColor(AppColors.textSecondary).maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 6 }).width('100%')
      }

      Row() {
        Text(`${escHtml(String(thread['author'] ?? ''))} · ${formatTime(Number(thread['postDate'] ?? 0))}`)
          .fontSize(12).fontColor(AppColors.textTertiary)
        Text(`💬 ${thread['replies'] ?? 0}`)
          .fontSize(12).fontColor(AppColors.textTertiary)
      }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ top: 8 })
    }
    .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 }).alignItems(HorizontalAlign.Start)
    .onClick(() => {
      const tid = String(thread['tid'] ?? '')
      if (tid) {
        routerStore.navigateActivity(Screen.thread(tid))
      }
    })
  }
}
