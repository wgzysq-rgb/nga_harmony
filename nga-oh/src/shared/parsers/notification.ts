import type { BaseNotification, NotificationGroup } from '../types/notification.js';

export function parseNotifications(raw: any): NotificationGroup {
  const empty: NotificationGroup = { items: [], unread: 0, lasttime: 0 };
  const group = raw?.data?.['0'] ?? raw?.data;
  if (!group || typeof group !== 'object') return empty;
  if (!group || typeof group !== 'object') return empty;

  const items: BaseNotification[] = [];

  for (const subKey of Object.keys(group)) {
    if (subKey === 'unread' || subKey === 'lasttime') continue;
    const arr = group[subKey];
    if (!arr || typeof arr !== 'object') continue;

    for (const item of Object.values(arr)) {
      const e = item as any;
      if (!e || typeof e !== 'object') continue;

      items.push({
        type: e['0'] ?? 0,
        fromUid: String(e['1'] ?? ''),
        fromName: String(e['2'] ?? ''),
        toUid: String(e['3'] ?? ''),
        toName: String(e['4'] ?? ''),
        text: String(e['5'] ?? ''),
        tid: String(e['6'] ?? ''),
        pid: String(e['7'] ?? ''),
        pid2: String(e['8'] ?? ''),
        timeStamp: Number(e['9']) || 0,
        page: String(e['10'] ?? ''),
        text2: String(e['11'] ?? ''),
        text3: String(e['13'] ?? ''),
      });
    }
  }

  items.sort((a, b) => b.timeStamp - a.timeStamp);

  return {
    items,
    unread: Number(group['unread']) || 0,
    lasttime: Number(group['lasttime']) || 0,
  };
}
