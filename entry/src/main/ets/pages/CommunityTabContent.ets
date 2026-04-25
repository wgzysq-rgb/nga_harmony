import { appStore, FavBoard } from '../store/AppStore'
import { routerStore, RouterStoreClass } from '../store/RouterStore'
import { getForumCategories } from '../service/NgaApi'
import { AppColors } from '../common/Constants'
import { CategoryDataSource } from '../common/LazyDataSource'

@Component
export struct CommunityTabContent {
  @State isLoading: boolean = true
  @State collapsedCatIds: string[] = []
  @State favoritesList: FavBoard[] = []
  @State private router: RouterStoreClass = routerStore
  @Prop currentBreakpoint: string = 'sm'
  @StorageProp('favVersion') @Watch('onFavVersionChange') favVersion: number = 0
  categories: import('../model/Forum').Category[] = []
  private categoriesDataSource: CategoryDataSource = new CategoryDataSource()

  aboutToAppear(): void {
    this.syncFavorites()
    this.loadCategories()
  }

  private onFavVersionChange(): void {
    this.syncFavorites()
  }

  private syncFavorites(): void {
    this.favoritesList = [...appStore.settings.favorites]
  }

  private async loadCategories(): Promise<void> {
    try {
      const result = await getForumCategories(appStore.auth.token)
      if (result.ok) {
        this.categories = result.data
        this.categoriesDataSource.replaceAll(this.categories)
      }
    } catch (e) {
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

  private isFavBoard(fid: number): boolean {
    for (const f of this.favoritesList) {
      if (f.fid === fid) return true
    }
    return false
  }

  private handleToggleFav(fid: number, name: string): void {
    if (this.isFavBoard(fid)) {
      appStore.removeFavorite(fid)
    } else {
      const fb = new FavBoard()
      fb.fid = fid
      fb.stid = fid
      fb.name = name
      appStore.addFavorite(fb)
    }
  }

  @Builder
  SidebarListContent() {
    if (this.favoritesList.length > 0) {
      Column() {
        Text('收藏板块')
          .fontSize(11).fontWeight(FontWeight.Bold).fontColor(AppColors.textSecondary)
          .width('100%').padding({ left: 8, top: 8, bottom: 4 })

        ForEach(this.favoritesList, (fav: FavBoard) => {
          Row() {
            Image(`https://img4.nga.178.com/ngabbs/nga_classic/f/app/${fav.fid}.png`)
              .width(20).height(20).borderRadius(5).objectFit(ImageFit.Cover)
              .onError(() => {})
            Text(fav.name)
              .fontSize(12).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 6 }).layoutWeight(1)
          }
          .width('100%').height(32)
          .padding({ left: 8, right: 8 })
          .alignItems(VerticalAlign.Center)
          .borderRadius(8)
          .backgroundColor(this.isActiveBoard(fav.fid) ? AppColors.bgSecondary : Color.Transparent)
          .onClick(() => {
            routerStore.navigateForum(fav.fid, fav.name)
          })
        })
      }
      .width('100%')
    }

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
      Row() {
        Text('›')
          .fontSize(14).fontColor(AppColors.textTertiary).margin({ right: 6 })
          .rotate({ angle: this.isCatCollapsed(cat) ? 0 : 90 })
        Text(cat.name)
          .fontSize(13).fontWeight(FontWeight.Bold)
        Text(this.collectBoardCount(cat).toString())
          .fontSize(11).fontColor(AppColors.textTertiary).margin({ left: 6 })
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

  @Builder
  MobileContent() {
    Row() {
      Text('🔍')
        .fontSize(16).margin({ right: 8 })
      Text('搜索板块、主题...')
        .fontSize(15).fontColor(AppColors.textTertiary)
    }
    .width('92%').height(40).padding({ left: 12, right: 12 })
    .backgroundColor(AppColors.bgSecondary).borderRadius(10)
    .margin({ top: 12, bottom: 12 }).alignItems(VerticalAlign.Center)
    .onClick(() => {
      routerStore.navigateSearch()
    })

    if (this.favoritesList.length > 0) {
      this.FavoritesGrid()
    }

    if (this.isLoading) {
      Column() {
        LoadingProgress().width(24).height(24).color(AppColors.textTertiary)
        Text('加载中...').fontSize(14).fontColor(AppColors.textTertiary).margin({ top: 12 })
      }
      .width('100%').height(200)
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    } else {
      List() {
        LazyForEach(this.categoriesDataSource, (cat: import('../model/Forum').Category) => {
          ListItem() {
            this.CategoryGrid(cat)
          }
        }, (cat: import('../model/Forum').Category) => cat.id)
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
          .fontSize(13).fontWeight(FontWeight.Bold).fontColor(AppColors.primary)
        Text(`${this.favoritesList.length} 个板块`)
          .fontSize(11).fontColor(AppColors.textTertiary)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 6 })
      .justifyContent(FlexAlign.SpaceBetween)

      GridRow({ columns: { sm: 4, md: 4, lg: 3 }, gutter: 8 }) {
        ForEach(this.favoritesList, (fav: FavBoard) => {
          GridCol() {
            Column() {
              Stack() {
                Image(`https://img4.nga.178.com/ngabbs/nga_classic/f/app/${fav.fid}.png`)
                  .width(44).height(44).borderRadius(12).objectFit(ImageFit.Cover)
                  .onError(() => {})
              }
              .width(44).height(44).borderRadius(12).backgroundColor(AppColors.bgSecondary)

              Text(fav.name)
                .fontSize(11).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 56 })
            }
            .padding({ top: 8, bottom: 8 }).alignItems(HorizontalAlign.Center)
            .onClick(() => {
              routerStore.navigateForum(fav.fid, fav.name)
            })
          }
        })
      }
      .width('100%').padding({ left: 8, right: 8, bottom: 14 })
    }
    .width('92%').backgroundColor(AppColors.bgTertiary).borderRadius(12).margin({ bottom: 8 })
  }

  @Builder
  CategoryGrid(cat: import('../model/Forum').Category) {
    Column() {
      Row() {
        Text(cat.name).fontSize(13).fontWeight(FontWeight.Bold)
        Text(this.collectBoardCount(cat).toString())
          .fontSize(11).fontColor(AppColors.textTertiary).margin({ left: 6 })
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 8 })

      GridRow({ columns: { sm: 4, md: 4, lg: 3 }, gutter: 8 }) {
        ForEach(this.collectBoards(cat), (board: import('../model/Forum').BoardContent) => {
          GridCol() {
            Column() {
              Stack() {
                Image(`https://img4.nga.178.com/ngabbs/nga_classic/f/app/${board.fid}.png`)
                  .width(40).height(40).borderRadius(10).objectFit(ImageFit.Cover)
                  .onError(() => {})
              }
              .width(40).height(40).borderRadius(10).backgroundColor(AppColors.bgSecondary)

              Text(board.name)
                .fontSize(11).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 52 })
                .fontColor(AppColors.textPrimary)
            }
            .padding({ top: 10, bottom: 10 }).alignItems(HorizontalAlign.Center)
            .onClick(() => {
              routerStore.navigateForum(board.fid, board.name)
            })
          }
        })
      }
      .width('100%').padding({ left: 6, right: 6 })
      .backgroundColor(AppColors.bgTertiary).borderRadius(12)
    }
    .width('92%')
  }

  private isActiveBoard(fid: number): boolean {
    return this.router.boardSlot !== null && this.router.boardSlot.fid === fid
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
