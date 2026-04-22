import { ServerResponse } from 'node:http';
import { GET, POST } from '../router.js';
import { requireAuth, parseJsonBody } from '../lib/with-auth.js';
import { browseHistoryStore } from '../lib/browse-history.js';
import { jsonRes } from '../lib/json-res.js';

GET('/api/browse-history', requireAuth((req, res, _params, session) => {
  const items = browseHistoryStore.get(session.uid);
  jsonRes(res, 200, { ok: true, data: items });
}));

POST('/api/browse-history/add', requireAuth(async (req, res, _params, session) => {
  try {
    const body = await parseJsonBody(req);
    const { tid, subject, author, authorid, replies, postDate, board } = body;
    if (!tid || !subject) {
      jsonRes(res, 400, { ok: false, error: '缺少 tid 或 subject' });
      return;
    }
    browseHistoryStore.add(session.uid, {
      tid, subject,
      author: author ?? '',
      authorid: authorid ?? '',
      replies: replies ?? 0,
      postDate: postDate ?? 0,
      board: board ?? '',
    });
    jsonRes(res, 200, { ok: true });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '添加失败' });
  }
}));

POST('/api/browse-history/remove', requireAuth(async (req, res, _params, session) => {
  try {
    const body = await parseJsonBody(req);
    const { tid } = body;
    if (!tid) {
      jsonRes(res, 400, { ok: false, error: '缺少 tid' });
      return;
    }
    browseHistoryStore.remove(session.uid, tid);
    jsonRes(res, 200, { ok: true });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '删除失败' });
  }
}));

POST('/api/browse-history/clear', requireAuth((_req, res, _params, session) => {
  browseHistoryStore.clear(session.uid);
  jsonRes(res, 200, { ok: true });
}));
