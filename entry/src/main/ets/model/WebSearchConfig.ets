/**
 * Web Search 配置数据模型。
 *
 * 定义联网搜索提供商的配置数据结构及预设。
 */

/** 搜索提供商类型标识。 */
export type WebSearchProviderType = 'tavily' | 'serpapi' | 'brave' | 'custom'

/**
 * 搜索提供商预设。
 *
 * 预定义常见搜索 API 的连接信息，
 * 用户在添加搜索提供商时可快速选择。
 */
export class WebSearchProviderPreset {
  /** 提供商类型标识 */
  id: WebSearchProviderType
  /** 显示名称 */
  name: string
  /** 描述文案 */
  description: string
  /** API Key 输入框占位符 */
  apiKeyPlaceholder: string

  /**
   * 创建搜索提供商预设。
   *
   * @param id - 提供商类型标识
   * @param name - 显示名称
   * @param description - 描述文案
   * @param apiKeyPlaceholder - API Key 占位符
   */
  constructor(
    id: WebSearchProviderType,
    name: string,
    description: string,
    apiKeyPlaceholder: string
  ) {
    this.id = id
    this.name = name
    this.description = description
    this.apiKeyPlaceholder = apiKeyPlaceholder
  }
}

/** 全网搜索提供商预设列表。 */
export const WEB_SEARCH_PROVIDER_PRESETS: WebSearchProviderPreset[] = [
  new WebSearchProviderPreset(
    'tavily',
    'Tavily',
    '专为 AI Agent 设计的搜索 API，支持深度搜索和答案摘要',
    'tvly-... 在 tavily.com 注册获取'
  ),
  new WebSearchProviderPreset(
    'serpapi',
    'SerpAPI',
    'Google 搜索结果结构化 API',
    '在 serpapi.com 注册获取'
  ),
  new WebSearchProviderPreset(
    'brave',
    'Brave Search',
    'Brave 隐私搜索引擎 API',
    '在 brave.com/search/api 注册获取'
  ),
  new WebSearchProviderPreset(
    'custom',
    '自定义',
    '自定义搜索 API 端点',
    '输入 API Key'
  )
]

/**
 * 搜索提供商配置。
 *
 * 每个配置代表一个独立的搜索 API 提供商，
 * 包含连接信息及认证凭证。
 */
export class WebSearchProviderProfile {
  /** 唯一标识（生成时赋值） */
  id: string = ''
  /** 用户命名的方案名称 */
  name: string = ''
  /** 提供商类型标识 */
  providerType: WebSearchProviderType = 'tavily'
  /** API 密钥 */
  apiKey: string = ''
  /** 自定义 API 端点（仅 providerType='custom' 时有效） */
  endpoint: string = ''
}
