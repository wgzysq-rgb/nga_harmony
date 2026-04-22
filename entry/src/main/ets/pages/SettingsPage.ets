/**
 * 设置页面 - 复刻 React SettingsPage.tsx
 * 深色模式 / 字号 / NGA 域名 / 黑名单管理 / 退出登录
 */

import router from '@ohos.router'
import { appStore } from '../store/AppStore'
import { NavBar } from '../common/NavBar'
import { AppColors, FONT_OPTIONS, DOMAIN_OPTIONS, FontOption, DomainOption } from '../common/Constants'
import { ActionSheetDialog, ActionOption, ConfirmDialog } from '../common/Dialogs'

@Entry
@Component
struct SettingsPage {
  @State showFontSheet: boolean = false
  @State showDomainSheet: boolean = false
  @State showLogoutConfirm: boolean = false
  fontSizeDialogController?: CustomDialogController
  domainDialogController?: CustomDialogController
  logoutDialogController?: CustomDialogController

  build() {
    Column() {
      NavBar({ title: '设置', showBack: true })

      Scroll() {
        Column() {
          // 外观设置
          Column() {
            // 深色模式
            this.SettingRow('🌙', '#5856D6', '深色模式', appStore.settings.theme === 'dark' ? '开启' : '', () => {
              appStore.toggleTheme()
            })

            Divider().margin({ left: 60 }).color(AppColors.separator)

            // 字号
            this.SettingRow('🔤', '#FF2D55', '字号',
              FONT_OPTIONS.find((f: FontOption) => f.value === appStore.settings.fontSize)?.label ?? '中', () => {
                this.fontSizeDialogController?.open()
              })

            Divider().margin({ left: 60 }).color(AppColors.separator)

            // NGA 域名
            this.SettingRow('🌐', '#5AC8FA', 'NGA 域名',
              DOMAIN_OPTIONS[appStore.settings.domainIndex]?.label ?? 'bbs.nga.cn', () => {
                this.domainDialogController?.open()
              })
          }
          .width('92%')
          .backgroundColor(AppColors.bgTertiary)
          .borderRadius(12)
          .margin({ top: 20 })

          // 其他
          Column() {
            // 黑名单管理
            this.SettingRow('🚫', '#8E8E93', '黑名单管理', '', () => {
              router.pushUrl({ url: 'pages/BlacklistPage' })
            })

            Divider().margin({ left: 60 }).color(AppColors.separator)

            // 退出登录
            Row() {
              Stack() {
                Text('🚪')
                  .fontSize(17)
                  .fontColor(Color.White)
              }
              .width(29)
              .height(29)
              .borderRadius(6)
              .backgroundColor('#FF3B30')
              .margin({ right: 12 })

              Text('退出登录')
                .fontSize(17)
                .fontColor('#FF3B30')
                .layoutWeight(1)
            }
            .width('100%')
            .height(44)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.logoutDialogController?.open()
            })
          }
          .width('92%')
          .backgroundColor(AppColors.bgTertiary)
          .borderRadius(12)
          .margin({ top: 20 })
        }
        .width('100%')
        .padding({ bottom: 30 })
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.bg)
    .bindContentCover(this.fontSizeDialogController !== undefined, this.FontSizeDialogBuilder())
    .bindContentCover(this.domainDialogController !== undefined, this.DomainDialogBuilder())
    .bindContentCover(this.logoutDialogController !== undefined, this.LogoutDialogBuilder())
  }

  @Builder
  FontSizeDialogBuilder() {
    ActionSheetDialog({
      title: '选择字号',
      options: FONT_OPTIONS as ActionOption[],
      selected: appStore.settings.fontSize,
      onSelect: (value: number) => {
        appStore.setFontSize(value)
      },
      onCancel: () => {}
    })
  }

  @Builder
  DomainDialogBuilder() {
    ActionSheetDialog({
      title: '选择域名',
      options: DOMAIN_OPTIONS as ActionOption[],
      selected: appStore.settings.domainIndex,
      onSelect: (value: number) => {
        appStore.setDomainIndex(value)
      },
      onCancel: () => {}
    })
  }

  @Builder
  LogoutDialogBuilder() {
    ConfirmDialog({
      title: '退出登录',
      message: '确定要退出登录吗？',
      confirmLabel: '退出',
      destructive: true,
      onConfirm: () => {
        appStore.clearAuth()
        router.replaceUrl({ url: 'pages/LoginPage' })
      },
      onCancel: () => {}
    })
  }

  @Builder
  SettingRow(icon: string, iconColor: string, label: string, badge: string, action: () => void) {
    Row() {
      Stack() {
        Text(icon)
          .fontSize(17)
          .fontColor(Color.White)
      }
      .width(29)
      .height(29)
      .borderRadius(6)
      .backgroundColor(iconColor)
      .margin({ right: 12 })

      Text(label)
        .fontSize(17)
        .layoutWeight(1)

      if (badge) {
        Text(badge)
          .fontSize(15)
          .fontColor(AppColors.textSecondary)
          .margin({ right: 8 })
      }

      Text('>')
        .fontSize(16)
        .fontColor('#C7C7CC')
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(action)
  }
}
