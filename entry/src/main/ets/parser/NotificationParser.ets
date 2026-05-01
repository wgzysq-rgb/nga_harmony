import type { NgaNotification, ReplyNotification, MessageNotification, UpvoteNotification } from '../model/Notification';

export function parseNotifications(raw: object | null): NgaNotification[] {
  const result: NgaNotification[] = [];
  const rawObj = raw as Record<string, Object>;
  const data = rawObj?.['data'] as Record<string, Object>;
  if (!data || typeof data !== 'object') return result;

  for (const categoryKey of Object.keys(data)) {
    const group = data[categoryKey] as Record<string, Object>;
    if (!group || typeof group !== 'object') continue;

    const hasUnread: boolean = Number(group['unread'] ?? 0) > 0;

    for (const batchKey of Object.keys(group)) {
      if (batchKey === 'unread' || batchKey === 'lasttime') continue;
      const batchObj: Object = group[batchKey];
      if (!Array.isArray(batchObj)) continue;
      const batch: Record<string, Object>[] = batchObj as Record<string, Object>[];

      for (const item of batch) {
        if (!item || typeof item !== 'object') continue;
        const e: Record<string, Object> = item as Record<string, Object>;

        const type: number = Number(e['0'] ?? 0);

        if (type === 10 || type === 11 || type === 12) {
          const mid: string = String(e['6'] ?? '');
          result.push({
            type: type,
            userId: String(e['1'] ?? ''),
            userName: String(e['2'] ?? ''),
            title: '',
            mid: mid,
            timeStamp: String(e['9'] ?? ''),
            unread: hasUnread,
          } as MessageNotification);
        } else if (type === 17) {
          result.push({
            type: type,
            userId: '',
            userName: '',
            toUid: String(e['3'] ?? ''),
            title: String(e['5'] ?? ''),
            tid: String(e['6'] ?? ''),
            pid: String(e['7'] ?? ''),
            timeStamp: String(e['9'] ?? ''),
            unread: hasUnread,
          } as UpvoteNotification);
        } else {
          const tid: string = String(e['6'] ?? '');
          result.push({
            type: type,
            userId: String(e['1'] ?? ''),
            userName: String(e['2'] ?? ''),
            repliedId: String(e['3'] ?? ''),
            repliedName: String(e['4'] ?? ''),
            title: String(e['5'] ?? ''),
            tid: tid,
            replyPid: String(e['7'] ?? ''),
            repliedPid: String(e['8'] ?? ''),
            timeStamp: String(e['9'] ?? ''),
            page: String(e['10'] ?? ''),
            unread: hasUnread,
          } as ReplyNotification);
        }
      }
    }
  }

  return result;
}
