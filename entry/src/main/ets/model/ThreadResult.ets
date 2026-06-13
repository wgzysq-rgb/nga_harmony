/**
 * 帖子详情（getThread/getThreadHtml）的返回结果模型。
 * 包含帖子分页信息、主题元数据与帖子列表，以及发帖鉴权与回复结果。
 */
import { ApiResult } from './NgaApiResults';
import type { ThreadInfo } from './Thread';
import type { PostInfo } from './PostInfo';

/**
 * 帖子分页信息。
 */
export class ThreadPagination {
  page: number = 1;
  totalPages: number = 0;
  totalRows: number = 0;
}

/**
 * 帖子详情结果。
 */
export class ThreadResult extends ApiResult {
  threadInfo: ThreadInfo | null = null;
  forumName: string = '';
  pagination: ThreadPagination = new ThreadPagination();
  posts: PostInfo[] = [];
}

/**
 * 发帖/回复鉴权结果。
 */
export class PostAuthResult extends ApiResult {
  auth: string = '';
  attachUrl: string = '';
  if_moderator: number = 0;
}

/**
 * 发帖/回复/评论提交结果。
 */
export class PostReplyResult extends ApiResult {
  tid: number = 0;
  pid: string = '';
}
