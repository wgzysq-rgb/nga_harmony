/**
 * 自定义 AI 激活配置与调用门面。
 *
 * 统一封装当前激活的用户自定义 AI 配置校验、调用与错误文案，
 * 页面层不再直接处理配置索引或额外调用分支。
 * 支持联网搜索（Function Calling + Tavily）。
 */

import { appStore } from '../../store/AppStore'
import type { AiProviderProfile } from '../../model/AiConfig'
import {
  chatComplete,
  chatCompleteStream,
  chatCompleteWithTools,
  chatCompleteStreamToolDecision,
  ChatMessage,
  ToolCall
} from './OpenAiCompatibleClient'
import type {
  ChatStreamChunkCallback,
  ToolCallResult
} from './OpenAiCompatibleClient'
import { searchWeb, SearchResponse } from './WebSearchService'
import { translateError } from './AiErrorTranslator'
import { Logger, DOMAIN_SERVICE } from '../../common/utils/Logger'

const logger = new Logger(DOMAIN_SERVICE, 'ActiveAiSvc')
/** 联网搜索工具名称。 */
const WEB_SEARCH_TOOL_NAME: string = 'web_search'
/** 缓存已确认不支持 tools 的模型配置，避免每轮对话重复失败再降级。 */
const toolUnsupportedProfileKeys: Record<string, boolean> = {}

/** AI 处理阶段状态回调，用于 UI 展示不同阶段的提示文案。 */
export type ChatStatusCallback = (status: string) => void

/**
 * 工具调用阶段信息，用于 UI 展示工具调用的进度与详情。
 *
 * @property phase - 当前阶段: 空字符串 | analyzing | searching | compiling | complete
 * @property toolName - 工具名称（如 'web_search'）
 * @property query - 搜索关键词
 * @property resultCount - 搜索结果数量
 * @property phaseIcon - 阶段图标 emoji（预计算，避免 @Builder 内调用方法）
 * @property phaseDescription - 阶段描述文案（预计算，避免 @Builder 内调用方法）
 */
export class ToolCallInfo {
  /** 当前阶段: 空字符串 | analyzing | searching | compiling | complete */
  phase: string = 'analyzing'
  /** 工具名称 */
  toolName: string = ''
  /** 搜索关键词 */
  query: string = ''
  /** 搜索结果数量 */
  resultCount: number = 0
  /** 阶段图标 emoji（由服务层预计算） */
  phaseIcon: string = '⚡'
  /** 阶段描述文案（由服务层预计算） */
  phaseDescription: string = 'AI 正在分析是否需要搜索互联网...'
}

/** 工具调用阶段信息回调。 */
export type ToolCallCallback = (info: ToolCallInfo) => void

/**
 * 单次工具搜索执行结果。
 */
class WebSearchExecution {
  /** 对应的模型 tool call。 */
  toolCall: ToolCall
  /** 实际搜索查询。 */
  query: string
  /** Tavily 搜索响应。 */
  response: SearchResponse

  /**
   * 创建搜索执行结果。
   *
   * @param toolCall - 对应的模型 tool call
   * @param query - 实际搜索查询
   * @param response - Tavily 搜索响应
   */
  constructor(toolCall: ToolCall, query: string, response: SearchResponse) {
    this.toolCall = toolCall
    this.query = query
    this.response = response
  }
}

/**
 * 获取当前激活的自定义 AI 配置。
 *
 * @returns 当前激活配置，若未选择或配置不存在则返回 null
 */
export function getActiveAiProfile(): AiProviderProfile | null {
  return appStore.getActiveAiProfile()
}

/**
 * 获取当前自定义 AI 配置不可用时的用户提示。
 *
 * @returns 空字符串表示配置可用，否则为用户可读的错误提示
 */
export function getActiveAiValidationMessage(): string {
  const profile: AiProviderProfile | null = getActiveAiProfile()
  if (!profile) {
    if (appStore.settings.aiProfiles.length === 0) {
      return '请先在设置中添加 AI 配置'
    }
    return '请先在设置中选择 AI 配置'
  }
  if (profile.endpoint.trim().length === 0 || profile.modelName.trim().length === 0) {
    return '请先在 AI 配置中填写服务地址和模型名称'
  }
  if (profile.apiKey.trim().length === 0) {
    return '请先在 AI 配置中填写 API 密钥'
  }
  return ''
}

