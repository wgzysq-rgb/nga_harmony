import { FilterListManager } from '../../FilterListManager'
import { SettingsContext } from '../SettingsContext'
import { SettingsState } from '../SettingsState'
import type { UserNoteEntry } from '../../../model/NoteInfo'

/**
 * 用户便签设置域子 store。
 *
 * 承载 notes 列表（UserNoteEntry）的增删改查，提供按 userId 查询与批量映射。
 */
export class NoteSettings {
  private ctx: SettingsContext
  private manager: FilterListManager<UserNoteEntry> = new FilterListManager<UserNoteEntry>()

  constructor(ctx: SettingsContext) {
    this.ctx = ctx
  }

  addOrUpdateNote(userId: string, nickName: string, note: string): void {
    const existing: UserNoteEntry | undefined = this.ctx.state.notes.find(
      (n: UserNoteEntry) => n.userId === userId)
    if (existing) {
      existing.note = note
      existing.nickName = nickName
    } else {
      this.ctx.state.notes = this.manager.add({ userId, nickName, note })
    }
    this.ctx.persist()
  }

  removeNote(userId: string): void {
    this.ctx.state.notes = this.manager.remove((n: UserNoteEntry) => n.userId === userId)
    this.ctx.persist()
  }

  removeAllNotes(): void {
    this.ctx.state.notes = this.manager.clear()
    this.ctx.persist()
  }

  getNote(userId: string): string {
    const entry: UserNoteEntry | undefined = this.ctx.state.notes.find(
      (n: UserNoteEntry) => n.userId === userId)
    return entry?.note ?? ''
  }

  getNoteMap(): Record<string, string> {
    const map: Record<string, string> = {}
    for (let i = 0; i < this.ctx.state.notes.length; i++) {
      map[this.ctx.state.notes[i].userId] = this.ctx.state.notes[i].note
    }
    return map
  }

  /** 从持久化对象加载便签列表（回填 FilterListManager） */
  load(saved: SettingsState): void {
    if (saved.notes) {
      this.ctx.state.notes = saved.notes
      this.manager.init(saved.notes)
    }
  }

  /** 重置便签列表与 manager */
  reset(): void {
    this.manager = new FilterListManager<UserNoteEntry>()
  }
}
