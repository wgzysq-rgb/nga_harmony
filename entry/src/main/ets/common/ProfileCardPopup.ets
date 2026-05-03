import { appStore } from '../store/AppStore'
import { routerStore, Screen } from '../store/RouterStore'
import { ProfileData, AdminForumsData } from '../model/User'
import { AppColors } from '../common/Constants'
import { formatTime, fmtNum, escHtml, unescapeHtml } from '../common/Utils'
import { Avatar } from '../common/Avatar'
import { MakeNoteDialog } from '../common/Dialogs'
import { pasteboard } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';
import { getUserActivityAnalysis, UserActivityAnalysis, ForumStat } from '../service/NgaApi';
import { floatingLayerStore } from '../store/FloatingLayerStore';

@Component
export struct ProfileCardPopup {
  @Prop targetUid: string = ''
  @Prop currentBreakpoint: string = 'sm'
  @State profile: ProfileData | null = null
  @State isLoading: boolean = true
  @State hasError: boolean = false
  @StorageProp('profileVersion') @Watch('onProfileVersionChange') profileVersion: number = 0
  onClose: () => void = () => {}
  noteDialogController?: CustomDialogController
  @State analysisMode: string = 'idle'
  @State analysisData: UserActivityAnalysis | null = null

  private async startAnalysis(): Promise<void> {
    if (this.analysisMode !== 'idle') return
    this.analysisMode = 'loading'
    try {
      const result: UserActivityAnalysis | null = await getUserActivityAnalysis(
        appStore.auth.token,
        this.targetUid
      )
      if (result && (result.topicCount > 0 || result.replyCount > 0)) {
        this.analysisData = result
        this.analysisMode = 'ready'
        try {
          const d = display.getDefaultDisplaySync()
          const ctx = this.getUIContext()
          const screenH = ctx.px2vp(d.height)
          const targetY = Math.max(16, (screenH - 420) / 2)
          animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, () => {
            floatingLayerStore.profileCardY = targetY
          })
        } catch (e) {}
      } else {
        appStore.showToast('该用户暂无公开记录')
        this.analysisMode = 'idle'
      }
    } catch (e) {
      appStore.showToast('分析请求失败')
      this.analysisMode = 'idle'
    }
  }

  private async copyToClipboard(text: string): Promise<void> {
    try {
      const pb: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard()
      const record: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
      await pb.setData(record)
      appStore.showToast('已复制到剪贴板')
    } catch (e) {
      appStore.showToast('复制失败')
    }
  }

  private showNoteDialog(): void {
    this.noteDialogController = new CustomDialogController({
      builder: MakeNoteDialog({
        userName: this.profile?.userName ?? '',
        uid: this.targetUid,
        currentNote: appStore.getNote(this.targetUid),
        onConfirm: (note: string, uid: string, userName: string): void => {
          appStore.addOrUpdateNote(uid, userName, note)
          appStore.showToast('备注已保存')
        }
      }),
      autoCancel: true,
      customStyle: true,
      alignment: DialogAlignment.Center
    })
    this.noteDialogController.open()
  }

  aboutToAppear(): void {
    const cached = appStore.getCachedProfile(this.targetUid)
    if (cached) {
      this.profile = cached
      this.isLoading = false
    }
    appStore.ensureProfile(this.targetUid)
  }

  private onProfileVersionChange(): void {
    const cached = appStore.getCachedProfile(this.targetUid)
    if (cached) {
      this.profile = cached
      this.isLoading = false
      this.hasError = false
    }
  }

  private navigateProfile(uid: string): void {
    this.onClose()
    routerStore.navigateActivity(Screen.profile(uid))
  }

  private navigateAuthorPosts(uid: string, name: string, searchpost: boolean): void {
    this.onClose()
    routerStore.navigateActivity(Screen.topicList(
      name + (searchpost ? '的回帖' : '的主题'), -1, uid, '', searchpost ? '1' : ''
    ))
  }

  private joinForumNames(forums: AdminForumsData[]): string {
    const names: string[] = []
    for (let i = 0; i < forums.length; i++) {
      names.push(forums[i].forumName)
    }
    return names.join(', ')
  }

  private joinTitleHonor(title: string, honor: string): string {
    const parts: string[] = []
    if (title && title.length > 0) parts.push(title)
    if (honor && honor.length > 0) parts.push(honor)
    return parts.join(' · ')
  }

  build() {
    Column() {
      if (this.isLoading) {
        this.LoadingContent()
      } else if (this.hasError) {
        this.ErrorContent()
      } else if (this.profile) {
        this.ProfileContent(this.profile!)
      }
    }
    .width(280)
    .backgroundColor(AppColors.bg)
    .borderRadius(14)
    .shadow({ radius: 16, color: AppColors.shadowLight, offsetY: 4 })
    .clip(true)
  }

  @Builder
  LoadingContent() {
    Column() {
      LoadingProgress().width(20).height(20).color(AppColors.textTertiary)
      Text('加载中...').fontSize(14).fontColor(AppColors.textTertiary).margin({ top: 8 })
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ErrorContent() {
    Column() {
      Text('获取用户信息失败').fontSize(14).fontColor(AppColors.textTertiary)
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ProfileContent(profile: ProfileData) {
    Column() {
      Row() {
        Avatar({ avatar: profile.avatarUrl, uid: profile.uid, name: profile.userName, avatarSize: 50 })

        Column() {
          Row() {
            Text(unescapeHtml(profile.userName))
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor(AppColors.textPrimary)
            if (profile.group && profile.group.length > 0) {
              Text(unescapeHtml(profile.group))
                .fontSize(10).fontColor(AppColors.textSecondary)
                .backgroundColor(AppColors.bgSecondary).borderRadius(4)
                .padding({ left: 5, right: 5, top: 2, bottom: 2 }).margin({ left: 6 })
            }
            if (profile.muteTime && profile.muteTime.length > 0) {
              Text('禁言中')
                .fontSize(10).fontColor(AppColors.white)
                .backgroundColor(AppColors.destructive).borderRadius(4)
                .padding({ left: 5, right: 5, top: 2, bottom: 2 }).margin({ left: 4 })
            }
          }
          .alignItems(VerticalAlign.Center)

          if (profile.title || profile.honor) {
            Text(unescapeHtml(this.joinTitleHonor(profile.title, profile.honor)))
              .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 3 })
          }

          Text(`UID: ${escHtml(profile.uid)}`)
            .fontSize(11).fontColor(AppColors.textTertiary).margin({ top: 3 })

          if (appStore.getNote(profile.uid).length > 0) {
            Text('备注: ' + appStore.getNote(profile.uid))
              .fontSize(11).fontColor(AppColors.warning).margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })
      .alignItems(VerticalAlign.Center)

      if (Number(profile.posts) || Number(profile.fame) || Number(profile.rvrc) || Number(profile.money)) {
        Row() {
          if (Number(profile.posts)) {
            this.StatItem(fmtNum(profile.posts), '发帖')
          }
          if (Number(profile.fame)) {
            this.StatItem(fmtNum(profile.fame), '威望')
          }
          if (Number(profile.rvrc)) {
            this.StatItem(fmtNum(profile.rvrc), 'RVRC')
          }
          if (Number(profile.money)) {
            this.StatItem(fmtNum(profile.money), '金钱')
          }
        }
        .width('100%')
        .backgroundColor(AppColors.bgSecondary)
        .borderRadius(8)
        .padding(6)
        .margin({ top: 12 })
      }

      Column() {
        this.DetailRows(profile)

        if (profile.sign && profile.sign.length > 0) {
          Text(unescapeHtml(profile.sign))
            .fontSize(12).fontColor(AppColors.textTertiary)
            .margin({ top: 8 })
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
      }
      .padding({ left: 16, right: 16 })
      .width('100%')

      Row() {
        Text('主题').fontSize(12).fontColor(AppColors.primary).layoutWeight(1).textAlign(TextAlign.Center)
          .padding({ top: 10, bottom: 10 })
          .onClick(() => this.navigateAuthorPosts(profile.uid, profile.userName, false))
        Divider().vertical(true).height(16).alignSelf(ItemAlign.Center).color(AppColors.separator)
        Text('回帖').fontSize(12).fontColor(AppColors.primary).layoutWeight(1).textAlign(TextAlign.Center)
          .padding({ top: 10, bottom: 10 })
          .onClick(() => this.navigateAuthorPosts(profile.uid, profile.userName, true))
        Divider().vertical(true).height(16).alignSelf(ItemAlign.Center).color(AppColors.separator)
        Text(appStore.getNote(profile.uid).length > 0 ? '编辑备注' : '备注')
          .fontSize(12)
          .fontColor(AppColors.primary)
          .layoutWeight(1).textAlign(TextAlign.Center)
          .padding({ top: 10, bottom: 10 })
          .onClick(() => { this.showNoteDialog() })
        Divider().vertical(true).height(16).alignSelf(ItemAlign.Center).color(AppColors.separator)
        Text(this.analysisMode === 'loading' ? '分析中...' : '查成分')
          .fontSize(12)
          .fontColor(this.analysisMode === 'loading' ? AppColors.textTertiary : AppColors.primary)
          .layoutWeight(1).textAlign(TextAlign.Center)
          .padding({ top: 10, bottom: 10 })
          .onClick(() => {
            if (this.analysisMode === 'idle') {
              this.startAnalysis()
            }
          })
        Divider().vertical(true).height(16).alignSelf(ItemAlign.Center).color(AppColors.separator)
        Text(appStore.settings.blacklist.some(e => e.userId === profile.uid) ? '取消屏蔽' : '屏蔽')
          .fontSize(12)
          .fontColor(appStore.settings.blacklist.some(e => e.userId === profile.uid) ? AppColors.textPrimary : AppColors.destructive)
          .layoutWeight(1).textAlign(TextAlign.Center)
          .padding({ top: 10, bottom: 10 })
          .onClick(() => {
            if (appStore.settings.blacklist.some(e => e.userId === profile.uid)) {
              appStore.removeBlacklist(profile.uid)
              appStore.showToast('已取消屏蔽')
            } else {
              appStore.addBlacklist({
                userId: profile.uid,
                nickName: profile.userName || `User${profile.uid}`
              })
              appStore.showToast('已加入黑名单')
            }
          })
      }
      .width('100%')
      .border({ width: { top: 0.5 }, color: AppColors.separator })
      .margin({ top: 8 })

      if (this.analysisMode === 'loading') {
        Row() {
          LoadingProgress().width(16).height(16).color(AppColors.primary)
          Text('正在获取发言记录...').fontSize(12).fontColor(AppColors.textSecondary).margin({ left: 8 })
        }
        .width('100%')
        .padding(12)
        .justifyContent(FlexAlign.Center)
        .border({ width: { top: 0.5 }, color: AppColors.separator })
      } else if (this.analysisMode === 'ready') {
        this.AnalysisContent()
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ bottom: 0 })
  }

  @Builder
  StatItem(value: string, label: string) {
    Column() {
      Text(value).fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary)
      Text(label).fontSize(10).fontColor(AppColors.textTertiary).margin({ top: 1 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  DetailRows(profile: ProfileData) {
    Column() {
      if (profile.regdate) {
        this.DetailRow('注册日期', formatTime(Number(profile.regdate)))
      }
      if (profile.ipLoc) {
        this.DetailRow('IP属地', profile.ipLoc)
      }
      if (profile.followByNum && Number(profile.followByNum) > 0) {
        this.DetailRow('被关注', profile.followByNum)
      }
      if (profile.adminForums && profile.adminForums.length > 0) {
        this.DetailRow('管理版面', this.joinForumNames(profile.adminForums))
      }
    }
    .width('100%')
    .margin({ top: 4 })
  }

  @Builder
  DetailRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(12).fontColor(AppColors.textSecondary)
      Text(unescapeHtml(value)).fontSize(12).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium)
        .layoutWeight(1).textAlign(TextAlign.End).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 5, bottom: 5 })
  }

  @Builder
  AnalysisContent() {
    Column() {
      Divider().color(AppColors.separator)
      Text('账号成分分析').fontSize(13).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Bold)
        .margin({ top: 8, bottom: 6 }).padding({ left: 16 })

      if (this.analysisData) {
        // 活跃概况
        Row() {
          this.SummaryBadge(String(this.analysisData.topicCount), '主题')
          this.SummaryBadge(String(this.analysisData.replyCount), '回复')
          this.SummaryBadge(String(this.analysisData.totalDays) + '天', '跨度')
        }
        .width('100%')
        .padding({ left: 12, right: 12 })

        // 活跃版面
        Text('活跃版面').fontSize(12).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium)
          .margin({ top: 10, bottom: 4 }).padding({ left: 12 })
        Column() {
          ForEach(this.getTopForums(), (fs: ForumStat) => {
            this.ForumRow(fs.name, fs.topicCount + fs.replyCount,
              Math.round((fs.topicCount + fs.replyCount) / Math.max(1, this.getTotalActivity()) * 100))
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        // 时间分布
        Text('发帖时段').fontSize(12).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium)
          .margin({ top: 8, bottom: 4 }).padding({ left: 12 })
        Column() {
          this.TimeSlot('凌晨 0-6时', this.getTimeSum(0, 5))
          this.TimeSlot('上午 6-12时', this.getTimeSum(6, 11))
          this.TimeSlot('下午 12-18时', this.getTimeSum(12, 17))
          this.TimeSlot('晚上 18-24时', this.getTimeSum(18, 23))
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        // 复制按钮
        Text('复制数据')
          .fontSize(11).fontColor(AppColors.white)
          .backgroundColor(AppColors.primary)
          .borderRadius(12)
          .padding({ left: 14, right: 14, top: 5, bottom: 5 })
          .margin({ top: 10, bottom: 8, left: 16 })
          .onClick(() => {
            this.copyToClipboard(this.buildSummaryText())
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SummaryBadge(value: string, label: string) {
    Column() {
      Text(value).fontSize(14).fontWeight(FontWeight.Bold).fontColor(AppColors.primary)
      Text(label).fontSize(10).fontColor(AppColors.textTertiary).margin({ top: 1 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ForumRow(name: string, count: number, pct: number) {
    Row() {
      Text(unescapeHtml(name)).fontSize(12).fontColor(AppColors.textPrimary).layoutWeight(1)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(String(count)).fontSize(12).fontColor(AppColors.textSecondary).margin({ left: 4 })
      Row() {
        Text('').width(pct > 0 ? pct * 1.2 : 0).height(6).backgroundColor(AppColors.primary).borderRadius(3)
      }
      .width(120).height(6).backgroundColor(AppColors.bgSecondary).borderRadius(3).margin({ left: 6 })
    }
    .width('100%')
    .padding({ top: 3, bottom: 3 })
  }

  @Builder
  TimeSlot(label: string, count: number) {
    Row() {
      Text(label).fontSize(11).fontColor(AppColors.textSecondary).width(90)
      Row() {
        Text('').width(this.getBarWidth(count)).height(8).backgroundColor(AppColors.primary).borderRadius(4)
      }
      .width(80).height(8).backgroundColor(AppColors.bgSecondary).borderRadius(4)
      Text(String(count)).fontSize(11).fontColor(AppColors.textSecondary).margin({ left: 6 }).width(24)
    }
    .width('100%')
    .padding({ top: 2, bottom: 2 })
  }

  private getTopForums(): ForumStat[] {
    return this.analysisData?.forumList.slice(0, 5) ?? [];
  }

  private getTotalActivity(): number {
    return (this.analysisData?.topicCount ?? 0) + (this.analysisData?.replyCount ?? 0);
  }

  private getBarWidth(count: number): number {
    const maxVal = this.getMaxTimeSlot();
    return maxVal > 0 ? Math.round(count / maxVal * 80) : 0;
  }

  private getTimeSum(start: number, end: number): number {
    if (!this.analysisData) return 0
    let sum = 0
    for (let i = start; i <= end; i++) {
      sum += this.analysisData.hourDistribution[i] || 0
    }
    return sum
  }

  private getMaxTimeSlot(): number {
    const a = this.getTimeSum(0, 5)
    const b = this.getTimeSum(6, 11)
    const c = this.getTimeSum(12, 17)
    const d = this.getTimeSum(18, 23)
    return Math.max(a, b, c, d, 1)
  }

  private buildSummaryText(): string {
    if (!this.analysisData) return ''
    const d = this.analysisData
    let text = `${this.profile?.userName ?? ''}(UID:${this.targetUid}) 的账号分析：\n`
    text += `共 ${d.topicCount} 个主题，${d.replyCount} 条回复，时间跨度 ${d.totalDays} 天\n\n`
    text += '活跃版面：\n'
    for (let i = 0; i < d.forumList.length; i++) {
      const f = d.forumList[i]
      text += `  ${f.name}: ${f.topicCount + f.replyCount} 帖\n`
    }
    text += '\n发帖时段：\n'
    text += `  凌晨: ${this.getTimeSum(0, 5)} 帖\n`
    text += `  上午: ${this.getTimeSum(6, 11)} 帖\n`
    text += `  下午: ${this.getTimeSum(12, 17)} 帖\n`
    text += `  晚上: ${this.getTimeSum(18, 23)} 帖\n`
    if (d.topicSubjects.length > 0) {
      text += '\n发表的主题：\n'
      for (let i = 0; i < d.topicSubjects.length; i++) {
        text += `  ${i + 1}. ${d.topicSubjects[i]}\n`
      }
    }
    if (d.replySnippets.length > 0) {
      text += '\n回复内容：\n'
      for (let i = 0; i < d.replySnippets.length; i++) {
        text += `  ${i + 1}. ${d.replySnippets[i]}\n`
      }
    }
    return text
  }
}