/**
 * 使用当前激活的自定义 AI 配置发起对话补全。
 *
 * @param messages - 对话消息列表
 * @returns 模型返回文本
 */
export async function chatCompleteWithActiveAi(messages: ChatMessage[]): Promise<string> {
  const profile: AiProviderProfile | null = getActiveAiProfile()
  const validationMessage: string = getActiveAiValidationMessage()
  if (!profile || validationMessage.length > 0) {
    throw new Error(validationMessage.length > 0 ? validationMessage : '请先在设置中选择 AI 配置')
  }
  return chatComplete(profile, messages)
}

/**
 * 使用当前激活的自定义 AI 配置发起可流式展示的对话补全。
 *
 * 当配置关闭流式输出时，自动降级为普通请求并一次性回调完整文本。
 * 当启用联网搜索时，先通过 Function Calling 判断模型是否需要搜索，
 * 若需要则调用 Tavily 获取结果后再输出最终答案。
 *
 * @param messages - 对话消息列表
 * @param onDelta - 文本增量回调
 * @param onStatus - 可选的状态更新回调，用于 UI 展示不同阶段提示
 * @param onToolCall - 可选的工具调用阶段回调
 * @returns 模型返回的完整文本
 */
export async function chatCompleteWithActiveAiStream(
  messages: ChatMessage[],
  onDelta: ChatStreamChunkCallback,
  onStatus?: ChatStatusCallback,
  onToolCall?: ToolCallCallback
): Promise<string> {
  const profile: AiProviderProfile | null = getActiveAiProfile()
  const validationMessage: string = getActiveAiValidationMessage()
  if (!profile || validationMessage.length > 0) {
    throw new Error(validationMessage.length > 0 ? validationMessage : '请先在设置中选择 AI 配置')
  }

  if (shouldUseWebSearch(profile)) {
    logger.info('启用联网搜索: model=%s', profile.modelName)
    return chatCompleteWithWebSearch(profile, messages, onDelta, onStatus, onToolCall)
  }

  return chatCompleteWithoutWebSearch(profile, messages, onDelta)
}

/**
 * 不启用联网搜索时的普通对话流程。
 *
 * @param profile - AI 提供方配置
 * @param messages - 对话消息列表
 * @param onDelta - 文本增量回调
 * @returns 模型返回的完整文本
 */
async function chatCompleteWithoutWebSearch(
  profile: AiProviderProfile,
  messages: ChatMessage[],
  onDelta: ChatStreamChunkCallback
): Promise<string> {
  if (!profile.streaming) {
    const result: string = await chatComplete(profile, messages)
    onDelta(result)
    return result
  }
  return chatCompleteStream(profile, messages, onDelta)
}

/**
 * 判断当前配置是否应进入联网搜索工具流程。
 *
 * @param profile - AI 提供方配置
 * @returns true 表示应尝试联网搜索
 */
function shouldUseWebSearch(profile: AiProviderProfile): boolean {
  return profile.enableSearch &&
    profile.tavilyApiKey.trim().length > 0 &&
    !isToolUnsupported(profile)
}

/**
 * 联网搜索对话补全流程。
 *
 * 分两阶段：
 * 1. 请求带 tools 声明，让模型决定是否需要搜索。
 * 2. 若需搜索，调用 Tavily 后再请求模型生成最终答案。
 *
 * @param profile - AI 提供方配置
 * @param messages - 对话消息列表
 * @param onDelta - 文本增量回调
 * @param onStatus - 可选的状态更新回调
 * @param onToolCall - 可选的工具调用阶段回调
 * @returns 模型返回的完整文本
 */
