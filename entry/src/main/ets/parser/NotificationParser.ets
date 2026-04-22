import type { NgaNotification, ReplyNotification, MessageNotification, VoteNotification } from '../model/Notification';

export function parseNotifications(raw: object | null): NgaNotification[] {
  const result: NgaNotification[] = [];
  const rawObj = raw as Record<string, Object>;
  const data = (rawObj?.['data'] as Record<string, Object>)?.['data'];
  if (!data || typeof data !== 'object') return result;

  const group = (data as Record<string, Object>)['0'] as Record<string, Object>;
  if (!group || typeof group !== 'object') return result;

  // 回复通知
  const replyArr = group['0'];
  if (replyArr && typeof replyArr === 'object') {
    for (const item of Object.values(replyArr as Record<string, Object>)) {
      const e = item as Record<string, Object>;
      if (!e || typeof e !== 'object') continue;
      result.push({
        type: 0,
        userId: String(e['1'] ?? ''),
        userName: String(e['2'] ?? ''),
        repliedId: String(e['3'] ?? ''),
        repliedName: String(e['4'] ?? ''),
        title: String(e['5'] ?? ''),
        tid: String(e['6'] ?? ''),
        replyPid: String(e['7'] ?? ''),
        repliedPid: String(e['8'] ?? ''),
        timeStamp: String(e['9'] ?? ''),
        page: String(e['10'] ?? ''),
      } as ReplyNotification);
    }
  }

  // 私信通知
  const msgArr = group['1'];
  if (msgArr && typeof msgArr === 'object') {
    for (const item of Object.values(msgArr as Record<string, Object>)) {
      const e = item as Record<string, Object>;
      if (!e || typeof e !== 'object') continue;
      result.push({
        type: 1,
        userId: String(e['1'] ?? ''),
        userName: String(e['2'] ?? ''),
        mid: String(e['6'] ?? ''),
        timeStamp: String(e['9'] ?? ''),
      } as MessageNotification);
    }
  }

  // 投票通知
  const voteArr = group['2'];
  if (voteArr && typeof voteArr === 'object') {
    for (const item of Object.values(voteArr as Record<string, Object>)) {
      const e = item as Record<string, Object>;
      if (!e || typeof e !== 'object') continue;
      result.push({
        type: 2,
        userId: String(e['3'] ?? ''),
        userName: '',
        title: String(e['5'] ?? ''),
        tid: String(e['6'] ?? ''),
        pid: String(e['7'] ?? ''),
        timeStamp: String(e['9'] ?? ''),
      } as VoteNotification);
    }
  }

  return result;
}
