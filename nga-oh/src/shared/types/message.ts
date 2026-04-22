export interface MessageListInfo {
  rowsPerPage: number;
  nextPage: number;
  currentPage: number;
  messageEntryList: MessageThreadInfo[];
}

export interface MessageThreadInfo {
  mid: number;
  subject: string;
  time: string;
  lasttime: string;
  posts: number;
  from_username: string;
  last_from_username: string;
}

export interface MessageListData {
  messageEntryList: MessageThreadInfo[];
  rowsPerPage?: number;
  nextPage?: number;
  currentPage?: number;
}

export interface MessageDetailInfo {
  nextPage: number;
  currentPage: number;
  alluser: string;
  title: string;
  messageEntryList: MessageArticle[];
}

export interface MessageArticle {
  subject: string;
  time: string | number;
  content: string;
  from: string;
  lou: number;
  js_escap_avatar: string;
  author: string;
  yz: string;
  mute_time: string;
  signature: string;
  formated_html_data: string;
}

export interface MessageDetailData {
  messageEntryList: MessageArticle[];
  title: string;
  nextPage?: number;
  currentPage?: number;
  alluser?: string;
}
