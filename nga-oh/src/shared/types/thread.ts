export interface ThreadData {
  rowList: ThreadRowInfo[];
  threadInfo: any;
  __F: Record<string, string>;
  __ROWS: number;
  rowNum: number;
  pagination: {
    page: number;
    totalPages: number;
    totalRows: number;
  };
}

export interface Post {
  pid: string;
  lou: number;
  authorid: string;
  author: string;
  subject: string;
  content: string;
  postdate: number;
  level: number;
  avatar: string;
  signature: string;
  attachs: PostAttachment[];
  comments: PostComment[];
  fromClient: string;
  from_client_model?: string;
  isanonymous: number;
  alterinfo: string;
  score: number;
  score_2?: number;
  isInBlackList: boolean;
  isMuted: boolean;
  reputation: number;
  memberGroup: string;
  postCount: number;
  tid?: string;
  muteTime?: string;
}

export interface PostAttachment {
  attachurl: string;
  thumb: string;
  [key: string]: any;
}

export interface PostComment {
  author: string;
  authorid: string;
  content: string;
}

export interface ThreadInfo {
  tid: string;
  fid: string;
  subject: string;
  author: string;
  authorid: string;
  replies: number;
  type: string;
  authoravatar?: string;
}

export interface ThreadPageData {
  threadInfo: ThreadInfo | null;
  forumName: string;
  pagination: {
    totalPages: number;
    totalRows: number;
  };
  posts: Post[];
}

export interface ThreadRowInfo {
  tid: number;
  fid: number;
  pid: number;
  lou: number;
  authorid: number;
  author: string;
  subject: string;
  content: string;
  vote: string;
  postdate: string;
  attachs: Attachment[];
  level: string;
  yz: string;
  js_escap_avatar: string;
  muteTime: string;
  aurvrc: number;
  signature: string;
  comments: ThreadRowInfo[];
  hotReplies: string[];
  from_client: string;
  from_client_model: string;
  isanonymous: boolean;
  alterinfo: string;
  score: number;
  score_2: number;
  isInBlackList: boolean;
  userNote: string;
  imageUrlList: string[];
  formattedHtmlData: string;
  isMuted: boolean;
  postCount: string;
  reputation: number;
  memberGroup: string;
}

export interface Attachment {
  aid: string;
  attachurl: string;
  url_utf8_org_name: string;
  name: string;
  ext: string;
  type: string;
  size: number;
  thumb: string;
  dscp: string;
  subid: number;
}
