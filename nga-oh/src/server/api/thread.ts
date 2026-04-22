import { GET, POST } from '../router.js';
import { ngaClient } from '../nga-client.js';
import { requireAuth, parseJsonBody } from '../lib/with-auth.js';
import { extractBlacklist } from '../middleware/auth.js';
import { parseThreadData } from '../../shared/parsers/thread.js';
import { parseNgaContent, resolveAttachUrl } from '../../shared/content-parser.js';
import { parseNgaError } from '../../shared/parsers/error.js';
import { parseFromClient } from '../../shared/parsers/client.js';
import { jsonRes } from '../lib/json-res.js';

GET('/api/thread', requireAuth(async (req, res, _params, session) => {
  try {
    const url = new URL(req.url!, 'http://localhost');
    const tid = url.searchParams.get('tid');
    const pid = url.searchParams.get('pid');
    const authorid = url.searchParams.get('authorid');
    const page = url.searchParams.get('page') || '1';

    if (!tid && !pid) {
      jsonRes(res, 400, { ok: false, error: '缺少 tid 或 pid' });
      return;
    }

    const params: Record<string, string | number | undefined> = {
      page,
      __output: '8',
      noprefix: '',
      v2: '',
    };
    if (tid) params.tid = tid;
    if (pid) params.pid = pid;
    if (authorid) params.authorid = authorid;

    const blacklist = extractBlacklist(req);
    const raw = await ngaClient.get('/read.php', params, { uid: session.uid, cid: session.cid });

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    const data = parseThreadData(raw, blacklist);

    if (raw?.data?.__PAGE) {
      data.pagination.page = Number(raw.data.__PAGE);
    }

    const __U = raw?.data?.__U ?? {};
    const forumName = data.__F?.name ?? Object.values(data.__F).find(v => typeof v === 'string') ?? '';

    const posts = data.rowList.map(row => {
      const userInfo = __U[String(row.authorid)] ?? {};
      const avatar = userInfo.avatar ?? row.js_escap_avatar ?? '';
      const signature = userInfo.signature ?? row.signature ?? '';
      const username = userInfo.username ?? row.author ?? '';
      const reputation = userInfo.reputation ?? row.reputation ?? 0;
      const memberGroup = userInfo.__groupName ?? row.memberGroup ?? '';
      const level = userInfo.level ?? row.level ?? '';
      const postCount = userInfo.postCount ?? row.postCount ?? '';

      const parsedContent = parseNgaContent(row.content);
      const parsedSignature = signature ? parseNgaContent(signature) : '';

      const attachs = row.attachs.map(a => ({
        ...a,
        attachurl: resolveAttachUrl(a.attachurl),
        thumb: a.thumb ? resolveAttachUrl(a.thumb) : '',
      }));

      return {
        pid: row.pid,
        lou: row.lou,
        authorid: row.authorid,
        author: username,
        subject: row.subject,
        content: parsedContent,
        postdate: row.postdate,
        level,
        yz: row.yz,
        avatar,
        signature: parsedSignature,
        attachs,
        comments: row.comments,
        hotReplies: row.hotReplies,
        fromClient: parseFromClient(row.from_client),
        from_client_model: row.from_client_model,
        isanonymous: row.isanonymous,
        alterinfo: row.alterinfo,
        score: row.score,
        score_2: row.score_2,
        isInBlackList: row.isInBlackList,
        isMuted: row.isMuted,
        reputation,
        memberGroup,
        postCount,
        muteTime: row.muteTime,
      };
    });

    let threadInfo: any = null;
    if (raw?.data?.__T) {
      const __T = raw.data.__T;
      if (__T.tid) {
        threadInfo = __T;
      } else {
        const tKeys = Object.keys(__T);
        if (tKeys.length > 0) {
          const first = __T[tKeys[0]];
          if (first && typeof first === 'object' && first.tid) {
            threadInfo = first;
          }
        }
      }
    }

    jsonRes(res, 200, {
      ok: true,
      data: {
        threadInfo,
        forumName,
        pagination: data.pagination,
        posts,
      },
    });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '获取帖子详情失败' });
  }
}));

