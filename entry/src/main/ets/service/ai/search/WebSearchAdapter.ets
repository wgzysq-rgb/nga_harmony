/**
 * 联网搜索适配器接口。
 *
 * 定义搜索提供商的统一契约，各提供商实现此接口进行适配。
 * 同时导出搜索相关的公共类型。
 */

/** 单条搜索结果。 */
export class SearchResultItem {
  /** 标题 */
  title: string = ''
  /** 链接 */
  url: string = ''
  /** 内容摘要 */
  content: string = ''
  /** 相关性评分（0~1） */
  score: number = 0
}

/** 搜索响应。 */
export class SearchResponse {
  /** AI 生成的答案摘要 */
  answer: string = ''
  /** 搜索结果列表 */
  results: SearchResultItem[] = []
  /** 是否成功 */
  success: boolean = false
  /** 错误信息 */
  errorMessage: string = ''
}

/**
 * 联网搜索适配器接口。
 *
 * 每个搜索 API 提供商实现此接口，
 * 将各自的请求/响应格式适配为统一的 SearchResponse。
 */
export interface WebSearchAdapter {
  /**
   * 执行网页搜索。
   *
   * @param query - 搜索关键词或自然语言问题
   * @param apiKey - 提供商 API 密钥
   * @returns 标准化搜索结果
   */
  search(query: string, apiKey: string): Promise<SearchResponse>
}
