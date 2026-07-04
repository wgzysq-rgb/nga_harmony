/**
 * AI 提供方预设数据。
 *
 * 提供流行 AI 服务商的端点地址和默认模型，
 * 降低用户手动输入配置的门槛。
 */

/** AI 服务商预设 */
export class AiProviderPreset {
  /** 服务商标识 */
  id: string
  /** 服务商名称 */
  name: string
  /** OpenAI 兼容端点地址 */
  endpoint: string
  /** 默认模型名称 */
  defaultModelName: string
  /** 是否支持通过 OpenAI 兼容接口获取模型列表 */
  supportsModelList: boolean
  /** 一句话说明 */
  description: string
  /** API Key 格式提示文本，用作输入框占位符 */
  apiKeyPlaceholder: string

  /**
   * 创建 AI 服务商预设。
   *
   * @param id - 服务商标识
   * @param name - 服务商名称
   * @param endpoint - OpenAI 兼容端点地址
   * @param defaultModelName - 默认模型名称
   * @param supportsModelList - 是否支持获取模型列表
   * @param description - 一句话说明
   * @param apiKeyPlaceholder - API Key 格式提示
   */
  constructor(
    id: string,
    name: string,
    endpoint: string,
    defaultModelName: string,
    supportsModelList: boolean,
    description: string,
    apiKeyPlaceholder: string
  ) {
    this.id = id
    this.name = name
    this.endpoint = endpoint
    this.defaultModelName = defaultModelName
    this.supportsModelList = supportsModelList
    this.description = description
    this.apiKeyPlaceholder = apiKeyPlaceholder
  }
}

/** 预设 AI 服务商列表 */
export const PROVIDER_PRESETS: AiProviderPreset[] = [
  new AiProviderPreset('deepseek', 'DeepSeek', 'https://api.deepseek.com', 'deepseek-v4-flash', true, '国产高性价比大模型', 'sk-...'),
  new AiProviderPreset('zhipu', '智谱 GLM', 'https://open.bigmodel.cn/api/paas/v4', 'glm-5.2', false, '清华系大模型', 'xxxxxxxx...xxxxxxxx.xxxxxxxxxxxxxxxx'),
  new AiProviderPreset('doubao', '豆包', 'https://ark.cn-beijing.volces.com/api/v3', 'doubao-seed-2-1-pro-260628', false, '火山方舟大模型', 'ark_... 或 AKID...'),
  new AiProviderPreset('minimax', 'MiniMax', 'https://api.minimaxi.com/v1', 'MiniMax-M3', true, '长上下文与 Agent 场景', 'mm-... 或从控制台获取'),
  new AiProviderPreset('moonshot', 'Kimi', 'https://api.moonshot.cn/v1', 'kimi-k2.6', false, '长文本处理能力强', 'sk-...'),
  new AiProviderPreset('openai', 'OpenAI', 'https://api.openai.com/v1', 'gpt-4o-mini', true, '全球领先的大模型', 'sk-...'),
  new AiProviderPreset('custom', '自定义', '', '', true, '手动输入端点地址', '请输入 API Key')
]
