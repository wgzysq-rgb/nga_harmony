/**
 * 用户资料页 - 复刻 React ProfilePage.tsx
 * 自身 profile: 显示私信/通知/收藏/签到/设置操作列表
 * 其他用户: 显示发私信/查看帖子/加黑操作按钮
 */

import router from '@ohos.router'
import { appStore } from '../store/AppStore'
import { getUserProfile, getNotifications, checkin } from '../service/NgaApi'
import { ProfileData } from '../model/User'
import { NavBar } from '../common/NavBar'
import { AppColors } from '../common/Constants'
import { formatTime, fmtNum, escHtml } from '../common/Utils'
import { ReputationData } from '../model/User'
import { Avatar } from '../common/Avatar'

@Entry
@Component
struct ProfilePage {
  @State isLoading: boolean = true
  @State hasError: boolean = false
  @State errorMsg: string = ''
  @State profile: ProfileData | null = null
  @State unreadNotifications: number = 0
  @State unreadMessages: number = 0
  @State checkinLoading: boolean = false
  @State checkinResult: string = ''

  private uid: string = ''
  private isOwnProfile: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params) {
      this.uid = params['uid'] ?? ''
    }
    this.isOwnProfile = appStore.auth.uid === this.uid
    this.loadProfile()
    if (this.isOwnProfile) {
      this.loadUnreadCount()
    }
  }

  private async loadProfile(): Promise<void> {
    this.isLoading = true
    this.hasError = false
    try {
      const result = await getUserProfile(appStore.auth.token, this.uid)
      if (result.ok && result.data) {
        this.profile = result.data
      } else {
        this.hasError = true
        this.errorMsg = result.error || '加载失败'
      }
    } catch (e) {
      this.hasError = true
      this.errorMsg = (e as Error).message || '加载失败'
    }
    this.isLoading = false
  }

  private async loadUnreadCount(): Promise<void> {
    try {
      const result = await getNotifications(appStore.auth.token)
      if (result.ok && result.data) {
        const notifications = result.data as import('../model/Notification').NotificationInfo[]
        this.unreadNotifications = notifications.length
      }
    } catch (e) {
      // ignore
    }
  }

  private async handleCheckin(): Promise<void> {
    this.checkinLoading = true
    try {
      const result = await checkin(appStore.auth.token)
      if (result.ok) {
        this.checkinResult = '签到成功'
      } else {
        this.checkinResult = result.error || '签到失败'
      }
    } catch (e) {
      this.checkinResult = '签到失败'
    }
    this.checkinLoading = false
    setTimeout(() => { this.checkinResult = '' }, 3000)
  }

  @Builder
  StatRow(icon: string, label: string, value: string) {
    Row() {
      Text(icon)
        .fontSize(16)
        .margin({ right: 8 })
      Text(label)
        .fontSize(14)
        .fontColor(AppColors.textSecondary)
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor(AppColors.textPrimary)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  // 自身 profile 操作行 (复刻 React SettingRow 样式)
  @Builder
  ActionRow(icon: string, iconColor: string, label: string, badge: string, action: () => void) {
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
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#FF3B30')
          .borderRadius(10)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .fontWeight(FontWeight.Bold)
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

  build() {
    Column() {
      NavBar({ title: '用户资料', showBack: true })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(28).height(28).color(AppColors.textTertiary)
          Text('加载中...')
            .fontSize(14)
            .fontColor(AppColors.textTertiary)
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.hasError) {
        Column() {
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor(AppColors.textTertiary)
            .margin({ bottom: 12 })
          Button('重试')
            .fontSize(14)
            .fontColor(AppColors.primary)
            .backgroundColor(AppColors.bgSecondary)
            .borderRadius(10)
            .onClick(() => this.loadProfile())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.profile) {
        Scroll() {
          Column() {
            // 用户头像区
            Column() {
              // 头像
              Avatar({ avatar: this.profile!.avatarUrl, uid: String(this.profile!.uid), name: this.profile!.userName, avatarSize: 80 })

              Text(escHtml(this.profile!.userName))
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 12 })

              Row() {
                if (this.profile!.group) {
                  Text(escHtml(this.profile!.group))
                    .fontSize(12)
                    .fontColor(AppColors.primary)
                    .backgroundColor(AppColors.primaryLight)
                    .borderRadius(4)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                }
                Text(`UID: ${escHtml(this.profile!.uid)}`)
                  .fontSize(13)
                  .fontColor(AppColors.textSecondary)
                  .margin({ left: 8 })

                if (this.profile!.ipLoc) {
                  Text(`📍 ${escHtml(this.profile!.ipLoc)}`)
                    .fontSize(13)
                    .fontColor(AppColors.textSecondary)
                    .margin({ left: 8 })
                }
              }
              .margin({ top: 8 })

              if (this.profile!.title) {
                Text(escHtml(this.profile!.title))
                  .fontSize(13)
                  .fontColor(AppColors.textTertiary)
                  .margin({ top: 6 })
              }
              if (this.profile!.honor) {
                Text(escHtml(this.profile!.honor))
                  .fontSize(12)
                  .fontColor(AppColors.warning)
                  .fontWeight(FontWeight.Medium)
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .padding({ top: 24, bottom: 16 })
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(AppColors.bgTertiary)

            // 统计信息
            Column() {
              this.StatRow('💬', '发帖数', fmtNum(this.profile!.posts))
              Divider().margin({ left: 60 }).color(AppColors.separator)
              this.StatRow('💰', '金钱', fmtNum(this.profile!.money))
              Divider().margin({ left: 60 }).color(AppColors.separator)
              this.StatRow('🏅', '威望', fmtNum(this.profile!.rvrc))
              Divider().margin({ left: 60 }).color(AppColors.separator)
              this.StatRow('📅', '注册日期', this.profile!.regdate || '未知')
              Divider().margin({ left: 60 }).color(AppColors.separator)
              this.StatRow('👥', '会员组', this.profile!.group || '普通会员')
              if (Number(this.profile!.fame) > 0) {
                Divider().margin({ left: 60 }).color(AppColors.separator)
                this.StatRow('⭐', '声望', fmtNum(this.profile!.fame))
              }
              if (Number(this.profile!.followByNum) > 0) {
                Divider().margin({ left: 60 }).color(AppColors.separator)
                this.StatRow('🛡', '被关注', this.profile!.followByNum)
              }
            }
            .width('92%')
            .backgroundColor(AppColors.bgTertiary)
            .borderRadius(12)
            .margin({ top: 16 })

            // 勋章
            if (this.profile!.medal) {
              Column() {
                Text('勋章')
                  .fontSize(13)
                  .fontColor(AppColors.textSecondary)
                  .margin({ bottom: 4 })
                RichText(this.profile!.medal)
                  .width('100%')
              }
              .width('92%')
              .padding(16)
              .backgroundColor(AppColors.bgTertiary)
              .borderRadius(12)
              .margin({ top: 16 })
              .alignItems(HorizontalAlign.Start)
            }

            // 签名
            if (this.profile!.sign) {
              Column() {
                Text('签名')
                  .fontSize(13)
                  .fontColor(AppColors.textSecondary)
                  .margin({ bottom: 4 })
                RichText(this.profile!.sign)
                  .width('100%')
              }
              .width('92%')
              .padding(16)
              .backgroundColor(AppColors.bgTertiary)
              .borderRadius(12)
              .margin({ top: 16 })
              .alignItems(HorizontalAlign.Start)
            }

            // 操作按钮区域 (复刻 React ProfilePage: 自身 vs 其他用户)
            if (this.isOwnProfile) {
              // 自身 profile: 设置列表 (复刻 React ProfilePage own profile)
              Column() {
                // 私信
                this.ActionRow('📩', '#007AFF', '私信',
                  this.unreadMessages > 0 ? `${this.unreadMessages}` : '', () => {
                    router.pushUrl({ url: 'pages/MessageListPage' })
                  })
                Divider().margin({ left: 60 }).color(AppColors.separator)
                // 通知
                this.ActionRow('🔔', '#FF3B30', '通知',
                  this.unreadNotifications > 0 ? `${this.unreadNotifications}` : '', () => {
                    router.pushUrl({ url: 'pages/NotificationPage' })
                  })
                Divider().margin({ left: 60 }).color(AppColors.separator)
                // 收藏主题
                this.ActionRow('⭐', '#FF9500', '收藏主题', '', () => {
                  router.pushUrl({
                    url: 'pages/TopicListPage',
                    params: { fid: '__favorites__', favor: '1', name: '我的收藏' }
                  })
                })
                Divider().margin({ left: 60 }).color(AppColors.separator)
                // 每日签到
                this.ActionRow('✅', '#34C759',
                  this.checkinLoading ? '签到中...' : this.checkinResult || '每日签到', '', () => {
                    this.handleCheckin()
                  })
                Divider().margin({ left: 60 }).color(AppColors.separator)
                // 设置
                this.ActionRow('⚙️', '#5856D6', '设置', '', () => {
                  router.pushUrl({ url: 'pages/SettingsPage' })
                })
              }
              .width('92%')
              .backgroundColor(AppColors.bgTertiary)
              .borderRadius(12)
              .margin({ top: 24 })
            } else {
              // 其他用户: 操作按钮 (复刻 React ProfilePage other user)
              Row() {
                Button('发私信')
                  .fontSize(15)
                  .fontColor(Color.White)
                  .backgroundColor(AppColors.primary)
                  .borderRadius(12)
                  .layoutWeight(1)
                  .height(44)
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/MessageListPage',
                      params: { composeTo: this.profile!.userName }
                    })
                  })

                Button('查看帖子')
                  .fontSize(15)
                  .fontColor(AppColors.textPrimary)
                  .backgroundColor(AppColors.bgTertiary)
                  .borderRadius(12)
                  .layoutWeight(1)
                  .height(44)
                  .margin({ left: 12 })
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/TopicListPage',
                      params: {
                        fid: '-1',
                        authorid: this.profile!.uid,
                        name: this.profile!.userName + '的帖子'
                      }
                    })
                  })

                Button('加黑')
                  .fontSize(15)
                  .fontColor(AppColors.destructive)
                  .backgroundColor(AppColors.bgTertiary)
                  .borderRadius(12)
                  .height(44)
                  .margin({ left: 12 })
                  .onClick(() => {
                    appStore.addBlacklist({
                      userId: this.profile!.uid,
                      nickName: this.profile!.userName || `User${this.profile!.uid}`
                    })
                    appStore.showToast('已加入黑名单')
                  })
              }
              .width('92%')
              .margin({ top: 24, bottom: 30 })
            }
          }
          .alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.bg)
  }
}