POST('/api/post/auth', requireAuth(async (req, res, _params, session) => {
  try {
    const body = await parseJsonBody(req);
    const { fid, action, tid, stid, pid, comment } = body;

    const qs = new URLSearchParams();
    qs.set('fid', String(fid ?? ''));
    qs.set('lite', 'js');
    if (action) qs.set('action', action);
    if (pid) qs.set('pid', String(pid));
    if (tid) qs.set('tid', String(tid));
    if (stid) qs.set('stid', String(stid));
    if (comment) qs.set('comment', String(comment));

    const raw = await ngaClient.post(
      `/post.php?${qs.toString()}`,
      {},
      { uid: session.uid, cid: session.cid }
    );

    const auth = raw?.data?.auth ?? '';
    const attachUrl = raw?.data?.attach_url ?? '';

    jsonRes(res, 200, {
      ok: true,
      data: { auth, attachUrl, if_moderator: raw?.data?.if_moderator ?? 0 },
    });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '获取auth失败' });
  }
}));

POST('/api/post/reply', requireAuth(async (req, res, _params, session) => {
  try {
    const body = await parseJsonBody(req);
    const { tid, fid, content, anony, attachments, attachmentsCheck, stid, action, pid, postSubject } = body;

    const fields: Record<string, string> = {
      step: '2',
      action: action ?? 'reply',
      fid: String(fid),
      post_content: content,
      anony: String(anony ?? 0),
      attachments: attachments ?? '',
      attachments_check: attachmentsCheck ?? '',
      __output: '8',
    };
    if (tid) fields.tid = String(tid);
    if (pid) fields.pid = String(pid);
    if (postSubject) fields.post_subject = postSubject;
    if (stid) fields.stid = String(stid);

    const raw = await ngaClient.post('/post.php', fields, { uid: session.uid, cid: session.cid });

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    jsonRes(res, 200, {
      ok: true,
      data: { tid: raw?.data?.tid ?? tid, pid: raw?.data?.pid ?? '' },
    });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '回复失败' });
  }
}));

POST('/api/post/comment', requireAuth(async (req, res, _params, session) => {
  try {
    const body = await parseJsonBody(req);
    const { tid, pid, fid, content, anony } = body;

    const fields: Record<string, string> = {
      step: '2',
      action: 'reply',
      comment: '1',
      lite: 'htmljs',
      nojump: '1',
      fid: String(fid),
      tid: String(tid),
      pid: String(pid),
      post_content: content,
      anony: String(anony ?? 0),
      __output: '8',
    };

    const raw = await ngaClient.post('/post.php', fields, { uid: session.uid, cid: session.cid });

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    jsonRes(res, 200, { ok: true });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '评论失败' });
  }
}));

POST('/api/vote', requireAuth(async (req, res, _params, session) => {
  try {
    const body = await parseJsonBody(req);
    const { value, tid, pid } = body;

    const raw = await ngaClient.post(
      '/nuke.php',
      {
        __lib: 'topic_recommend',
        __act: 'add',
        raw: '3',
        __output: '8',
        value: String(value),
        tid: String(tid),
        pid: String(pid ?? 0),
      },
      { uid: session.uid, cid: session.cid }
    );

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    jsonRes(res, 200, { ok: true });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '操作失败' });
  }
}));

POST('/api/favorite/add', requireAuth(async (req, res, _params, session) => {
  try {
    const body = await parseJsonBody(req);
    const { tid, pid } = body;

    const qs = new URLSearchParams({
      __lib: 'topic_favor',
      __act: 'topic_favor',
      lite: 'js',
      action: 'add',
      tid: String(tid),
    });
    if (pid) qs.set('pid', String(pid));

    const raw = await ngaClient.post(
      `/nuke.php?${qs.toString()}&noprefix`,
      {},
      { uid: session.uid, cid: session.cid }
    );

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    jsonRes(res, 200, { ok: true });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '收藏失败' });
  }
}));

