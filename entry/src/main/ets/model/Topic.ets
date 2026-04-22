export interface TopicListInfo {
  name: string;
  threadPageList: ThreadPageInfo[];
  subBoardList: object[];
  curTime: number;
  pagination: Pagination;
}

export interface ThreadPageInfo {
  tid: number;
  fid: number;
  author: string;
  authorId: number;
  lastPoster: string;
  replies: number;
  subject: string;
  titleFont: string;
  type: number;
  topicMisc: string;
  page: number;
  pid: number;
  position: number;
  isAnonymity: boolean;
  postDate: number;
  replyInfo: ReplyInfo;
  board: string;
  mirrorBoard: boolean;
  previewSnippet?: string;
  previewImages?: string[];
}

export interface ReplyInfo {
  pidStr: string;
  content: string;
  subject: string;
  postDate: string;
  authorId: string;
  tidStr: string;
}

export interface TopicRaw {
  tid: number;
  fid: number;
  quote_from: number;
  quote_to: string;
  topic_misc: string;
  author: string;
  authorid: string;
  subject: string;
  type: number;
  postdate: number;
  lastpost: number;
  lastposter: string;
  replies: number;
  lastmodify: number;
  recommend: number;
  titlefont: string;
  admin_ui: number;
  tpcurl: string;
  parent: Record<string, string>;
  topic_misc_var: Record<string, number>;
  __P?: TopicQuoteInfo;
}

export interface TopicQuoteInfo {
  tid: number;
  pid: number;
  authorid: string;
  type: number;
  postdate: number;
  subject: string;
  content: string;
}

export interface Pagination {
  page: number;
  totalPages: number;
  totalRows: number;
}
