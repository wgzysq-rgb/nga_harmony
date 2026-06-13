/**
 * 私信模块（getMessageList/getMessageDetail/sendMessage）的返回结果模型。
 */
import type { MessageListInfo, MessageDetailInfo } from './Message';
import { ApiResult } from './NgaApiResults';

/**
 * 私信列表结果。
 */
export class MessageListResult extends ApiResult {
  data: MessageListInfo | null = null;
}

/**
 * 私信详情结果。
 */
export class MessageDetailResult extends ApiResult {
  data: MessageDetailInfo | null = null;
}

/**
 * 发送私信结果。
 */
export class MessageSendResult extends ApiResult {
  mid: string = '';
}