POST('/api/favorite/remove', requireAuth(async (req, res, _params, session) => {
  try {
    const body = await parseJsonBody(req);
    const { tid, pid, page } = body;

    const raw = await ngaClient.post(
      '/nuke.php',
      {
        __lib: 'topic_favor',
        __act: 'topic_favor',
        __output: '8',
        action: 'del',
        page: String(page ?? '1'),
        tidarray: pid ? `${tid}_${pid}` : String(tid),
      },
      { uid: session.uid, cid: session.cid }
    );

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    jsonRes(res, 200, { ok: true });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '取消收藏失败' });
  }
}));

POST('/api/upload/attach', requireAuth(async (req, res, _params, session) => {
  try {
    const boundaryMatch = (req.headers['content-type'] ?? '').match(/boundary=(.+)/);
    if (!boundaryMatch) {
      jsonRes(res, 400, { ok: false, error: '无效的 multipart 请求' });
      return;
    }

    const rawBody = await new Promise<Buffer>((resolve, reject) => {
      const chunks: Buffer[] = [];
      req.on('data', (chunk) => chunks.push(chunk));
      req.on('end', () => resolve(Buffer.concat(chunks)));
      req.on('error', reject);
    });

    const boundary = boundaryMatch[1];
    const parts = parseMultipart(rawBody, boundary);

    let fileBuffer: Buffer | null = null;
    let fileName = 'upload.jpg';
    let fileContentType = 'image/jpeg';
    const formFields: Record<string, string> = {};

    for (const part of parts) {
      if (part.filename) {
        fileBuffer = part.data;
        fileName = part.filename;
        const ctMatch = part.header.match(/Content-Type:\s*(.+)/i);
        if (ctMatch) fileContentType = ctMatch[1].trim();
      } else if (part.name) {
        formFields[part.name] = part.data.toString('utf-8');
      }
    }

    if (!fileBuffer) {
      jsonRes(res, 400, { ok: false, error: '未找到附件文件' });
      return;
    }

    formFields['func'] = formFields['func'] ?? 'upload';
    formFields['v2'] = formFields['v2'] ?? '1';
    formFields['lite'] = formFields['lite'] ?? 'js';
    formFields['origin_domain'] = formFields['origin_domain'] ?? 'bbs.ngacn.cc';

    const raw = await ngaClient.uploadFile(
      fileBuffer,
      fileName,
      fileContentType,
      formFields,
      { uid: session.uid, cid: session.cid },
    );

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    jsonRes(res, 200, {
      ok: true,
      data: {
        attachments: raw?.data?.attachments ?? '',
        attachmentsCheck: raw?.data?.attachments_check ?? '',
      },
    });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '上传失败' });
  }
}));

interface MultipartPart {
  name: string;
  filename?: string;
  header: string;
  data: Buffer;
}

function parseMultipart(body: Buffer, boundary: string): MultipartPart[] {
  const parts: MultipartPart[] = [];
  const delimiter = Buffer.from(`--${boundary}`);
  let start = 0;

  while (start < body.length) {
    const delimIdx = body.indexOf(delimiter, start);
    if (delimIdx === -1) break;
    const nextDelimIdx = body.indexOf(delimiter, delimIdx + delimiter.length);
    if (nextDelimIdx === -1) break;

    const partStart = delimIdx + delimiter.length + 2;
    const partEnd = nextDelimIdx - 2;
    if (partStart >= partEnd) { start = nextDelimIdx; continue; }

    const partBuf = body.subarray(partStart, partEnd);
    const headerEnd = partBuf.indexOf('\r\n\r\n');
    if (headerEnd === -1) { start = nextDelimIdx; continue; }

    const headerStr = partBuf.subarray(0, headerEnd).toString('utf-8');
    const dataBuf = partBuf.subarray(headerEnd + 4);

    const nameMatch = headerStr.match(/name="([^"]+)"/);
    const filenameMatch = headerStr.match(/filename="([^"]+)"/);

    parts.push({
      name: nameMatch?.[1] ?? '',
      filename: filenameMatch?.[1],
      header: headerStr,
      data: dataBuf,
    });

    start = nextDelimIdx;
  }

  return parts;
}
