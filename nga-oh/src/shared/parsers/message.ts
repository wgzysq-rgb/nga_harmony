import type { MessageListInfo, MessageThreadInfo, MessageDetailInfo, MessageArticle } from '../types/message.js';

export function parseMessageList(raw: any): MessageListInfo {
  const rows = raw?.data?.data ?? [];
  const messages: MessageThreadInfo[] = [];

  for (const key of Object.keys(rows)) {
    const r = rows[key];
    if (!r || !r.mid) continue;
    messages.push({
      mid: Number(r.mid),
      subject: r.subject ?? '',
      time: r.time ?? '',
      lasttime: r.lasttime ?? '',
      posts: Number(r.posts ?? 0),
      from_username: r.from_username ?? '',
      last_from_username: r.last_from_username ?? '',
    });
  }

  return {
    rowsPerPage: Number(raw?.data?.rowsPerPage ?? 20),
    nextPage: Number(raw?.data?.nextPage ?? 0),
    currentPage: Number(raw?.data?.currentPage ?? 1),
    messageEntryList: messages,
  };
}

export function parseMessageDetail(raw: any): MessageDetailInfo {
  const rows = raw?.data?.data ?? [];
  const articles: MessageArticle[] = [];

  for (const key of Object.keys(rows)) {
    const r = rows[key];
    if (!r) continue;
    articles.push({
      subject: r.subject ?? '',
      time: r.time ?? '',
      content: r.content ?? '',
      from: r.from ?? '',
      lou: Number(r.lou ?? 0),
      js_escap_avatar: r.js_escap_avatar ?? '',
      author: r.author ?? '',
      yz: r.yz ?? '',
      mute_time: r.mute_time ?? '',
      signature: r.signature ?? '',
      formated_html_data: r.formated_html_data ?? '',
    });
  }

  return {
    nextPage: Number(raw?.data?.nextPage ?? 0),
    currentPage: Number(raw?.data?.currentPage ?? 1),
    alluser: raw?.data?.alluser ?? '',
    title: raw?.data?.title ?? '',
    messageEntryList: articles,
  };
}
