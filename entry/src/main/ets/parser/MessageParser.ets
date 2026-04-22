import type { MessageListInfo, MessageThreadInfo, MessageDetailInfo, MessageArticle } from '../model/Message';

export function parseMessageList(raw: object | null): MessageListInfo {
  const rawObj = raw as Record<string, Object>;
  const dataObj = rawObj?.['data'] as Record<string, Object>;
  const rows = (dataObj?.['data'] ?? {}) as Record<string, Object>;
  const messages: MessageThreadInfo[] = [];

  const keys = Object.keys(rows);
  for (let i = 0; i < keys.length; i++) {
    const r = rows[keys[i]] as Record<string, Object>;
    if (!r || !r['mid']) continue;
    const msg: MessageThreadInfo = {
      mid: Number(r['mid']),
      subject: String(r['subject'] ?? ''),
      time: String(r['time'] ?? ''),
      lasttime: String(r['lasttime'] ?? ''),
      posts: Number(r['posts'] ?? 0),
      from_username: String(r['from_username'] ?? ''),
      last_from_username: String(r['last_from_username'] ?? ''),
    };
    messages.push(msg);
  }

  const result: MessageListInfo = {
    rowsPerPage: Number(dataObj?.['rowsPerPage'] ?? 20),
    nextPage: Number(dataObj?.['nextPage'] ?? 0),
    currentPage: Number(dataObj?.['currentPage'] ?? 1),
    messageEntryList: messages,
  };
  return result;
}

export function parseMessageDetail(raw: object | null): MessageDetailInfo {
  const rawObj = raw as Record<string, Object>;
  const dataObj = rawObj?.['data'] as Record<string, Object>;
  const rows = (dataObj?.['data'] ?? {}) as Record<string, Object>;
  const articles: MessageArticle[] = [];

  const keys = Object.keys(rows);
  for (let i = 0; i < keys.length; i++) {
    const r = rows[keys[i]] as Record<string, Object>;
    if (!r) continue;
    const article: MessageArticle = {
      subject: String(r['subject'] ?? ''),
      time: String(r['time'] ?? ''),
      content: String(r['content'] ?? ''),
      from: String(r['from'] ?? ''),
      lou: Number(r['lou'] ?? 0),
      js_escap_avatar: String(r['js_escap_avatar'] ?? ''),
      author: String(r['author'] ?? ''),
      yz: String(r['yz'] ?? ''),
      mute_time: String(r['mute_time'] ?? ''),
      signature: String(r['signature'] ?? ''),
      formated_html_data: String(r['formated_html_data'] ?? ''),
    };
    articles.push(article);
  }

  const result: MessageDetailInfo = {
    nextPage: Number(dataObj?.['nextPage'] ?? 0),
    currentPage: Number(dataObj?.['currentPage'] ?? 1),
    alluser: String(dataObj?.['alluser'] ?? ''),
    title: String(dataObj?.['title'] ?? ''),
    messageEntryList: articles,
  };
  return result;
}
