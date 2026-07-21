/**
 * 社交列表类型集合：收藏版块与黑名单条目。
 *
 * 字段定义与序列化格式向后兼容。
 */

/**
 * 收藏版块条目。
 * 持久化于用户设置中，字段顺序/名称不可变更以保证向后兼容。
 */
export class FavBoard {
  fid: number = 0
  stid: number = 0
  name: string = ''
}

/**
 * 黑名单条目。
 * userId 为用户 UID 字符串，nickName 为加入时记录的昵称。
 */
export interface BlacklistEntry {
  userId: string
  nickName: string
}
