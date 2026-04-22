import { ServerResponse } from 'node:http';
import { GET, POST } from '../router.js';
import { ngaClient } from '../nga-client.js';
import { requireAuth, parseJsonBody } from '../lib/with-auth.js';
import { parseNotifications } from '../../shared/parsers/notification.js';
import { parseMessageList, parseMessageDetail } from '../../shared/parsers/message.js';
import { parseNgaContent } from '../../shared/content-parser.js';
import { parseNgaError } from '../../shared/parsers/error.js';
import { jsonRes } from '../lib/json-res.js';

POST('/api/checkin', requireAuth(async (_req, res, _params, session) => {
  try {
    const raw = await ngaClient.post(
      '/nuke.php',
      { __lib: 'check_in', __act: 'check_in', lite: 'js' },
      { uid: session.uid, cid: session.cid },
    );

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    jsonRes(res, 200, { ok: true, data: raw?.data ?? {} });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '签到失败' });
  }
}));

GET('/api/notifications', requireAuth(async (_req, res, _params, session) => {
  try {
    const raw = await ngaClient.get('/nuke.php', {
      __lib: 'noti', __output: '8', __act: 'get_all', raw: '3', time_limit: '1',
    }, { uid: session.uid, cid: session.cid });

    const result = parseNotifications(raw);
    jsonRes(res, 200, { ok: true, data: result });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '获取通知失败' });
  }
}));

POST('/api/notifications/mute', requireAuth(async (req, res, _params, session) => {
  try {
    const body = await parseJsonBody(req);
    const { tid, pid } = body;
    if (!tid) {
      jsonRes(res, 400, { ok: false, error: '缺少 tid' });
      return;
    }

    const raw = await ngaClient.post('/nuke.php', {
      __lib: 'noti', __act: 'set_post_tag', __output: '3',
      no_hint: '1', tid: String(tid), pid: String(pid ?? 0),
    }, { uid: session.uid, cid: session.cid });

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    jsonRes(res, 200, { ok: true });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '屏蔽通知失败' });
  }
}));

POST('/api/notifications/clear', requireAuth(async (_req, res, _params, session) => {
  try {
    const raw = await ngaClient.post(
      '/nuke.php?__lib=noti&raw=3&__act=del',
      {},
      { uid: session.uid, cid: session.cid },
    );

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    jsonRes(res, 200, { ok: true });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '清除通知失败' });
  }
}));

GET('/api/messages', requireAuth(async (req, res, _params, session) => {
  try {
    const url = new URL(req.url!, 'http://localhost');
    const page = url.searchParams.get('page') || '1';

    const raw = await ngaClient.get('/nuke.php', {
      __lib: 'message', __act: 'message', act: 'list', page, lite: 'js',
    }, { uid: session.uid, cid: session.cid });

    const data = parseMessageList(raw);
    jsonRes(res, 200, { ok: true, data });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '获取私信列表失败' });
  }
}));

GET('/api/messages/:mid', requireAuth(async (req, res, params, session) => {
  try {
    const url = new URL(req.url!, 'http://localhost');
    const page = url.searchParams.get('page') || '1';
    const mid = params.mid;

    const raw = await ngaClient.get('/nuke.php', {
      __lib: 'message', __act: 'message', act: 'read', page, mid, lite: 'js',
    }, { uid: session.uid, cid: session.cid });

    const data = parseMessageDetail(raw);
    data.messageEntryList = data.messageEntryList.map(article => ({
      ...article,
      content: parseNgaContent(article.content),
      signature: parseNgaContent(article.signature),
    }));
    jsonRes(res, 200, { ok: true, data });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '获取私信详情失败' });
  }
}));

