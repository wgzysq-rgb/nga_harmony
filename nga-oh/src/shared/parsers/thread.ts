import type { ThreadData, ThreadRowInfo, Attachment } from '../types/thread.js';

export function parseThreadData(raw: any, blacklist: Set<string> = new Set()): ThreadData {
  const rowList: ThreadRowInfo[] = [];
  const rawRows = raw?.data?.__R ?? {};
  const totalRows = raw?.data?.__ROWS ?? 0;
  const rowsPerPage = raw?.data?.__R__ROWS_PAGE ?? 20;

  for (const key of Object.keys(rawRows)) {
    const r = rawRows[key];
    if (!r || r.pid === undefined || r.pid === null) continue;
    if (blacklist.has(String(r.authorid))) continue;
    rowList.push(mapRow(r, blacklist));
  }

  const actualTotalRows = totalRows > 0 ? totalRows : rowList.length;
  return {
    rowList,
    threadInfo: null,
    __F: raw?.data?.__F ?? {},
    __ROWS: totalRows,
    rowNum: totalRows,
    pagination: {
      page: 1,
      totalPages: Math.ceil(actualTotalRows / rowsPerPage),
      totalRows,
    },
  };
}

function mapRow(raw: any, blacklist: Set<string>): ThreadRowInfo {
  const attachs: Attachment[] = [];
  if (raw.attachs && typeof raw.attachs === 'object') {
    for (const [, val] of Object.entries(raw.attachs)) {
      const a = val as any;
      attachs.push({
        aid: String(a.aid ?? ''),
        attachurl: String(a.attachurl ?? ''),
        url_utf8_org_name: String(a.url_utf8_org_name ?? ''),
        name: String(a.name ?? ''),
        ext: String(a.ext ?? ''),
        type: String(a.type ?? ''),
        size: Number(a.size) || 0,
        thumb: String(a.thumb ?? ''),
        dscp: String(a.dscp ?? ''),
        subid: Number(a.subid) || 0,
      });
    }
  }

  const comments: ThreadRowInfo[] = [];
  if (raw.comments && Array.isArray(raw.comments)) {
    for (const c of raw.comments) {
      if (!blacklist.has(String(c.authorid))) {
        comments.push(mapRow(c, blacklist));
      }
    }
  }

  return {
    tid: raw.tid ?? 0,
    fid: raw.fid ?? 0,
    pid: raw.pid ?? 0,
    lou: raw.lou ?? 0,
    authorid: Number(raw.authorid) || 0,
    author: raw.author ?? '',
    subject: raw.subject ?? '',
    content: raw.content ?? '',
    vote: raw.vote ?? '',
    postdate: String(raw.postdate ?? ''),
    attachs,
    level: raw.level ?? '',
    yz: raw.yz ?? '',
    js_escap_avatar: raw.js_escap_avatar ?? '',
    muteTime: raw.mute_time ?? '',
    aurvrc: raw.aurvrc ?? 0,
    signature: raw.signature ?? '',
    comments,
    hotReplies: raw.hotReplies ?? [],
    from_client: raw.from_client ?? '',
    from_client_model: raw.from_client_model ?? '',
    isanonymous: !!raw.isanonymous,
    alterinfo: raw.alterinfo ?? '',
    score: raw.score ?? 0,
    score_2: raw.score_2 ?? 0,
    isInBlackList: false,
    userNote: '',
    imageUrlList: raw.imageUrlList ?? [],
    formattedHtmlData: raw.formattedHtmlData ?? '',
    isMuted: !!raw.mute_time,
    postCount: raw.postCount ?? '',
    reputation: raw.reputation ?? 0,
    memberGroup: raw.memberGroup ?? '',
  };
}