async function chatCompleteWithWebSearch(
  profile: AiProviderProfile,
  messages: ChatMessage[],
  onDelta: ChatStreamChunkCallback,
  onStatus?: ChatStatusCallback,
  onToolCall?: ToolCallCallback
): Promise<string> {
  const tools: Object[] = buildWebSearchTools()
  const toolCallInfo: ToolCallInfo = createToolInfo(
    'analyzing',
    '⚡',
    'AI 正在分析是否需要搜索互联网...',
    '',
    0
  )
  toolCallInfo.toolName = WEB_SEARCH_TOOL_NAME
  onToolCall?.(toolCallInfo)
  onStatus?.('⚡ AI 正在分析是否需要搜索互联网...')

  let toolResult: ToolCallResult
  let decisionText: string = ''
  try {
    if (profile.streaming) {
      toolResult = await chatCompleteStreamToolDecision(profile, messages, tools, (chunk: string): void => {
        decisionText += chunk
      })
    } else {
      toolResult = await chatCompleteWithTools(profile, messages, tools)
      decisionText = toolResult.content
    }
  } catch (e) {
    const toolErr: Error = e as Error
    if (shouldCacheToolFailure(toolErr)) {
      markToolUnsupported(profile)
    }
    logger.warn('工具决策失败，降级为普通请求: %{public}s', toolErr.message ?? '')
    notifyNoToolCall(onToolCall)
    onStatus?.('AI 正在生成回答...')
    try {
      return await chatCompleteWithoutWebSearch(profile, messages, onDelta)
    } catch (fallbackErr) {
      const fbErr: Error = fallbackErr as Error
      logger.warn('普通对话也失败: %{public}s', fbErr.message ?? '')
      throw new Error(toolErr.message || '工具调用失败')
    }
  }

  if (!toolResult.hasToolCalls) {
    const directText: string = toolResult.content.length > 0 ? toolResult.content : decisionText
    notifyNoToolCall(onToolCall)
    if (directText.length > 0) {
      onDelta(directText)
    }
    return directText
  }

  const executions: WebSearchExecution[] = await executeSearchToolCalls(
    toolResult.toolCalls,
    messages,
    profile.tavilyApiKey,
    toolCallInfo,
    onStatus,
    onToolCall
  )
  const resultCount: number = countSearchResults(executions)
  const combinedQuery: string = buildCombinedQuery(executions)

  toolCallInfo.phase = 'compiling'
  toolCallInfo.query = combinedQuery
  toolCallInfo.resultCount = resultCount
  toolCallInfo.phaseIcon = '📝'
  toolCallInfo.phaseDescription = '正在整理 ' + resultCount.toString() + ' 条搜索结果...'
  onToolCall?.(toolCallInfo)
  onStatus?.('📝 正在整理搜索结果...')

  if (!hasSuccessfulSearch(executions)) {
    const failedText: string = buildSearchFailedAnswer(executions)
    completeToolCall(toolCallInfo, '搜索失败，未获得可用结果', onToolCall)
    onDelta(failedText)
    return failedText
  }

  if (resultCount === 0) {
    const emptyText: string = buildEmptySearchAnswer()
    completeToolCall(toolCallInfo, '未找到可用搜索结果', onToolCall)
    onDelta(emptyText)
    return emptyText
  }

  const fullMessages: ChatMessage[] = buildMessagesWithToolResults(messages, toolResult, executions)
  const finalText: string = await completeFinalAnswer(profile, fullMessages, onDelta, onStatus)
  completeToolCall(toolCallInfo, '共搜索 ' + resultCount.toString() + ' 条结果', onToolCall)
  return finalText
}

/**
 * 创建 web_search 工具声明。
 *
 * @returns OpenAI tools 数组
 */
function buildWebSearchTools(): Object[] {
  const queryProp: Record<string, string> = {}
  queryProp['type'] = 'string'
  queryProp['description'] = '搜索关键词或自然语言问题'

  const props: Record<string, Object> = {}
  props['query'] = queryProp

  const params: Record<string, Object> = {}
  params['type'] = 'object'
  params['properties'] = props
  params['required'] = ['query']

  const funcDef: Record<string, Object> = {}
  funcDef['name'] = WEB_SEARCH_TOOL_NAME
  funcDef['description'] = '搜索互联网获取最新信息。当用户需要实时数据、最新新闻或训练数据之外的知识时使用此工具。'
  funcDef['parameters'] = params

  const toolDef: Record<string, Object> = {}
  toolDef['type'] = 'function'
  toolDef['function'] = funcDef

  return [toolDef]
}