POST('/api/messages/send', requireAuth(async (req, res, _params, session) => {
  try {
    const body = await parseJsonBody(req);
    const { to, mid, subject, content } = body;

    if (!content) {
      jsonRes(res, 400, { ok: false, error: '内容不能为空' });
      return;
    }

    const fields: Record<string, string> = {
      __lib: 'message',
      __act: 'message',
      lite: 'js',
      act: mid ? 'reply' : 'new',
      content,
    };

    if (to) fields.to = to;
    if (mid) fields.mid = String(mid);
    if (subject) fields.subject = subject;

    const raw = await ngaClient.post(
      '/nuke.php',
      fields,
      { uid: session.uid, cid: session.cid },
    );

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    jsonRes(res, 200, { ok: true, data: { mid: raw?.data?.mid ?? mid } });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '发送私信失败' });
  }
}));

GET('/api/user/:uid', requireAuth(async (_req, res, params, session) => {
  try {
    const uid = params.uid;
    const raw = await ngaClient.get('/nuke.php', {
      __lib: 'ucp', __act: 'get', lite: 'js', noprefix: '', uid,
    }, { uid: session.uid, cid: session.cid }, {
      Referer: `https://bbs.nga.cn/nuke.php?func=ucp&lite=jsx&uid=${uid}`,
    });

    if (raw.error) {
      const errMsg = typeof raw.error === 'string' ? raw.error : raw.error['0'];
      jsonRes(res, 200, { ok: false, error: errMsg ?? '获取用户资料失败' });
      return;
    }

    const rawInner = raw.data ?? {};
    const d = rawInner['0'] ?? rawInner;
    const regTimestamp = Number(d.regdate) || 0;
    const regDateStr = regTimestamp > 0
      ? new Date(regTimestamp * 1000).toISOString().slice(0, 10)
      : '';
    const muteTime = Number(d.muteTime) || 0;
    const medalStr = String(d.medal ?? '0');
    const hasMedal = medalStr !== '0' && medalStr !== '';

    let reputationList: { name: string; value: string; desc: string }[] = [];
    if (d.reputation && typeof d.reputation === 'object') {
      for (const entry of Object.values(d.reputation) as any[]) {
        if (Array.isArray(entry)) {
          reputationList.push({ name: entry[0] ?? '', value: String(entry[1] ?? ''), desc: entry[2] ?? '' });
        }
      }
    }

    let adminForumList: { fid: string; name: string }[] = [];
    if (d.adminForums && typeof d.adminForums === 'object') {
      for (const [fid, name] of Object.entries(d.adminForums)) {
        if (typeof name === 'string') adminForumList.push({ fid, name });
      }
    }

    const profile = {
      uid: String(d.uid ?? uid),
      userName: d.username ?? '',
      avatarUrl: d.avatar ?? '',
      group: d.group ?? '',
      title: d.title ?? '',
      honor: d.honor ?? '',
      yz: d.yz ?? 0,
      money: String(d.money ?? ''),
      fame: String(d.fame ?? ''),
      rvrc: String(d.rvrc ?? ''),
      posts: String(d.posts ?? ''),
      regdate: regDateStr,
      sign: d.sign ?? '',
      ipLoc: d.ipLoc ?? '',
      medal: hasMedal ? medalStr : '',
      muteTime: muteTime > 0 ? new Date(muteTime * 1000).toISOString().slice(0, 16) : '',
      followByNum: String(d.follow_by_num ?? ''),
      adminForums: adminForumList,
      reputationEntryList: reputationList,
    };

    jsonRes(res, 200, { ok: true, data: profile });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '获取用户资料失败' });
  }
}));

POST('/api/settings/domain', requireAuth(async (req, res, _params, _session) => {
  try {
    const body = await parseJsonBody(req);
    const { index } = body;

    const DOMAINS = [
      'https://bbs.nga.cn',
      'https://ngabbs.com',
      'https://nga.178.com',
    ];

    if (typeof index !== 'number' || index < 0 || index >= DOMAINS.length) {
      jsonRes(res, 400, { ok: false, error: '无效域名索引' });
      return;
    }

    ngaClient.setActiveDomainIndex(index);
    jsonRes(res, 200, { ok: true, data: { domain: DOMAINS[index] } });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '切换域名失败' });
  }
}));
