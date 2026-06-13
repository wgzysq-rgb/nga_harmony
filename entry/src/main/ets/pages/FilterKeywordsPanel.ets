import { appStore } from '../store/AppStore'
import { FilterKeyword } from '../model/FilterKeyword'
import { AppColors } from '../common/constants/Constants'
import { FilterKeywordDataSource } from '../common/datasource/LazyDataSource'
import { PanelNavBar } from '../common/components/PanelNavBar'
import { ConfirmDialog, AddKeywordDialog } from '../common/dialogs/Dialogs'

@Component
export struct FilterKeywordsPanel {
  @State removeTarget: string = ''
  @State keywordCount: number = 0
  @StorageProp('statusBarHeight') statusBarHeight: number = 0
  @StorageProp('navBarHeight') navBarHeight: number = 0

  private keywordDataSource: FilterKeywordDataSource = new FilterKeywordDataSource()

  addDialogController?: CustomDialogController

  deleteDialogController?: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '删除关键词',
      message: '确定要删除该关键词吗？',
      confirmLabel: '删除',
      destructive: true,
      onConfirm: () => {
        if (this.removeTarget) {
          appStore.removeKeyword(this.removeTarget)
          this.refreshKeywords()
          this.removeTarget = ''
        }
      },
      onCancel: () => {
        this.removeTarget = ''
      }
    }),
    autoCancel: true,
    customStyle: true
  })

  aboutToDisappear(): void {
    this.deleteDialogController = undefined
    this.addDialogController = undefined
  }

  aboutToAppear(): void {
    this.refreshKeywords()
  }

  private refreshKeywords(): void {
    this.keywordCount = appStore.settings.filterKeywords.length
    this.keywordDataSource.replaceAll(appStore.settings.filterKeywords)
  }

  build() {
    Stack() {
      Column() {
        Row().width('100%').height(44 + this.statusBarHeight)

        if (this.keywordCount === 0) {
          Column() {
            Image($r('app.media.icon_text_fields')).width(40).height(40).fillColor(AppColors.textTertiary).opacity(0.4)
            Text('关键词列表为空').fontSize(15).fontColor(AppColors.textTertiary).margin({ top: 8 })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else {
          Row() {
            Text('共 ' + String(this.keywordCount) + ' 个关键词').fontSize(13).fontColor(AppColors.textTertiary).layoutWeight(1)
            Text('删除全部').fontSize(13).fontColor(AppColors.destructive)
              .onClick(() => {
                appStore.removeAllKeywords()
                this.refreshKeywords()
                appStore.showToast('已清空关键词')
              })
          }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

          List() {
            LazyForEach(this.keywordDataSource, (item: FilterKeyword) => {
              ListItem() {
                Row() {
                  Stack() {
                    Image($r('app.media.icon_check'))
                      .width(18).height(18)
                      .fillColor(item.enabled ? AppColors.primary : AppColors.textTertiary)
                      .opacity(item.enabled ? 1.0 : 0.3)
                  }
                  .width(40).height(40).borderRadius(20).backgroundColor(AppColors.bgSecondary)

                  Column() {
                    Text(item.keyword)
                      .fontSize(15).fontColor(item.enabled ? AppColors.textPrimary : AppColors.textTertiary)
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    if (!item.enabled) {
                      Text('已停用').fontSize(12).fontColor(AppColors.textTertiary).margin({ top: 2 })
                    }
                  }
                  .layoutWeight(1).margin({ left: 12 }).alignItems(HorizontalAlign.Start)
                  .onClick(() => {
                    appStore.toggleKeyword(item.keyword)
                    this.refreshKeywords()
                  })

                  Stack() {
                    Image($r('app.media.icon_delete')).width(18).height(18).fillColor(AppColors.destructive)
                  }
                  .width(40).height(40)
                  .onClick(() => {
                    this.removeTarget = item.keyword
                    this.deleteDialogController?.open()
                  })
                }
                .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }).alignItems(VerticalAlign.Center)
              }
            }, (item: FilterKeyword) => item.keyword)
          }
          .width('100%').layoutWeight(1)
          .divider({ strokeWidth: 0.5, color: AppColors.separator })
        }
      }
      .width('100%').height('100%')

      PanelNavBar({ title: '关键词屏蔽', rightLabel: '+ 添加', onRightClick: (): void => {
        this.addDialogController = new CustomDialogController({
          builder: AddKeywordDialog({
            onConfirm: (keyword: string): void => {
              appStore.addKeyword(keyword)
              this.refreshKeywords()
              appStore.showToast('已添加关键词')
            }
          }),
          autoCancel: true,
          customStyle: true,
          alignment: DialogAlignment.Center
        })
        this.addDialogController.open()
      } })
        .width('100%').position({ x: 0, y: 0 })
    }
    .width('100%').height('100%').backgroundColor(AppColors.bg)
  }
}