/**
 * 顺序执行模型请求的所有 web_search tool call。
 *
 * @param toolCalls - 模型发起的工具调用列表
 * @param messages - 对话消息列表
 * @param apiKey - Tavily API 密钥
 * @param toolCallInfo - 可复用的工具状态对象
 * @param onStatus - 可选的状态更新回调
 * @param onToolCall - 可选的工具调用阶段回调
 * @returns 搜索执行结果列表
 */
async function executeSearchToolCalls(
  toolCalls: ToolCall[],
  messages: ChatMessage[],
  apiKey: string,
  toolCallInfo: ToolCallInfo,
  onStatus?: ChatStatusCallback,
  onToolCall?: ToolCallCallback
): Promise<WebSearchExecution[]> {
  const executions: WebSearchExecution[] = []
  for (let i: number = 0; i < toolCalls.length; i++) {
    const query: string = parseSearchQuery(toolCalls[i].function.arguments, messages)
    toolCallInfo.phase = 'searching'
    toolCallInfo.query = query
    toolCallInfo.phaseIcon = '🌐'
    toolCallInfo.phaseDescription = '正在搜索 "' + query + '"'
    onToolCall?.(toolCallInfo)
    onStatus?.('🔍 正在搜索互联网...')

    const response: SearchResponse = await searchWeb(query, apiKey)
    executions.push(new WebSearchExecution(toolCalls[i], query, response))
  }
  return executions
}

/**
 * 从 tool call 参数中解析查询文本。
 *
 * @param argumentsText - tool call function.arguments 原文
 * @param messages - 对话消息列表
 * @returns 搜索查询文本
 */
function parseSearchQuery(argumentsText: string, messages: ChatMessage[]): string {
  let parsedQuery: string = argumentsText
  try {
    const parsedValue: Object = JSON.parse(argumentsText) as Object
    if (typeof parsedValue === 'object' && parsedValue !== null) {
      const parsedRecord: Record<string, Object> = parsedValue as Record<string, Object>
      const queryValue: Object | undefined = parsedRecord['query']
      if (typeof queryValue === 'string') {
        parsedQuery = queryValue
      }
    }
  } catch (e) {
    parsedQuery = argumentsText
  }

  if (parsedQuery.trim().length > 0) {
    return parsedQuery.trim()
  }
  return getLastUserMessage(messages)
}

/**
 * 获取最后一条用户消息作为兜底搜索词。
 *
 * @param messages - 对话消息列表
 * @returns 用户最后一条非空消息
 */
function getLastUserMessage(messages: ChatMessage[]): string {
  for (let i: number = messages.length - 1; i >= 0; i--) {
    if (messages[i].role === 'user' && messages[i].content.trim().length > 0) {
      return messages[i].content.trim()
    }
  }
  return ''
}

/**
 * 统计成功搜索返回的结果数。
 *
 * @param executions - 搜索执行结果列表
 * @returns 搜索结果总数
 */
function countSearchResults(executions: WebSearchExecution[]): number {
  let count: number = 0
  for (let i: number = 0; i < executions.length; i++) {
    if (executions[i].response.success) {
      count += executions[i].response.results.length
    }
  }
  return count
}

/**
 * 判断是否至少有一次搜索请求成功。
 *
 * @param executions - 搜索执行结果列表
 * @returns true 表示至少一次搜索成功
 */
function hasSuccessfulSearch(executions: WebSearchExecution[]): boolean {
  for (let i: number = 0; i < executions.length; i++) {
    if (executions[i].response.success) {
      return true
    }
  }
  return false
}

/**
 * 拼接多次搜索查询，供 UI 摘要展示。
 *
 * @param executions - 搜索执行结果列表
 * @returns 查询摘要
 */
function buildCombinedQuery(executions: WebSearchExecution[]): string {
  let combined: string = ''
  for (let i: number = 0; i < executions.length; i++) {
    if (executions[i].query.length === 0) {
      continue
    }
    if (combined.length > 0) {
      combined += '；'
    }
    combined += executions[i].query
  }
  return combined
}

