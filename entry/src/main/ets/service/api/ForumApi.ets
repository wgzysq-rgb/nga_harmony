/**
 * NGA 版块 API - 版块分类、版块搜索、主题列表
 */

import { ngaClient } from '../NgaClient';
import { appStore } from '../../store/AppStore';
import { parseForumCategories } from '../../parser/ForumParser';
import { parseTopicList } from '../../parser/TopicParser';
import { parseNgaError } from '../../parser/ErrorParser';
import { CategoriesResult, TopicListResult, SearchForumResult } from '../../model/NgaApiResults';

// ============== 版块分类 ==============

export async function getForumCategories(token: string): Promise<CategoriesResult> {
  const result = new CategoriesResult();
  const session = appStore.getSession(token);
  if (!session) {
    result.error = '未登录';
    return result;
  }

  try {
    const params: Record<string, string> = { '__lib': 'home', '__act': 'category' };
    const raw = await ngaClient.get('/app_api.php', params, { uid: session.uid, cid: session.cid });
    result.data = parseForumCategories(raw as object);
    result.ok = true;
  } catch (e) {
    result.error = (e as Error).message ?? '获取板块分类失败';
  }
  return result;
}

export async function searchForum(token: string, key: string): Promise<SearchForumResult> {
  const result = new SearchForumResult();
  const session = appStore.getSession(token);
  if (!session) {
    result.error = '未登录';
    return result;
  }

  try {
    const params: Record<string, string> = { '__output': '8', 'key': key };
    result.data = await ngaClient.getWithBaseUrl('/forum.php', params, 'http://bbs.nga.cn', { uid: session.uid, cid: session.cid });
    result.ok = true;
  } catch (e) {
    result.error = (e as Error).message ?? '搜索失败';
  }
  return result;
}

// ============== 帖子列表 ==============

export interface TopicListParams {
  fid: string;
  stid: string;
  page: string;
  key: string;
  author: string;
  authorid: string;
  favor: string;
  recommend: string;
  twentyfour: string;
  searchpost: string;
  content: string;
  fidgroup: string;
}

export function createTopicListParams(): TopicListParams {
  return {
    fid: '', stid: '', page: '1', key: '', author: '', authorid: '',
    favor: '', recommend: '', twentyfour: '', searchpost: '', content: '', fidgroup: '',
  };
}

export async function getTopicList(token: string, params: TopicListParams,
  blacklist: Set<string> = new Set(),
  keywords: string[] = []): Promise<TopicListResult> {
  const result = new TopicListResult();
  const session = appStore.getSession(token);
  if (!session) {
    result.error = '未登录';
    return result;
  }

  try {
    const ngaParams: Record<string, string> = {
      'page': params.page || '1',
      'lite': 'js',
      'noprefix': '',
    };

    if (params.authorid) ngaParams['authorid'] = params.authorid;
    if (params.searchpost) ngaParams['searchpost'] = params.searchpost;
    if (params.favor) ngaParams['favor'] = params.favor;
    if (params.content) ngaParams['content'] = params.content;

    if (params.author) {
      ngaParams['author'] = params.author;
    } else {
      if (params.stid) ngaParams['stid'] = params.stid;
      else if (params.fid && params.fid !== '-1') ngaParams['fid'] = params.fid;
      if (params.key) ngaParams['key'] = params.key;
      if (params.fidgroup) ngaParams['fidgroup'] = params.fidgroup;
    }

    if (params.recommend) {
      ngaParams['recommend'] = params.recommend;
      ngaParams['order_by'] = 'postdatedesc';
      ngaParams['user'] = '1';
    }

    const raw = await ngaClient.get('/thread.php', ngaParams, { uid: session.uid, cid: session.cid }) as Record<string, Object>;
    const error = parseNgaError(raw);
    if (error) {
      result.error = error;
      return result;
    }

    const dataObj = raw?.['data'] as Record<string, Object> | undefined;
    const page = Number(dataObj?.['__PAGE'] ?? params.page ?? 1);
    result.data = parseTopicList(raw, blacklist, keywords, page);
    result.ok = true;
  } catch (e) {
    result.error = (e as Error).message ?? '获取主题列表失败';
  }
  return result;
}
