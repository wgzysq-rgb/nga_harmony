/**
 * NGA 用户 API - 当前用户、用户资料、用户成分分析
 */

import { ngaClient } from '../NgaClient';
import { appStore } from '../../store/AppStore';
import {
  CurrentUserResult, UserProfileResult, UserActivityAnalysis, ForumStat,
} from '../../model/NgaApiResults';
import { UserInfo } from '../../model/UserInfo';
import { ProfileData, ReputationData, AdminForumsData } from '../../model/User';

// ============== 当前用户 ==============

export async function getCurrentUser(token: string): Promise<CurrentUserResult> {
  const result = new CurrentUserResult();
  const session = appStore.getSession(token);
  if (!session) {
    result.error = '会话不存在';
    return result;
  }

  try {
    const params: Record<string, string> = {
      '__lib': 'ucp', '__act': 'get', 'lite': 'js', 'noprefix': '', 'uid': session.uid,
    };
    const raw = await ngaClient.get('/nuke.php', params, { uid: session.uid, cid: session.cid }) as Record<string, Object>;
    const data = raw?.['data'] as Record<string, Object> | undefined;
    const d = (data?.['0'] ?? data) as Record<string, Object> | undefined;

    const nickName = String(d?.['username'] ?? session.nickName);
    const avatarUrl = String(d?.['avatar'] ?? session.avatarUrl);

    await appStore.updateSession(token, nickName, avatarUrl);

    const user = new UserInfo();
    user.uid = session.uid;
    user.nickName = nickName;
    user.avatarUrl = avatarUrl;
    result.ok = true;
    result.user = user;
  } catch (e) {
    const user = new UserInfo();
    user.uid = session.uid;
    user.nickName = session.nickName;
    user.avatarUrl = session.avatarUrl;
    result.ok = true;
    result.user = user;
  }
  return result;
}

// ============== 用户资料 ==============

export async function getUserProfile(token: string, uid: string): Promise<UserProfileResult> {
  const result = new UserProfileResult();
  const session = appStore.getSession(token);
  if (!session) {
    result.error = '未登录';
    return result;
  }

  try {
    const params: Record<string, string> = {
      '__lib': 'ucp', '__act': 'get', 'lite': 'js', 'noprefix': '', 'uid': uid,
    };
    const extraHeaders: Record<string, string> = {
      'Referer': `https://bbs.nga.cn/nuke.php?func=ucp&lite=jsx&uid=${uid}`,
    };
    const raw = await ngaClient.get('/nuke.php', params, { uid: session.uid, cid: session.cid }, extraHeaders) as Record<string, Object>;

    const errorObj = raw?.['error'];
    if (errorObj) {
      const errMsg = typeof errorObj === 'string' ? String(errorObj) :
        String((errorObj as Record<string, Object>)['0']);
      result.error = errMsg || '获取用户资料失败';
      return result;
    }

    const rawInner = (raw?.['data'] ?? {}) as Record<string, Object>;
    const d = (rawInner['0'] ?? rawInner) as Record<string, Object>;
    const regTimestamp = Number(d['regdate']) || 0;
    const muteTime = Number(d['muteTime']) || 0;
    const medalStr = String(d['medal'] ?? '0');
    const hasMedal = medalStr !== '0' && medalStr !== '';

    const repList: ReputationData[] = [];
    if (d['reputation'] && typeof d['reputation'] === 'object') {
      const repObj = d['reputation'] as Record<string, Object>;
      const repKeys = Object.keys(repObj);
      for (let i = 0; i < repKeys.length; i++) {
        const entry = repObj[repKeys[i]];
        if (Array.isArray(entry)) {
          const arr = entry as Object[];
          const repItem = new ReputationData();
          repItem.name = String(arr[0] ?? '');
          repItem.value = String(arr[1] ?? '');
          repItem.reputation = Number(arr[2] ?? 0);
          repItem.topicSubject = String(arr[3] ?? '');
          repItem.postContent = String(arr[4] ?? '');
          repItem.author = String(arr[5] ?? '');
          repItem.time = Number(arr[6] ?? 0);
          repList.push(repItem);
        }
      }
    }

    const adminList: AdminForumsData[] = [];
    if (d['adminForums'] && typeof d['adminForums'] === 'object') {
      const forums = d['adminForums'] as Record<string, Object>;
      const fKeys = Object.keys(forums);
      for (let i = 0; i < fKeys.length; i++) {
        const name = forums[fKeys[i]];
        if (typeof name === 'string') {
          const item = new AdminForumsData();
          item.fid = fKeys[i];
          item.forumName = String(name);
          adminList.push(item);
        }
      }
    }

    const profile = new ProfileData();
    profile.uid = String(d['uid'] ?? uid);
    profile.userName = String(d['username'] ?? '');
    profile.avatarUrl = String(d['avatar'] ?? '');
    profile.group = String(d['group'] ?? '');
    profile.title = String(d['title'] ?? '');
    profile.honor = String(d['honor'] ?? '');
    profile.yz = Number(d['yz'] ?? 0);
    profile.money = String(d['money'] ?? '');
    profile.fame = String(d['fame'] ?? '');
    profile.rvrc = String(d['rvrc'] ?? '');
    profile.posts = String(d['posts'] ?? '');
    profile.regdate = regTimestamp > 0 ? String(regTimestamp) : '';
    profile.sign = String(d['sign'] ?? '');
    profile.ipLoc = String(d['ipLoc'] ?? '');
    profile.medal = hasMedal ? medalStr : '';
    profile.muteTime = muteTime > 0 ? new Date(muteTime * 1000).toISOString().slice(0, 16) : '';
    profile.followByNum = String(d['follow_by_num'] ?? '');
    profile.adminForums = adminList;
    profile.reputationEntryList = repList;

    result.data = profile;
    result.ok = true;
  } catch (e) {
    result.error = (e as Error).message ?? '获取用户资料失败';
  }
  return result;
}

