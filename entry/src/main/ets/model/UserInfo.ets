/**
 * 当前登录用户/认证用户的轻量信息（uid/昵称/头像）。
 * 仅承载登录链路与当前会话所需的最小字段，详细资料见 model/User 中的 ProfileData。
 */

/**
 * 用户基本信息。
 */
export class UserInfo {
  uid: string = '';
  nickName: string = '';
  avatarUrl: string = '';
}
