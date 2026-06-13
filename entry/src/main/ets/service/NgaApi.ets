/**
 * NGA API 业务逻辑层 barrel 聚合入口
 *
 * 业务函数按域拆分至 ./api/ 子目录：
 * - AuthApi     登录/会话/凭据注入
 * - UserApi     当前用户/用户资料/用户成分分析
 * - ForumApi    版块分类/搜索/主题列表
 * - ThreadApi   帖子详情/回帖/评论/附件上传
 * - FavoriteApi 收藏/投票/签到
 * - MessageApi  通知/私信
 * - MiscApi     域名切换
 *
 * 24 个引用方继续从 `from '../service/NgaApi'` 导入，barrel 保证零改动。
 * 领域数据类已迁出至 model/ 层，请直接从 model/ 导入类型与构造器。
 */

export * from './api/AuthApi';
export * from './api/UserApi';
export * from './api/ForumApi';
export * from './api/ThreadApi';
export * from './api/FavoriteApi';
export * from './api/MessageApi';
export * from './api/MiscApi';
