/**
 * AI 提供方和模型预设数据。
 *
 * 提供流行 AI 服务商的端点地址预设及常用模型列表，
 * 降低用户手动输入端点地址的门槛。
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

  /**
   * 创建 AI 服务商预设。
   *
   * @param id - 服务商标识
   * @param name - 服务商名称
   * @param endpoint - OpenAI 兼容端点地址
   * @param defaultModelName - 默认模型名称
   * @param supportsModelList - 是否支持获取模型列表
   * @param description - 一句话说明
   */
  constructor(
    id: string,
    name: string,
    endpoint: string,
    defaultModelName: string,
    supportsModelList: boolean,
    description: string
  ) {
    this.id = id
    this.name = name
    this.endpoint = endpoint
    this.defaultModelName = defaultModelName
    this.supportsModelList = supportsModelList
    this.description = description
  }
}

/** AI 模型预设 */
export class AiModelPreset {
  /** 模型名称 */
  modelName: string
  /** 用途说明 */
  description: string
  /** 所属服务商 ID */
  providerId: string

  /**
   * 创建 AI 模型预设。
   *
   * @param modelName - 模型名称
   * @param description - 用途说明
   * @param providerId - 所属服务商 ID
   */
  constructor(modelName: string, description: string, providerId: string) {
    this.modelName = modelName
    this.description = description
    this.providerId = providerId
  }
}

/** 预设 AI 服务商列表 */
export const PROVIDER_PRESETS: AiProviderPreset[] = [
  new AiProviderPreset('deepseek', 'DeepSeek', 'https://api.deepseek.com', 'deepseek-v4-flash', true, '国产高性价比大模型'),
  new AiProviderPreset('zhipu', '智谱 GLM', 'https://open.bigmodel.cn/api/paas/v4', 'glm-5.2', false, '清华系大模型'),
  new AiProviderPreset('doubao', '豆包', 'https://ark.cn-beijing.volces.com/api/v3', 'doubao-seed-2-1-pro-260628', false, '火山方舟大模型'),
  new AiProviderPreset('minimax', 'MiniMax', 'https://api.minimaxi.com/v1', 'MiniMax-M3', true, '长上下文与 Agent 场景'),
  new AiProviderPreset('moonshot', 'Kimi', 'https://api.moonshot.cn/v1', 'kimi-k2.6', false, '长文本处理能力强'),
  new AiProviderPreset('openai', 'OpenAI', 'https://api.openai.com/v1', 'gpt-4o-mini', true, '全球领先的大模型'),
  new AiProviderPreset('custom', '自定义', '', '', true, '手动输入端点地址')
]

/** 预设模型列表 */
export const MODEL_PRESETS: AiModelPreset[] = [
  new AiModelPreset('deepseek-v4-flash', '快速通用 - 日常任务首选', 'deepseek'),
  new AiModelPreset('deepseek-v4-pro', '旗舰推理 - 复杂分析场景', 'deepseek'),
  new AiModelPreset('glm-5.2', '旗舰通用 - 适合复杂分析', 'zhipu'),
  new AiModelPreset('glm-5.1', '稳定通用 - 日常任务', 'zhipu'),
  new AiModelPreset('doubao-seed-2-1-pro-260628', '旗舰通用 - 复杂分析与推理', 'doubao'),
  new AiModelPreset('doubao-seed-2-1-turbo-260628', '快速通用 - 日常任务', 'doubao'),
  new AiModelPreset('MiniMax-M3', '长上下文 - Agent 与代码任务', 'minimax'),
  new AiModelPreset('MiniMax-M2.7', '高性能 - 长上下文任务', 'minimax'),
  new AiModelPreset('kimi-k2.6', '长文本 - 中文优化', 'moonshot'),
  new AiModelPreset('kimi-k2.7-code', '代码与 Agent 任务', 'moonshot'),
  new AiModelPreset('gpt-4o', '通用多模态 - 支持图片理解', 'openai'),
  new AiModelPreset('gpt-4o-mini', '轻量快速 - 日常任务首选', 'openai')
]

/**
 * 根据服务商 ID 获取对应的模型预设列表。
 *
 * @param providerId - 服务商标识
 * @returns 该服务商的模型预设列表
 */
export function getModelsByProvider(providerId: string): AiModelPreset[] {
  const result: AiModelPreset[] = []
  for (let i = 0; i < MODEL_PRESETS.length; i++) {
    if (MODEL_PRESETS[i].providerId === providerId) {
      result.push(MODEL_PRESETS[i])
    }
  }
  return result
}
