import { ServerResponse } from 'node:http';
import { GET } from '../router.js';
import { ngaClient } from '../nga-client.js';
import { requireAuth } from '../lib/with-auth.js';
import { extractBlacklist } from '../middleware/auth.js';
import { parseTopicList } from '../../shared/parsers/topic.js';
import { parseNgaError } from '../../shared/parsers/error.js';
import { jsonRes } from '../lib/json-res.js';

function resolveRawUrl(attachurl: string): string {
  if (!attachurl) return '';
  if (attachurl.startsWith('http')) return attachurl;
  if (/^[\d]+$/.test(attachurl) || !attachurl.includes('/')) return '';
  return `https://img.nga.178.com/attachments/${attachurl}`;
}

function extractSnippet(content: string): string {
  let text = content;
  text = text.replace(/\[img\][^\[]*\[\/img\]/gi, '');
  text = text.replace(/\[\/?(?:pid|uid|tid|quote|collapse|code|b|i|u|del|h|item|l|r|color|size|font|url|list|align|table|tr|td|style|collapse|flash|lessernuke|album|hip|comment|randomblock|dice|s)\d*[^\]]*\]/gi, '');
  text = text.replace(/\[@\d+\]/g, '');
  text = text.replace(/Post by [^\n]*/gi, '');
  text = text.replace(/\[s:\w+:\w+\]/g, '');
  text = text.replace(/\.?\/mon_\S+\.(?:jpg|jpeg|png|gif|webp|bmp)/gi, '');
  text = text.replace(/https?:\/\/\S+\.(?:jpg|jpeg|png|gif|webp|bmp)\S*/gi, '');
  text = text.replace(/<[^>]+>/g, '');
  text = text.replace(/&\w+;/g, ' ');
  text = text.replace(/\s+/g, ' ').trim();
  return text.slice(0, 150);
}

function extractImageUrls(content: string): string[] {
  const images: string[] = [];
  const imgRe = /\[img\]\.?(\/?[^\]]+?)\[\/img\]/gi;
  let m;
  while ((m = imgRe.exec(content)) !== null && images.length < 3) {
    let u = m[1];
    if (u.startsWith('/mon_') || u.startsWith('mon_')) {
      u = `https://img.nga.178.com/attachments/${u.startsWith('/') ? u : '/' + u}`;
    }
    if (!u.startsWith('http')) u = `https://img.nga.178.com/attachments/${u}`;
    images.push(resolveRawUrl(u));
  }
  return images;
}

GET('/api/topics', requireAuth(async (req, res, _params, session) => {

  try {
    const url = new URL(req.url!, 'http://localhost');
    const fid = url.searchParams.get('fid');
    const stid = url.searchParams.get('stid');
    const page = url.searchParams.get('page') || '1';
    const key = url.searchParams.get('key');
    const author = url.searchParams.get('author');
    const authorid = url.searchParams.get('authorid');
    const favor = url.searchParams.get('favor');
    const recommend = url.searchParams.get('recommend');
    const twentyfour = url.searchParams.get('twentyfour');
    const searchpost = url.searchParams.get('searchpost');
    const contentParam = url.searchParams.get('content');
    const fidgroup = url.searchParams.get('fidgroup');

    const params: Record<string, string | number | undefined> = {
      page,
      lite: 'js',
      noprefix: '',
    };

    if (authorid) params.authorid = authorid;
    if (searchpost) params.searchpost = searchpost;
    if (favor) params.favor = favor;
    if (contentParam) params.content = contentParam;

    if (author) {
      params.author = author;
    } else {
      if (stid) params.stid = stid;
      else if (fid && fid !== '-1') params.fid = fid;
      if (key) params.key = key;
      if (fidgroup) params.fidgroup = fidgroup;
    }

    if (twentyfour) params.twentyfour = twentyfour;
    if (recommend) {
      params.recommend = recommend;
      params.order_by = 'postdatedesc';
      params.user = '1';
    }

    const blacklist = extractBlacklist(req);
    const raw = await ngaClient.get('/thread.php', params, { uid: session.uid, cid: session.cid });

    const error = parseNgaError(raw);
    if (error) {
      jsonRes(res, 200, { ok: false, error });
      return;
    }

    const data = parseTopicList(raw, blacklist, Number(raw?.data?.__PAGE ?? page), !!searchpost);

    for (const topic of data.threadPageList) {
      const content = topic.replyInfo?.content;
      if (content) {
        topic.previewSnippet = extractSnippet(content);
        topic.previewImages = extractImageUrls(content);
      }
    }

    jsonRes(res, 200, { ok: true, data });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '获取主题列表失败' });
  }
}));
