import { PostInfo } from '../service/NgaApi'
import type { MessageThreadInfo, MessageArticle } from '../model/Message'
import type { NotificationInfo } from '../model/Notification'
import type { BlacklistEntry } from '../store/AppStore'
import type { FavBoard } from '../store/AppStore'
import type { Category, BoardContent } from '../model/Forum'

class PostInfoDataSource implements IDataSource {
  private dataList: PostInfo[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.dataList.length
  }

  getData(index: number): PostInfo {
    return this.dataList[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  replaceAll(list: PostInfo[]): void {
    this.dataList = []
    for (let i = 0; i < list.length; i++) {
      this.dataList.push(list[i])
    }
    this.notifyReload()
  }

  appendAll(list: PostInfo[]): void {
    for (let i = 0; i < list.length; i++) {
      this.dataList.push(list[i])
    }
    this.notifyReload()
  }

  clear(): void {
    this.dataList = []
    this.notifyReload()
  }

  length(): number {
    return this.dataList.length
  }

  private notifyReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded()
    }
  }
}

class ThreadDataSource implements IDataSource {
  private dataList: object[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.dataList.length
  }

  getData(index: number): object {
    return this.dataList[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  replaceAll(list: object[]): void {
    this.dataList = []
    for (let i = 0; i < list.length; i++) {
      this.dataList.push(list[i])
    }
    this.notifyReload()
  }

  appendAll(list: object[]): void {
    for (let i = 0; i < list.length; i++) {
      this.dataList.push(list[i])
    }
    this.notifyReload()
  }

  clear(): void {
    this.dataList = []
    this.notifyReload()
  }

  length(): number {
    return this.dataList.length
  }

  private notifyReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded()
    }
  }
}

class MessageThreadDataSource implements IDataSource {
  private dataList: MessageThreadInfo[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.dataList.length
  }

  getData(index: number): MessageThreadInfo {
    return this.dataList[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  replaceAll(list: MessageThreadInfo[]): void {
    this.dataList = []
    for (let i = 0; i < list.length; i++) {
      this.dataList.push(list[i])
    }
    this.notifyReload()
  }

  clear(): void {
    this.dataList = []
    this.notifyReload()
  }

  private notifyReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded()
    }
  }
}

class MessageArticleDataSource implements IDataSource {
  private dataList: MessageArticle[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.dataList.length
  }

  getData(index: number): MessageArticle {
    return this.dataList[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  replaceAll(list: MessageArticle[]): void {
    this.dataList = []
    for (let i = 0; i < list.length; i++) {
      this.dataList.push(list[i])
    }
    this.notifyReload()
  }

  clear(): void {
    this.dataList = []
    this.notifyReload()
  }

  private notifyReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded()
    }
  }
}

class NotificationDataSource implements IDataSource {
  private dataList: NotificationInfo[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.dataList.length
  }

  getData(index: number): NotificationInfo {
    return this.dataList[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  replaceAll(list: NotificationInfo[]): void {
    this.dataList = []
    for (let i = 0; i < list.length; i++) {
      this.dataList.push(list[i])
    }
    this.notifyReload()
  }

  clear(): void {
    this.dataList = []
    this.notifyReload()
  }

  private notifyReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded()
    }
  }
}

class BlacklistDataSource implements IDataSource {
  private dataList: BlacklistEntry[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.dataList.length
  }

  getData(index: number): BlacklistEntry {
    return this.dataList[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  replaceAll(list: BlacklistEntry[]): void {
    this.dataList = []
    for (let i = 0; i < list.length; i++) {
      this.dataList.push(list[i])
    }
    this.notifyReload()
  }

  clear(): void {
    this.dataList = []
    this.notifyReload()
  }

  private notifyReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded()
    }
  }
}

class CategoryDataSource implements IDataSource {
  private dataList: Category[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.dataList.length
  }

  getData(index: number): Category {
    return this.dataList[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  replaceAll(list: Category[]): void {
    this.dataList = []
    for (let i = 0; i < list.length; i++) {
      this.dataList.push(list[i])
    }
    this.notifyReload()
  }

  clear(): void {
    this.dataList = []
    this.notifyReload()
  }

  private notifyReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded()
    }
  }
}

class HistoryItemDataSource implements IDataSource {
  private dataList: object[] = []
  private listeners: DataChangeListener[] = []

  totalCount(): number {
    return this.dataList.length
  }

  getData(index: number): object {
    return this.dataList[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  replaceAll(list: object[]): void {
    this.dataList = []
    for (let i = 0; i < list.length; i++) {
      this.dataList.push(list[i])
    }
    this.notifyReload()
  }

  clear(): void {
    this.dataList = []
    this.notifyReload()
  }

  private notifyReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded()
    }
  }
}

export { PostInfoDataSource, ThreadDataSource, MessageThreadDataSource, MessageArticleDataSource, NotificationDataSource, BlacklistDataSource, CategoryDataSource, HistoryItemDataSource }
