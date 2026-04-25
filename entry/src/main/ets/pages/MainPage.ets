/**
 * 主页面 - 统一三列 Panel 架构
 *
 * 第一列: 侧边栏堆栈, 固定且唯一
 * 第二列: 论坛板块堆栈, 替换模式, 堆栈深度为1
 * 第三列: 自由堆栈, 先入后出, 承载 App 大部分页面
 *
 * sm (一列): 显示内容区(activity > board > 社区网格), 不显示侧边栏
 * md (两列): 侧边栏 + 单列内容区
 * lg (三列): 侧边栏 + 板块列 + 活动列
 */

import { appStore } from '../store/AppStore'
import { routerStore, RouterStoreClass } from '../store/RouterStore'
import { getCurrentUser } from '../service/NgaApi'
import router from '@ohos.router'
import { floatingLayerStore, FloatingLayerStoreClass, FloatingPage } from '../store/FloatingLayerStore'
import { ActivityPanelComponent } from './ActivityPanelComponent'
import { BoardPanelComponent } from './BoardPanelComponent'
import { SidebarComponent } from './SidebarComponent'
import { CommunityTabContent } from './CommunityTabContent'
import { FloatingLayerComponent } from './FloatingLayerComponent'
import { EmptyHint } from '../common/EmptyHint'
import { ToastComponent } from '../common/Toast'

@Entry
@Component
struct MainPage {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @State private router: RouterStoreClass = routerStore
  @State private floating: FloatingLayerStoreClass = floatingLayerStore

  aboutToAppear(): void {
    this.checkAuth()
  }

  onBackPress(): boolean {
    if (this.floating.size > 0) {
      if (this.floating.top === FloatingPage.REPLY_DIALOG) {
        this.floating.notifyReplyCloseRequested()
      } else {
        this.floating.pop()
      }
      return true
    }
    if (this.router.activityStack.length > 0) {
      this.router.back()
      return true
    }
    if (this.router.boardSlot) {
      if (this.currentBreakpoint === 'sm' || this.router.boardSlot.type === 'search') {
        this.router.back()
        return true
      }
      return true
    }
    return false
  }

  build() {
    Stack() {
      if (this.currentBreakpoint === 'sm') {
        this.SmLayout()
      } else if (this.currentBreakpoint === 'md') {
        this.MdLayout()
      } else {
        this.LgLayout()
      }

      FloatingLayerComponent({ currentBreakpoint: this.currentBreakpoint })
      ToastComponent()
    }
    .width('100%').height('100%')
  }

  @Builder
  SmLayout() {
    if (this.router.topActivity) {
      Column() {
        ActivityPanelComponent({ topActivity: this.router.topActivity })
      }
      .width('100%').height('100%')
      .transition(TransitionEffect.opacity(0).animation({ duration: 200 }))
    } else if (this.router.boardSlot) {
      Column() {
        BoardPanelComponent({ boardSlot: this.router.boardSlot })
      }
      .width('100%').height('100%')
      .transition(TransitionEffect.opacity(0).animation({ duration: 200 }))
    } else {
      Column() {
        CommunityTabContent({ currentBreakpoint: 'sm' })
      }
      .width('100%').height('100%')
    }
  }

  @Builder
  MdLayout() {
    Row() {
      SidebarComponent()

      Column() {
        if (this.router.topActivity) {
          Column() {
            ActivityPanelComponent({ topActivity: this.router.topActivity })
          }
          .height('100%').width('100%')
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.translate({ x: 30 }).combine(TransitionEffect.opacity(0))
                .animation({ duration: 250 }),
              TransitionEffect.translate({ x: 30 }).combine(TransitionEffect.opacity(0))
                .animation({ duration: 250 })
            )
          )
        } else if (this.router.boardSlot) {
          Column() {
            BoardPanelComponent({ boardSlot: this.router.boardSlot })
          }
          .height('100%').width('100%')
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.translate({ x: -30 }).combine(TransitionEffect.opacity(0))
                .animation({ duration: 250 }),
              TransitionEffect.translate({ x: -30 }).combine(TransitionEffect.opacity(0))
                .animation({ duration: 250 })
            )
          )
        } else {
          Column() {
            EmptyHint()
          }
          .height('100%').width('100%')
          .transition(TransitionEffect.opacity(0).animation({ duration: 150 }))
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  LgLayout() {
    Row() {
      SidebarComponent()

      Row() {
        if (this.router.boardSlot || !this.router.topActivity) {
          Column() {
            if (this.router.boardSlot) {
              BoardPanelComponent({ boardSlot: this.router.boardSlot })
            } else {
              EmptyHint()
            }
          }
          .width(this.router.topActivity ? '40%' : '100%')
          .height('100%')
          .animation({ duration: 250, curve: Curve.FastOutLinearIn })
        }

        if (this.router.topActivity) {
          Column() {
            ActivityPanelComponent({ topActivity: this.router.topActivity })
          }
          .layoutWeight(1)
          .height('100%')
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.translate({ x: 30 }).combine(TransitionEffect.opacity(0))
                .animation({ duration: 250 }),
              TransitionEffect.translate({ x: 30 }).combine(TransitionEffect.opacity(0))
                .animation({ duration: 250 })
            )
          )
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  private async checkAuth(): Promise<void> {
    if (!appStore.auth.isAuthenticated) {
      router.replaceUrl({ url: 'pages/LoginPage' })
      return
    }

    try {
      await getCurrentUser(appStore.auth.token)
    } catch (e) {
    }
    appStore.fetchFavorites()
  }
}
