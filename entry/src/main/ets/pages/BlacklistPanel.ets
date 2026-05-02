/**
 * 黑名单管理面板 - 从 BlacklistPage 迁移, 统一 Panel 架构
 */

import { appStore } from '../store/AppStore'
import type { BlacklistEntry } from '../store/AppStore'
import { AppColors } from '../common/Constants'
import { escHtml, unescapeHtml } from '../common/Utils'
import { BlacklistDataSource } from '../common/LazyDataSource'
import { PanelNavBar } from '../common/PanelNavBar'
import { ConfirmDialog, AddBlacklistDialog } from '../common/Dialogs'

@Component
export struct BlacklistPanel {
  @State removeTarget: BlacklistEntry | null = null
  @State blacklistCount: number = 0
  @StorageProp('statusBarHeight') statusBarHeight: number = 0
  @StorageProp('navBarHeight') navBarHeight: number = 0

  private blacklistDataSource: BlacklistDataSource = new BlacklistDataSource()

  addDialogController?: CustomDialogController

  deleteDialogController?: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '移除黑名单',
      message: '确定要将其从黑名单中移除吗？',
      confirmLabel: '移除',
      destructive: true,
      onConfirm: () => {
        if (this.removeTarget) {
          appStore.removeBlacklist(this.removeTarget.userId)
          this.refreshBlacklist()
          this.removeTarget = null
        }
      },
      onCancel: () => {
        this.removeTarget = null
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
    this.refreshBlacklist()
  }

  private refreshBlacklist(): void {
    this.blacklistCount = appStore.settings.blacklist.length
    this.blacklistDataSource.replaceAll(appStore.settings.blacklist)
  }

  build() {
    Stack() {
      Column() {
        Row().width('100%').height(44 + this.statusBarHeight)

        if (this.blacklistCount === 0) {
          Column() {
            Image($r('app.media.icon_block')).width(40).height(40).fillColor(AppColors.textTertiary).opacity(0.4)
            Text('黑名单为空').fontSize(15).fontColor(AppColors.textTertiary).margin({ top: 8 })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else {
          Row() {
            Text('共 ' + String(this.blacklistCount) + ' 人').fontSize(13).fontColor(AppColors.textTertiary).layoutWeight(1)
            Text('删除全部').fontSize(13).fontColor(AppColors.destructive)
              .onClick(() => {
                appStore.removeAllBlacklist()
                this.refreshBlacklist()
                appStore.showToast('已清空黑名单')
              })
          }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

          List() {
            LazyForEach(this.blacklistDataSource, (entry: BlacklistEntry) => {
              ListItem() {
                Row() {
                  Stack() {
                    Image($r('app.media.icon_person')).width(20).height(20).fillColor(AppColors.textTertiary)
                  }
                  .width(40).height(40).borderRadius(20).backgroundColor(AppColors.bgSecondary)

                  Column() {
                    Text(unescapeHtml(entry.nickName)).fontSize(15).fontColor(AppColors.textPrimary)
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`UID: ${escHtml(entry.userId)}`).fontSize(13).fontColor(AppColors.textTertiary).margin({ top: 2 })
                  }
                  .layoutWeight(1).margin({ left: 12 }).alignItems(HorizontalAlign.Start)

                  Stack() {
                    Image($r('app.media.icon_delete')).width(18).height(18).fillColor(AppColors.destructive)
                  }
                  .width(40).height(40)
                  .onClick(() => {
                    this.removeTarget = entry
                    this.deleteDialogController?.open()
                  })
                }
                .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }).alignItems(VerticalAlign.Center)
              }
            }, (entry: BlacklistEntry) => entry.userId)
          }
          .width('100%').layoutWeight(1)
          .divider({ strokeWidth: 0.5, color: AppColors.separator })
        }
      }
      .width('100%').height('100%')

      PanelNavBar({ title: '黑名单管理', rightLabel: '+ 添加', onRightClick: (): void => {
        this.addDialogController = new CustomDialogController({
          builder: AddBlacklistDialog({
            onConfirm: (uid: string): void => {
              appStore.addBlacklist({ userId: uid, nickName: `User${uid}` })
              this.refreshBlacklist()
              appStore.showToast('已加入黑名单')
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
