export interface NotificationInfo {
  type: number;
  userId: string;
  userName: string;
  timeStamp: string;
}

export interface ReplyNotification extends NotificationInfo {
  type: number;
  repliedId: string;
  repliedName: string;
  title: string;
  tid: string;
  replyPid: string;
  repliedPid: string;
  page: string;
}

export interface MessageNotification extends NotificationInfo {
  type: number;
  mid: string;
}

export interface VoteNotification extends NotificationInfo {
  type: number;
  title: string;
  tid: string;
  pid: string;
}

export type NgaNotification = ReplyNotification | MessageNotification | VoteNotification;