/**
 * 构造包含工具调用结果的二阶段消息。
 *
 * @param messages - 原始对话消息
 * @param toolResult - 模型工具决策结果
 * @param executions - 搜索执行结果列表
 * @returns 二阶段补全消息
 */
function buildMessagesWithToolResults(
  messages: ChatMessage[],
  toolResult: ToolCallResult,
  executions: WebSearchExecution[]
): ChatMessage[] {
  const fullMessages: ChatMessage[] = copyMessages(messages)
  const assistantMsg: ChatMessage = new ChatMessage('assistant', '')
  assistantMsg.toolCalls = toolResult.toolCalls
  fullMessages.push(assistantMsg)

  logger.info('Phase 2 toolCalls.length=%d', toolResult.toolCalls.length)
  for (let i: number = 0; i < executions.length; i++) {
    const execution: WebSearchExecution = executions[i]
    const tcId: string = execution.toolCall.id
    const tcName: string = execution.toolCall.function.name
    if (execution.response.success && execution.response.results.length > 0) {
      fullMessages.push(new ChatMessage('tool', buildSearchContext(execution.response), tcId, tcName))
    } else if (execution.response.success) {
      fullMessages.push(new ChatMessage('tool', '联网搜索没有找到可用结果：' + execution.query, tcId, tcName))
    } else {
      fullMessages.push(new ChatMessage('tool', '网络搜索失败：' + execution.response.errorMessage, tcId, tcName))
    }
  }
  return fullMessages
}

/**
 * 获取最终模型回答。
 *
 * @param profile - AI 提供方配置
 * @param fullMessages - 包含工具结果的消息列表
 * @param onDelta - 文本增量回调
 * @param onStatus - 可选的状态更新回调
 * @returns 最终回答文本
 */
async function completeFinalAnswer(
  profile: AiProviderProfile,
  fullMessages: ChatMessage[],
  onDelta: ChatStreamChunkCallback,
  onStatus?: ChatStatusCallback
): Promise<string> {
  try {
    return await chatCompleteStream(profile, fullMessages, onDelta)
  } catch (e) {
    logger.warn('Phase 2 流式失败，降级为非流式: %{public}s', (e as Error).message ?? '')
    onStatus?.('📝 正在生成最终回答...')
    const finalText: string = await chatComplete(profile, fullMessages)
    onDelta(finalText)
    return finalText
  }
}

/**
 * 创建工具阶段状态对象。
 *
 * @param phase - 阶段值
 * @param icon - 阶段图标
 * @param description - 阶段描述
 * @param query - 搜索查询
 * @param resultCount - 搜索结果数量
 * @returns 工具阶段状态
 */
function createToolInfo(
  phase: string,
  icon: string,
  description: string,
  query: string,
  resultCount: number
): ToolCallInfo {
  const info: ToolCallInfo = new ToolCallInfo()
  info.phase = phase
  info.toolName = WEB_SEARCH_TOOL_NAME
  info.query = query
  info.resultCount = resultCount
  info.phaseIcon = icon
  info.phaseDescription = description
  return info
}

/**
 * 通知页面当前没有工具调用。
 *
 * @param onToolCall - 可选的工具调用阶段回调
 */
function notifyNoToolCall(onToolCall?: ToolCallCallback): void {
  onToolCall?.(createToolInfo('', '', '', '', 0))
}

/**
 * 标记工具调用完成。
 *
 * @param info - 工具阶段状态
 * @param description - 完成描述
 * @param onToolCall - 可选的工具调用阶段回调
 */
function completeToolCall(info: ToolCallInfo, description: string, onToolCall?: ToolCallCallback): void {
  info.phase = 'complete'
  info.phaseIcon = '✅'
  info.phaseDescription = description
  onToolCall?.(info)
}

/**
 * 将 Tavily 搜索结果构造成适合模型阅读的上下文字符串。
 *
 * @param searchResponse - Tavily 搜索结果
 * @returns 带来源标记的上下文文本
 */
