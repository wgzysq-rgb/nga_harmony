export enum NotiType {
  ReplyTopic = 1,
  ReplyReply = 2,
  CommentTopic = 3,
  CommentReply = 4,
  KeywordWatchTopic = 5,
  KeywordWatchReply = 6,
  MentionTopic = 7,
  MentionReply = 8,
  IpChange = 9,
  MessageNew = 10,
  MessageReply = 11,
  MessageAdd = 12,
  ReportTopic = 13,
  ReportReply = 14,
  RecommendPost = 15,
  KeywordWatch = 16,
  Upvote = 17,
}

export interface BaseNotification {
  type: NotiType
  fromUid: string
  fromName: string
  toUid: string
  toName: string
  text: string
  tid: string
  pid: string
  pid2: string
  timeStamp: number
  page: string
  text2: string
  text3: string
}

export interface NotificationGroup {
  items: BaseNotification[]
  unread: number
  lasttime: number
}

export interface NotificationData {
  items: BaseNotification[]
  unread: number
  lasttime: number
}

export type NgaNotification = BaseNotification
