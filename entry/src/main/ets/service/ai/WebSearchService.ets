/**
 * 联网搜索服务门面。
 *
 * 作为搜索的统一入口，根据当前激活的搜索提供商配置
 * 自动选择对应的适配器执行搜索。
 */

import { appStore } from '../../store/AppStore'
import {
  type WebSearchAdapter,
  SearchResponse,
  SearchResultItem
} from './search/WebSearchAdapter'
import { TavilySearchAdapter } from './search/TavilySearchAdapter'
import type { WebSearchProviderProfile, WebSearchProviderType } from '../../model/WebSearchConfig'
import { Logger, DOMAIN_SERVICE } from '../../common/utils/Logger'

const logger = new Logger(DOMAIN_SERVICE, 'WebSearchSvc')

// 重新导出公共类型，保持调用方引用不变
export { SearchResponse, SearchResultItem } from './search/WebSearchAdapter'

/** 适配器缓存，按 providerType 存储实例避免重复创建。 */
const adapterCache: Record<string, WebSearchAdapter> = {}

/**
 * 获取当前激活的搜索提供商配置。
 *
 * @returns 激活的配置，若未选择或配置不存在则返回 null
 */
export function getActiveWebSearchProfile(): WebSearchProviderProfile | null {
  return appStore.getActiveWebSearchProfile()
}

/**
 * 根据提供商类型获取对应的适配器实例。
 *
 * @param providerType - 提供商类型标识
 * @returns 适配器实例，若类型不支持则返回 null
 */
function getAdapter(providerType: WebSearchProviderType): WebSearchAdapter | null {
  if (adapterCache[providerType]) {
    return adapterCache[providerType]
  }
  switch (providerType) {
    case 'tavily':
      adapterCache[providerType] = new TavilySearchAdapter()
      return adapterCache[providerType]
    default:
      logger.warn('Unsupported web search provider: %{public}s', providerType)
      return null
  }
}

/**
 * 执行联网搜索。
 *
 * 根据当前激活的搜索提供商配置自动选择适配器执行搜索，
 * 若未激活任何搜索配置则返回失败。
 *
 * @param query - 搜索关键词或自然语言问题
 * @returns 标准化搜索结果
 */
export async function searchWeb(query: string): Promise<SearchResponse> {
  const profile: WebSearchProviderProfile | null = getActiveWebSearchProfile()
  const errorResult: SearchResponse = new SearchResponse()

  if (!profile) {
    errorResult.errorMessage = '未激活联网搜索配置'
    return errorResult
  }

  const adapter: WebSearchAdapter | null = getAdapter(profile.providerType)
  if (!adapter) {
    errorResult.errorMessage = '不支持的搜索提供商: ' + profile.providerType
    return errorResult
  }

  return adapter.search(query, profile.apiKey)
}

/**
 * 将搜索结果构造成适合模型阅读的上下文字符串。
 *
 * @param searchResponse - 搜索结果
 * @returns 模型可读的搜索结果上下文
 */
export function buildSearchContext(searchResponse: SearchResponse): string {
  let context: string = ''

  if (searchResponse.answer.length > 0) {
    context += '搜索摘要：' + searchResponse.answer + '\n\n'
  }

  context += '搜索结果：\n'
  for (let i: number = 0; i < searchResponse.results.length; i++) {
    const item: SearchResultItem = searchResponse.results[i]
    context += (i + 1).toString() + '. [' + item.title + '](' + item.url + ')\n'
    if (item.content.length > 0) {
      context += '   ' + item.content + '\n'
    }
    context += '\n'
  }

  context += '请仅基于以上搜索结果回答用户问题，并标注引用来源；如果搜索结果不足以确认结论，请明确说明无法确认。'
  return context
}
