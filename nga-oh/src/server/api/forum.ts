import { GET, POST } from '../router.js';
import { ngaClient } from '../nga-client.js';
import { requireAuth, parseJsonBody } from '../lib/with-auth.js';
import { parseForumCategories, parseForumSearch } from '../../shared/parsers/forum.js';
import { jsonRes } from '../lib/json-res.js';

GET('/api/forum/categories', requireAuth(async (_req, res, _params, session) => {
  try {
    const raw = await ngaClient.get(
      '/app_api.php',
      { __lib: 'home', __act: 'category' },
      { uid: session.uid, cid: session.cid }
    );

    const categories = parseForumCategories(raw);
    jsonRes(res, 200, { ok: true, data: categories });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '获取板块分类失败' });
  }
}));

GET('/api/forum/search', requireAuth(async (req, res, _params, session) => {
  try {
    const url = new URL(req.url!, 'http://localhost');
    const key = url.searchParams.get('key');
    if (!key) {
      jsonRes(res, 400, { ok: false, error: '缺少搜索关键词' });
      return;
    }

    const raw = await ngaClient.getWithBaseUrl(
      '/forum.php',
      { __output: '8', key },
      'https://bbs.nga.cn',
      { uid: session.uid, cid: session.cid }
    );

    const forums = parseForumSearch(raw);
    jsonRes(res, 200, { ok: true, data: forums });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '搜索失败' });
  }
}));

GET('/api/forum/favorites', requireAuth(async (_req, res, _params, session) => {
  try {
    const raw = await ngaClient.post(
      '/nuke.php',
      {
        __lib: 'forum_favor2',
        __act: 'forum_favor',
        __output: '8',
        action: 'sync',
      },
      { uid: session.uid, cid: session.cid }
    );

    const items = raw?.data?.['0'];
    if (!items || typeof items !== 'object') {
      jsonRes(res, 200, { ok: true, data: [] });
      return;
    }

    const forums = Object.values(items).map((item: any) => ({
      fid: Number(item.fid) || 0,
      stid: Number(item.id) || 0,
      name: String(item.name ?? ''),
    }));

    jsonRes(res, 200, { ok: true, data: forums });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '获取收藏板块失败' });
  }
}));

function makeForumFavorHandler(action: 'add' | 'del') {
  return requireAuth(async (req, res, _params, session) => {
    try {
      const body = await parseJsonBody(req);
      const { fid } = body;

      if (!fid) {
        jsonRes(res, 400, { ok: false, error: '缺少 fid' });
        return;
      }

      const params: Record<string, string> = {
        __lib: 'forum_favor2',
        __act: 'forum_favor',
        __output: '8',
        action,
        fid: String(fid),
      };

      const raw = await ngaClient.post('/nuke.php', params, { uid: session.uid, cid: session.cid });

      if (raw?.error) {
        jsonRes(res, 200, { ok: false, error: raw.error['0'] ?? (action === 'add' ? '添加收藏失败' : '取消收藏失败') });
        return;
      }

      jsonRes(res, 200, { ok: true });
    } catch (err: any) {
      jsonRes(res, 500, { ok: false, error: err.message ?? (action === 'add' ? '添加收藏板块失败' : '取消收藏板块失败') });
    }
  });
}

POST('/api/forum/favorite/add', makeForumFavorHandler('add'));
POST('/api/forum/favorite/remove', makeForumFavorHandler('del'));
