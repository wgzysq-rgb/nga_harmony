import { appStore } from '../store/AppStore'
import type { UserNoteEntry } from '../model/NoteInfo'
import { AppColors } from '../common/Constants'
import { escHtml, unescapeHtml } from '../common/Utils'
import { NotesDataSource } from '../common/LazyDataSource'
import { PanelNavBar } from '../common/PanelNavBar'
import { ConfirmDialog, MakeNoteDialog } from '../common/Dialogs'

@Component
export struct NotesPanel {
  @State showAddDialog: boolean = false
  @State removeTarget: UserNoteEntry | null = null
  @State editTarget: UserNoteEntry | null = null
  @State addUserName: string = ''
  @State addUid: string = ''
  @State notesCount: number = 0
  @StorageProp('statusBarHeight') statusBarHeight: number = 0
  @StorageProp('navBarHeight') navBarHeight: number = 0

  private notesDataSource: NotesDataSource = new NotesDataSource()

  noteDialogController?: CustomDialogController

  deleteDialogController?: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '删除备注',
      message: '确定要删除该用户的备注吗？',
      confirmLabel: '删除',
      destructive: true,
      onConfirm: () => {
        if (this.removeTarget) {
          appStore.removeNote(this.removeTarget.userId)
          this.refreshNotes()
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

  private showEditNote(entry: UserNoteEntry): void {
    this.editTarget = entry
    this.noteDialogController = new CustomDialogController({
      builder: MakeNoteDialog({
        userName: entry.nickName,
        uid: entry.userId,
        currentNote: entry.note,
        onConfirm: (note: string, uid: string, userName: string): void => {
          appStore.addOrUpdateNote(uid, userName, note)
          appStore.showToast('备注已保存')
          this.editTarget = null
          this.refreshNotes()
        }
      }),
      autoCancel: true,
      customStyle: true,
      alignment: DialogAlignment.Center
    })
    this.noteDialogController.open()
  }

  aboutToDisappear(): void {
    this.deleteDialogController = undefined
    this.noteDialogController = undefined
  }

  aboutToAppear(): void {
    this.refreshNotes()
  }

  private refreshNotes(): void {
    this.notesCount = appStore.settings.notes.length
    this.notesDataSource.replaceAll(appStore.settings.notes)
  }

  build() {
    Stack() {
      Column() {
        Row().width('100%').height(44 + this.statusBarHeight)

        if (this.notesCount === 0) {
          Column() {
            Image($r('app.media.icon_text_fields')).width(40).height(40).fillColor(AppColors.textTertiary).opacity(0.4)
            Text('暂无备注').fontSize(15).fontColor(AppColors.textTertiary).margin({ top: 8 })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        } else {
          Row() {
            Text('共 ' + String(this.notesCount) + ' 条备注').fontSize(13).fontColor(AppColors.textTertiary).layoutWeight(1)
            Text('删除全部').fontSize(13).fontColor(AppColors.destructive)
              .onClick(() => {
                appStore.removeAllNotes()
                this.refreshNotes()
                appStore.showToast('已清空备注')
              })
          }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

          List() {
            LazyForEach(this.notesDataSource, (entry: UserNoteEntry) => {
              ListItem() {
                Row() {
                  Stack() {
                    Image($r('app.media.icon_person')).width(20).height(20).fillColor(AppColors.textTertiary)
                  }
                  .width(40).height(40).borderRadius(20).backgroundColor(AppColors.bgSecondary)

                  Column() {
                    Text(unescapeHtml(entry.nickName)).fontSize(15).fontColor(AppColors.textPrimary)
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    if (entry.note.length > 0) {
                      Text(entry.note).fontSize(13).fontColor(AppColors.warning).margin({ top: 2 })
                        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    Text('UID: ' + escHtml(entry.userId)).fontSize(13).fontColor(AppColors.textTertiary).margin({ top: 2 })
                  }
                  .layoutWeight(1).margin({ left: 12 }).alignItems(HorizontalAlign.Start)

                  Stack() {
                    Image($r('app.media.icon_compose')).width(18).height(18).fillColor(AppColors.primary)
                  }
                  .width(36).height(36)
                  .onClick(() => { this.showEditNote(entry) })

                  Stack() {
                    Image($r('app.media.icon_delete')).width(18).height(18).fillColor(AppColors.destructive)
                  }
                  .width(36).height(36)
                  .onClick(() => {
                    this.removeTarget = entry
                    this.deleteDialogController?.open()
                  })
                }
                .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }).alignItems(VerticalAlign.Center)
              }
            }, (entry: UserNoteEntry) => entry.userId)
          }
          .width('100%').layoutWeight(1)
          .divider({ strokeWidth: 0.5, color: AppColors.separator })
        }
      }
      .width('100%').height('100%')

      PanelNavBar({ title: '用户备注', rightLabel: '+ 添加', onRightClick: (): void => { this.showAddDialog = true } })
        .width('100%').position({ x: 0, y: 0 })

      if (this.showAddDialog) {
        Column() {
        }
        .width('100%').height('100%')
        .position({ x: 0, y: 0 })
        .backgroundColor(AppColors.overlay)
        .onClick(() => { this.showAddDialog = false })

        Column() {
          Divider().width(36).height(4).borderRadius(2).color(AppColors.sheetIndicator).margin({ top: 8, bottom: 12 })
          Text('添加备注').fontSize(17).fontWeight(FontWeight.Bold).margin({ bottom: 4 })
          Text('输入用户昵称和备注内容').fontSize(13).fontColor(AppColors.textSecondary).margin({ bottom: 12 })

          TextInput({ text: this.addUserName, placeholder: '输入用户昵称' })
            .width('92%').height(44).fontSize(15).borderRadius(12)
            .backgroundColor(AppColors.bgSecondary)
            .keyboardAppearance(KeyboardAppearance.IMMERSIVE)
            .onChange((value: string) => { this.addUserName = value })

          TextInput({ text: this.addUid, placeholder: '输入用户 UID' })
            .width('92%').height(44).fontSize(15).borderRadius(12)
            .backgroundColor(AppColors.bgSecondary)
            .margin({ top: 8 })
            .keyboardAppearance(KeyboardAppearance.IMMERSIVE)
            .onChange((value: string) => { this.addUid = value })

          Button('确定添加')
            .width('92%').height(44).fontSize(16).fontColor(AppColors.white)
            .backgroundColor(AppColors.primary).borderRadius(12).margin({ top: 12, bottom: 20 })
            .enabled(this.addUid.trim().length > 0 && this.addUserName.trim().length > 0)
            .onClick(() => {
              if (this.addUid.trim() && this.addUserName.trim()) {
                appStore.addOrUpdateNote(this.addUid.trim(), this.addUserName.trim(), '')
                this.refreshNotes()
                this.addUid = ''
                this.addUserName = ''
                this.showAddDialog = false
                appStore.showToast('已添加备注')
              }
            })
        }
        .width('100%').backgroundColor(AppColors.bg)
        .borderRadius({ topLeft: 14, topRight: 14 }).alignItems(HorizontalAlign.Center)
        .padding({ bottom: this.navBarHeight })
        .position({ x: 0, y: '55%' })
      }
    }
    .width('100%').height('100%').backgroundColor(AppColors.bg)
  }
}
