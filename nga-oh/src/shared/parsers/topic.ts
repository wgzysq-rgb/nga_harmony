import type { TopicRaw, ThreadPageInfo, TopicListInfo } from '../types/topic.js';

export function parseTopicList(raw: any, blacklist: Set<string> = new Set(), currentPage: number = 1, isSearchPost: boolean = false): TopicListInfo {
  const topics: ThreadPageInfo[] = [];
  const tMap = raw?.data?.__T ?? {};
  let totalRows: number = Number(raw?.data?.__ROWS) || 0;
  const rRowsPerPage = raw?.data?.__R__ROWS_PAGE;
  const tRowsPerPage = raw?.data?.__T__ROWS_PAGE ?? 35;
  const rowsPerPage = isSearchPost ? (rRowsPerPage ?? 20) : tRowsPerPage;

  for (const key of Object.keys(tMap)) {
    const t = tMap[key];
    if (!t || !t.tid) continue;
    if (blacklist.has(String(t.authorid))) continue;
    topics.push(mapTopicRaw(t));
  }

  if (!totalRows && topics.length > 0) {
    if (topics.length < rowsPerPage) {
      totalRows = (currentPage - 1) * rowsPerPage + topics.length;
    } else {
      totalRows = currentPage * rowsPerPage + 1;
    }
  }

  return {
    name: raw?.data?.__F?.name ?? '',
    threadPageList: topics,
    subBoardList: [],
    curTime: raw?.time ?? 0,
    pagination: calcPagination(totalRows, rowsPerPage, currentPage),
  };
}

function mapTopicRaw(raw: TopicRaw): ThreadPageInfo {
  return {
    tid: raw.tid,
    fid: raw.fid,
    author: raw.author,
    authorId: Number(raw.authorid),
    lastPoster: raw.lastposter,
    replies: raw.replies,
    subject: raw.subject,
    titleFont: Number(raw.titlefont) || 0,
    type: raw.type,
    topicMisc: raw.topic_misc,
    page: 0,
    pid: 0,
    position: 0,
    isAnonymity: false,
    postDate: raw.postdate,
    replyInfo: raw.__P
      ? {
          pidStr: String(raw.__P.pid),
          content: raw.__P.content ?? '',
          subject: raw.__P.subject ?? '',
          postDate: String(raw.__P.postdate),
          authorId: raw.__P.authorid ?? '',
          tidStr: String(raw.__P.tid),
        }
      : {
          pidStr: '',
          content: '',
          subject: '',
          postDate: '',
          authorId: '',
          tidStr: '',
        },
    board: raw.parent?.['2'] ?? '',
    mirrorBoard: false,
    previewSnippet: '',
    previewImages: [],
  };
}

function calcPagination(totalRows: number, rowsPerPage: number, currentPage: number) {
  return {
    page: currentPage,
    totalPages: Math.ceil(totalRows / rowsPerPage),
    totalRows,
  };
}