function buildSearchContext(searchResponse: SearchResponse): string {
  let context: string = ''

  if (searchResponse.answer.length > 0) {
    context += '搜索摘要：' + searchResponse.answer + '\n\n'
  }

  context += '搜索结果：\n'
  for (let i: number = 0; i < searchResponse.results.length; i++) {
    const item = searchResponse.results[i]
    context += (i + 1).toString() + '. [' + item.title + '](' + item.url + ')\n'
    if (item.content.length > 0) {
      context += '   ' + item.content + '\n'
    }
    context += '\n'
  }

  context += '请仅基于以上搜索结果回答用户问题，并标注引用来源；如果搜索结果不足以确认结论，请明确说明无法确认。'
  return context
}

/**
 * 构造全部搜索失败时的回答。
 *
 * @param executions - 搜索执行结果列表
 * @returns 用户可读回答
 */
function buildSearchFailedAnswer(executions: WebSearchExecution[]): string {
  let reason: string = '未知错误'
  for (let i: number = 0; i < executions.length; i++) {
    if (!executions[i].response.success && executions[i].response.errorMessage.length > 0) {
      reason = executions[i].response.errorMessage
      break
    }
  }
  return '联网搜索失败：' + reason + '\n\n我没有获取到可用的实时搜索结果，因此不会基于最新信息继续推断。请稍后重试，或关闭联网搜索后按模型已有知识回答。'
}

/**
 * 构造搜索成功但无结果时的回答。
 *
 * @returns 用户可读回答
 */
function buildEmptySearchAnswer(): string {
  return '联网搜索没有找到可用结果。\n\n我没有足够的网络来源回答这个问题。可以换一个更具体的关键词重试，或关闭联网搜索后按模型已有知识回答。'
}

/**
 * 判断工具调用失败是否应缓存为不支持 tools。
 *
 * @param error - 工具决策阶段错误
 * @returns true 表示后续同配置应跳过工具流程
 */
function shouldCacheToolFailure(error: Error): boolean {
  const statusCode: number = parseInt(error.message)
  if (statusCode === 400 || statusCode === 404 || statusCode === 422 || statusCode === 501) {
    return true
  }
  const msg: string = error.message.toLowerCase()
  return msg.indexOf('tool') >= 0 || msg.indexOf('function') >= 0
}

/**
 * 标记当前配置不支持工具调用。
 *
 * @param profile - AI 提供方配置
 */
function markToolUnsupported(profile: AiProviderProfile): void {
  toolUnsupportedProfileKeys[getToolCapabilityKey(profile)] = true
}

/**
 * 判断当前配置是否已被标记为不支持工具调用。
 *
 * @param profile - AI 提供方配置
 * @returns true 表示应跳过工具流程
 */
function isToolUnsupported(profile: AiProviderProfile): boolean {
  return toolUnsupportedProfileKeys[getToolCapabilityKey(profile)] === true
}

/**
 * 构造工具能力缓存键。
 *
 * @param profile - AI 提供方配置
 * @returns 缓存键
 */
function getToolCapabilityKey(profile: AiProviderProfile): string {
  return profile.endpoint.trim() + '\n' + profile.modelName.trim()
}

/**
 * 深拷贝 ChatMessage 数组。
 *
 * ArkTS 不支持 spread 操作符，使用循环逐项复制。
 *
 * @param messages - 原始消息数组
 * @returns 副本
 */
function copyMessages(messages: ChatMessage[]): ChatMessage[] {
  const result: ChatMessage[] = []
  for (let i = 0; i < messages.length; i++) {
    const src: ChatMessage = messages[i]
    const dest: ChatMessage = new ChatMessage(src.role, src.content, src.toolCallId, src.name)
    if (src.toolCalls) {
      dest.toolCalls = src.toolCalls
    }
    result.push(dest)
  }
  return result
}

/**
 * 将 AI 调用异常转换为页面展示文案。
 *
 * @param err - 调用异常
 * @returns 用户可读错误信息
 */
export function formatAiCompletionError(err: Error): string {
  const code: number = parseInt(err.message)
  if (!isNaN(code)) {
    const info = translateError(code, err.message)
    return info.userMessage + '\n' + info.suggestion
  }
  if (err.message.length > 0 && err.message.indexOf('请先') === 0) {
    return err.message
  }
  return 'AI 调用失败：' + (err.message || '未知错误')
}
