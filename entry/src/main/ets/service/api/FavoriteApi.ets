/**
 * NGA 收藏/投票/签到 API
 */

import { ngaClient } from '../NgaClient';
import { appStore } from '../../store/AppStore';
import { parseNgaError } from '../../parser/ErrorParser';
import {
  ApiResult, VoteResult, CheckinResult, FavBoardItem, ForumFavoritesResult,
} from '../../model/NgaApiResults';

// ============== 版块收藏 ==============

export async function fetchForumFavorites(token: string): Promise<ForumFavoritesResult> {
  const result = new ForumFavoritesResult()
  const session = appStore.getSession(token)
  if (!session) {
    result.error = '未登录'
    return result
  }
  try {
    const fields: Record<string, string> = {
      '__lib': 'forum_favor2',
      '__act': 'forum_favor',
      '__output': '8',
      'action': 'sync',
    }
    const raw = await ngaClient.post('/nuke.php', fields, { uid: session.uid, cid: session.cid }) as Record<string, Object>
    const data = raw?.['data'] as Record<string, Object> | undefined
    const items = data?.['0'] as Record<string, Object> | undefined
    if (items && typeof items === 'object') {
      const keys = Object.keys(items)
      const forums: FavBoardItem[] = []
      for (const key of keys) {
        const item = items[key] as Record<string, Object>
        forums.push({
          fid: Number(item['fid']) || 0,
          stid: Number(item['id']) || 0,
          name: String(item['name'] ?? ''),
        })
      }
      result.data = forums
    }
    result.ok = true
  } catch (e) {
    result.error = (e as Error).message ?? '获取收藏板块失败'
  }
  return result
}

// ============== 投票 ==============

export async function votePost(token: string, tid: number, pid: number, value: number): Promise<VoteResult> {
  const result = new VoteResult();
  const session = appStore.getSession(token);
  if (!session) {
    result.error = '未登录';
    return result;
  }
  try {
    const fields: Record<string, string> = {
      '__lib': 'topic_recommend',
      '__act': 'add',
      'raw': '3',
      '__output': '8',
      'value': String(value),
      'tid': String(tid),
      'pid': String(pid),
    };
    const raw = await ngaClient.post('/nuke.php', fields, { uid: session.uid, cid: session.cid });
    const err = parseNgaError(raw);
    if (err) {
      result.error = err;
      return result;
    }
    const rawObj = raw as Record<string, Object>;
    const dataObj = rawObj['data'] as Record<string, Object>;
    if (dataObj) {
      result.message = String(dataObj['0'] ?? '');
    }
    result.ok = true;
  } catch (e) {
    result.error = (e as Error).message ?? '操作失败';
  }
  return result;
}

// ============== 主题收藏 ==============

export async function addFavorite(token: string, tid: number, pid: number): Promise<ApiResult> {
  const result = new ApiResult();
  const session = appStore.getSession(token);
  if (!session) {
    result.error = '未登录';
    return result;
  }
  try {
    const params: Record<string, string> = {
      '__lib': 'topic_favor',
      '__act': 'topic_favor',
      'lite': 'js',
      'action': 'add',
      'tid': String(tid),
    };
    if (pid) params['pid'] = String(pid);
    await ngaClient.postWithQuery('/nuke.php?noprefix', params, { uid: session.uid, cid: session.cid });
    result.ok = true;
  } catch (e) {
    result.error = (e as Error).message ?? '收藏失败';
  }
  return result;
}

export async function removeFavorite(token: string, tid: number, pid: number, page: number): Promise<ApiResult> {
  const result = new ApiResult();
  const session = appStore.getSession(token);
  if (!session) {
    result.error = '未登录';
    return result;
  }
  try {
    const fields: Record<string, string> = {
      '__lib': 'topic_favor',
      '__act': 'topic_favor',
      '__output': '8',
      'action': 'del',
      'page': String(page || 1),
      'tidarray': pid ? `${tid}_${pid}` : String(tid),
    };
    await ngaClient.post('/nuke.php', fields, { uid: session.uid, cid: session.cid });
    result.ok = true;
  } catch (e) {
    result.error = (e as Error).message ?? '取消收藏失败';
  }
  return result;
}

// ============== 签到 ==============

export async function checkin(token: string): Promise<CheckinResult> {
  const result = new CheckinResult();
  const session = appStore.getSession(token);
  if (!session) {
    result.error = '未登录';
    return result;
  }
  try {
    const fields: Record<string, string> = { '__lib': 'check_in', '__act': 'check_in', 'lite': 'js' };
    const raw = await ngaClient.post('/nuke.php', fields, { uid: session.uid, cid: session.cid }) as Record<string, Object>;
    const error = parseNgaError(raw);
    if (error) {
      result.error = error;
      return result;
    }
    result.data = raw?.['data'] ?? null;
    result.ok = true;
  } catch (e) {
    result.error = (e as Error).message ?? '签到失败';
  }
  return result;
}
