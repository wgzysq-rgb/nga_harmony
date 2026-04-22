import router from '@ohos.router'
import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'
import { NavBar } from '../common/NavBar'
import { AppColors } from '../common/Constants'
import { ConfirmDialog } from '../common/Dialogs'
import { escHtml, formatTime } from '../common/Utils'
import { appStore } from '../store/AppStore'

class HistoryItem {
  tid: string = ''
  subject: string = ''
  author: string = ''
  replies: number = 0
  ts: number = 0
  board: string = ''
}

@Entry
@Component
struct BrowseHistoryPage {
  @State items: HistoryItem[] = []
  @State showClearConfirm: boolean = false
  clearDialogController?: CustomDialogController

  aboutToAppear(): void {
    this.loadHistory()
  }

  private async loadHistory(): Promise<void> {
    try {
      const ctx = getContext(this) as Context
      const pref = await preferences.getPreferences(ctx, 'nga_browse_history')
      const raw = (await pref.get('items', '[]')) as string
      this.items = JSON.parse(raw) as HistoryItem[]
    } catch (e) {
      this.items = []
    }
  }

  private async removeItem(tid: string): Promise<void> {
    this.items = this.items.filter((item: HistoryItem) => item.tid !== tid)
    await this.persist()
  }

  private async clearAll(): Promise<void> {
    this.items = []
    await this.persist()
  }

  private async persist(): Promise<void> {
    try {
      const ctx = getContext(this) as Context
      const pref = await preferences.getPreferences(ctx, 'nga_browse_history')
      await pref.put('items', JSON.stringify(this.items))
      await pref.flush()
    } catch (e) {
    }
  }

  build() {
    Column() {
      NavBar({
        title: `浏览历史 (${this.items.length})`,
        showBack: true,
        rightLabel: this.items.length > 0 ? '清空' : '',
        onRightClick: () => {
          this.clearDialogController?.open()
        }
      })

      if (this.items.length === 0) {
        Column() {
          Text('🕐')
            .fontSize(40)
            .opacity(0.4)
            .margin({ bottom: 12 })
          Text('暂无浏览记录')
            .fontSize(15)
            .fontColor(AppColors.textTertiary)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.items, (item: HistoryItem) => {
              Row() {
                Column() {
                  Text(escHtml(item.subject))
                    .fontSize(15)
                    .fontColor(AppColors.textPrimary)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Row() {
                    if (item.board) {
                      Text(escHtml(item.board))
                        .fontSize(12)
                        .fontColor(AppColors.textTertiary)
                        .margin({ right: 4 })
                    }
                    Text(`${escHtml(item.author)} · ${formatTime(item.ts / 1000)}`)
                      .fontSize(12)
                      .fontColor(AppColors.textTertiary)
                    Text(`💬 ${item.replies}`)
                      .fontSize(12)
                      .fontColor(AppColors.textTertiary)
                      .margin({ left: 8 })
                  }
                  .margin({ top: 6 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Text('✕')
                  .fontSize(16)
                  .fontColor(AppColors.textTertiary)
                  .padding(8)
                  .onClick(() => this.removeItem(item.tid))
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/ThreadPage',
                  params: { tid: item.tid }
                })
              })
              .border({ width: { bottom: 0.5 }, color: AppColors.separator })
            }, (item: HistoryItem) => item.tid)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.bg)
    .bindContentCover(this.clearDialogController !== undefined, this.ClearDialogBuilder())
  }

  @Builder
  ClearDialogBuilder() {
    ConfirmDialog({
      title: '清空浏览记录',
      message: '确定清空所有浏览记录？此操作不可撤销。',
      confirmLabel: '清空',
      destructive: true,
      onConfirm: () => {
        this.clearAll()
        appStore.showToast('已清空浏览记录')
      },
      onCancel: () => {}
    })
  }
}