// ============== 用户成分分析 ==============

export async function getUserActivityAnalysis(token: string, uid: string): Promise<UserActivityAnalysis | null> {
  const result = new UserActivityAnalysis();
  const hourDist: number[] = [];
  for (let i = 0; i < 24; i++) hourDist.push(0);
  result.hourDistribution = hourDist;

  const forumMap: Record<string, ForumStat> = {};

  const addToForum = (name: string, isTopic: boolean): void => {
    let n = name;
    if (!n || n.length === 0) n = '未知';
    if (!forumMap[n]) {
      const fs = new ForumStat();
      fs.name = n;
      forumMap[n] = fs;
    }
    if (isTopic) forumMap[n].topicCount++;
    else forumMap[n].replyCount++;
  };

  const extractHour = (ts: number): void => {
    if (ts <= 0) return;
    const d = new Date(ts > 1e12 ? ts : ts * 1000);
    const h = d.getHours();
    if (h >= 0 && h < 24) result.hourDistribution[h]++;
  };

  const fmtDT = (ts: number): string => {
    if (ts <= 0) return '';
    const d = new Date(ts > 1e12 ? ts : ts * 1000);
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    const hour = String(d.getHours()).padStart(2, '0');
    const min = String(d.getMinutes()).padStart(2, '0');
    return `${month}-${day} ${hour}:${min}`;
  };

  const extractForumName = (raw: Record<string, Object>): string => {
    const parent = raw['parent'] as Record<string, Object> | undefined;
    if (parent && parent['2']) return String(parent['2']);
    return '';
  };

  const session = appStore.getSession(token);
  if (!session) return null;

  try {
    const topicParams: Record<string, string> = {
      'page': '1', 'lite': 'js', 'noprefix': '', 'authorid': uid,
    };
    const topicRaw = await ngaClient.get('/thread.php', topicParams, { uid: session.uid, cid: session.cid }) as Record<string, Object>;
    const tData = (topicRaw['data'] as Record<string, Object> | undefined)?.['__T'] as Record<string, Object> | undefined;
    if (tData) {
      const tKeys = Object.keys(tData);
      for (let i = 0; i < tKeys.length; i++) {
        const entry = tData[tKeys[i]] as Record<string, Object>;
        const subject = String(entry['subject'] ?? '');
        const entryAuthorId = Number(entry['authorid'] ?? 0);
        if (!entry['tid'] || entryAuthorId === 0) continue;
        if (subject.includes('帖子发布或回复时间超过限制') || subject.includes('帐号权限不足')) continue;
        result.topicCount++;
        result.topicSubjects.push(subject + ' (' + fmtDT(Number(entry['postdate'] ?? 0)) + ')');
        addToForum(extractForumName(entry), true);
        extractHour(Number(entry['postdate'] ?? 0));
      }
    }

    const replyParams: Record<string, string> = {
      'page': '1', 'lite': 'js', 'noprefix': '', 'authorid': uid, 'searchpost': '1',
    };
    const replyRaw = await ngaClient.get('/thread.php', replyParams, { uid: session.uid, cid: session.cid }) as Record<string, Object>;
    const rData = (replyRaw['data'] as Record<string, Object> | undefined)?.['__T'] as Record<string, Object> | undefined;
    if (rData) {
      const rKeys = Object.keys(rData);
      for (let i = 0; i < rKeys.length; i++) {
        const entry = rData[rKeys[i]] as Record<string, Object>;
        const subject = String(entry['subject'] ?? '');
        const entryAuthorId = Number(entry['authorid'] ?? 0);
        if (!entry['tid'] || entryAuthorId === 0) continue;
        if (subject.includes('帖子发布或回复时间超过限制') || subject.includes('帐号权限不足')) continue;
        result.replyCount++;
        addToForum(extractForumName(entry), false);
        const pData = entry['__P'] as Record<string, Object> | undefined;
        if (pData && pData['content']) {
          let rc: string = String(pData['content']);
          rc = rc.replace(/\[quote\][\s\S]*?\[\/quote\]/gi, '');
          rc = rc.replace(/\[\/?(?:pid|uid|tid|b|i|u|del|h|url|color|size|font|collapse|code)\d*[^\]]*\]/gi, '');
          rc = rc.replace(/\[s:\w+:\w+\]/g, '');
          rc = rc.replace(/<[^>]+>/g, '');
          rc = rc.replace(/https?:\/\/\S+/g, '');
          rc = rc.replace(/\s+/g, ' ').trim();
          if (rc.length > 0) {
            const replyTs = Number(pData?.['postdate'] ?? 0);
            result.replySnippets.push('回复于《' + subject + '》(' + fmtDT(replyTs) + '): ' + rc.slice(0, 200));
          }
        }
        const replyTs = Number(pData?.['postdate'] ?? 0);
        if (replyTs > 0) {
          extractHour(replyTs);
        }
      }
    }

    const fList: ForumStat[] = [];
    const fKeys = Object.keys(forumMap);
    for (let i = 0; i < fKeys.length; i++) {
      fList.push(forumMap[fKeys[i]]);
    }
    fList.sort((a, b) => (b.topicCount + b.replyCount) - (a.topicCount + a.replyCount));
    result.forumList = fList;

    return result;
  } catch (e) {
    return null;
  }
}
