/**
 * Tavily 搜索 API 适配器。
 *
 * 实现 WebSearchAdapter 接口，将 Tavily API 的请求/响应
 * 适配为统一的 SearchResponse 格式。
 */

import { http } from '@kit.NetworkKit'
import { Logger, DOMAIN_SERVICE } from '../../../common/utils/Logger'
import {
  type WebSearchAdapter,
  SearchResponse,
  SearchResultItem
} from './WebSearchAdapter'

const logger = new Logger(DOMAIN_SERVICE, 'TavilyAdpt')

/** Tavily API 基础地址 */
const TAVILY_BASE_URL: string = 'https://api.tavily.com'
/** 搜索超时毫秒数 */
const SEARCH_TIMEOUT: number = 15000

/**
 * Tavily 搜索适配器。
 *
 * 封装 Tavily Search API 的 HTTP 调用逻辑，
 * 将 Tavily 返回的结构化数据转换为 SearchResponse。
 */
export class TavilySearchAdapter implements WebSearchAdapter {
  /**
   * 执行 Tavily 网页搜索。
   *
   * @param query - 搜索关键词或自然语言问题
   * @param apiKey - Tavily API 密钥
   * @returns 标准化搜索结果
   */
  async search(query: string, apiKey: string): Promise<SearchResponse> {
    const result: SearchResponse = new SearchResponse()

    if (query.trim().length === 0) {
      result.errorMessage = '搜索关键词不能为空'
      return result
    }
    if (apiKey.trim().length === 0) {
      result.errorMessage = 'Tavily API 密钥未配置'
      return result
    }

    const url: string = TAVILY_BASE_URL + '/search'
    const body: Record<string, Object> = {
      'query': query,
      'search_depth': 'basic',
      'max_results': 5,
      'include_answer': true
    }

    const httpRequest: http.HttpRequest = http.createHttp()
    try {
      const response: http.HttpResponse = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + apiKey
        },
        extraData: JSON.stringify(body),
        expectDataType: http.HttpDataType.STRING,
        readTimeout: SEARCH_TIMEOUT,
        connectTimeout: 10000
      })

      const statusCode: number = response.responseCode
      const responseText: string = (response.result as string) ?? ''

      if (statusCode !== 200) {
        result.errorMessage = 'Tavily 搜索失败: HTTP ' + statusCode
        logger.error('Tavily search failed: HTTP %{public}d', statusCode)
        return result
      }

      const json: Record<string, Object> = JSON.parse(responseText) as Record<string, Object>
      result.answer = (json['answer'] as string) ?? ''

      const rawResults: Object[] = json['results'] as Object[]
      if (rawResults) {
        for (let i = 0; i < rawResults.length; i++) {
          const raw: Record<string, Object> = rawResults[i] as Record<string, Object>
          const item: SearchResultItem = new SearchResultItem()
          item.title = (raw['title'] as string) ?? ''
          item.url = (raw['url'] as string) ?? ''
          item.content = (raw['content'] as string) ?? ''
          item.score = (raw['score'] as number) ?? 0
          result.results.push(item)
        }
      }

      result.success = true
      return result
    } catch (e) {
      const err: Error = e as Error
      result.errorMessage = 'Tavily 搜索异常: ' + (err.message || '未知错误')
      logger.error('Tavily search exception: %{public}s', result.errorMessage)
      return result
    } finally {
      httpRequest.destroy()
    }
  }
}
