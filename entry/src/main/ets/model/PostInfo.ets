/**
 * 帖子详情页的主帖与评论数据模型。
 * PostInfo 由 ThreadParser 解析后填充，PostAttachInfo 描述帖子内联附件。
 */

/**
 * 帖子附件信息（图片/文件等内联附件）。
 */
export class PostAttachInfo {
  aid: string = '';
  attachurl: string = '';
  url_utf8_org_name: string = '';
  name: string = '';
  ext: string = '';
  type: string = '';
  size: number = 0;
  thumb: number = 0;
  thumbUrl: string = '';
  dscp: string = '';
  subid: number = 0;
}

/**
 * 单条帖子（主帖或回复/评论）。
 */
export class PostInfo {
  tid: number = 0;
  pid: number = 0;
  lou: number = 0;
  authorid: number = 0;
  author: string = '';
  subject: string = '';
  content: string = '';
  postdate: string = '';
  level: string = '';
  yz: string = '';
  avatar: string = '';
  signature: string = '';
  attachs: PostAttachInfo[] = [];
  comments: PostInfo[] = [];
  hotReplies: string[] = [];
  fromClient: string = '';
  from_client_model: string = '';
  isanonymous: boolean = false;
  alterinfo: string = '';
  score: number = 0;
  score_2: number = 0;
  isInBlackList: boolean = false;
  userNote: string = '';
  isMuted: boolean = false;
  reputation: number = 0;
  memberGroup: string = '';
  postCount: string = '';
  muteTime: string = '';
}
