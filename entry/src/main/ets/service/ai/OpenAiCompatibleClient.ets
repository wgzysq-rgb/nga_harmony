/**
 * OpenAI 兼容 API 客户端。
 *
 * 支持向 OpenAI 兼容端点发送对话补全请求，
 * 提供测试连接、获取模型列表功能。
 */

import { http } from '@kit.NetworkKit'
import { Logger, DOMAIN_APP } from '../../common/utils/Logger'
import type { AiProviderProfile } from '../../model/AiConfig'
import { AiTestResult } from '../../model/AiConfig'

const logger = new Logger(DOMAIN_APP, 'OpenAiClient')

/** 请求超时毫秒数 */
const REQUEST_TIMEOUT: number = 60000
/** 连接超时毫秒数 */
const CONNECT_TIMEOUT: number = 15000

/** 对话消息 */
export class ChatMessage {
  /** 消息角色 */
  role: string
  /** 消息内容 */
  content: string

  /**
   * 创建对话消息。
   *
   * @param role - 消息角色
   * @param content - 消息内容
   */
  constructor(role: string, content: string) {
    this.role = role
    this.content = content
  }
}

/**
 * 向 OpenAI 兼容端点发送聊天补全请求。
 *
 * @param profile - AI 提供方配置
 * @param messages - 消息列表
 * @returns 模型返回的完整文本
 */
export async function chatComplete(
  profile: AiProviderProfile,
  messages: ChatMessage[]
): Promise<string> {
  const url: string = buildChatUrl(profile.endpoint)
  const body: string = buildRequestBody(profile, messages, false)

  const httpRequest: http.HttpRequest = http.createHttp()
  try {
    const response: http.HttpResponse = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: buildHeaders(profile.apiKey),
      extraData: body,
      expectDataType: http.HttpDataType.STRING,
      readTimeout: REQUEST_TIMEOUT,
      connectTimeout: CONNECT_TIMEOUT
    })

    const statusCode: number = response.responseCode
    const responseText: string = (response.result as string) ?? ''

    if (statusCode !== 200) {
      throw new Error(String(statusCode))
    }

    const content: string = parseChatResponse(responseText)
    if (content.length === 0) {
      throw new Error('AI 响应为空或格式不兼容')
    }
    return content
  } finally {
    httpRequest.destroy()
  }
}

/**
 * 测试与 AI 端点的连接。
 *
 * 发送简短测试消息验证端点可达性、API Key 有效性和模型可用性。
 *
 * @param profile - AI 提供方配置
 * @returns 测试结果
 */
export async function testConnection(profile: AiProviderProfile): Promise<AiTestResult> {
  const url: string = buildChatUrl(profile.endpoint)
  const testMessages: ChatMessage[] = [
    new ChatMessage('user', '请用一句简短的中文确认连接成功。')
  ]
  const body: string = buildRequestBody(profile, testMessages, false)

  const result: AiTestResult = new AiTestResult()

  const httpRequest: http.HttpRequest = http.createHttp()
  const startTime: number = Date.now()
  try {
    const response: http.HttpResponse = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: buildHeaders(profile.apiKey),
      extraData: body,
      expectDataType: http.HttpDataType.STRING,
      readTimeout: 15000,
      connectTimeout: 10000
    })

    result.durationMs = Date.now() - startTime

    const statusCode: number = response.responseCode
    const responseText: string = (response.result as string) ?? ''

    if (statusCode === 200) {
      result.success = true
      result.message = parseChatResponse(responseText)
    } else {
      result.success = false
      result.errorMessage = `HTTP ${statusCode}`
    }
  } catch (err) {
    result.success = false
    result.durationMs = Date.now() - startTime
    const e: Error = err as Error
    result.errorMessage = e.message || '连接失败'
  } finally {
    httpRequest.destroy()
  }
  return result
}

/**
 * 从端点获取可用模型列表。
 *
 * @param profile - AI 提供方配置
 * @returns 模型名称列表
 */
export async function listModels(profile: AiProviderProfile): Promise<string[]> {
  let baseUrl: string = profile.endpoint
    .replace(/\/chat\/completions\/?$/, '')
    .replace(/\/+$/, '')
  const url: string = baseUrl + '/models'

  const httpRequest: http.HttpRequest = http.createHttp()
  try {
    const response: http.HttpResponse = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      header: buildHeaders(profile.apiKey),
      expectDataType: http.HttpDataType.STRING,
      readTimeout: 15000,
      connectTimeout: 10000
    })

    const statusCode: number = response.responseCode
    const responseText: string = (response.result as string) ?? ''

    if (statusCode !== 200) {
      logger.error('listModels failed: HTTP %{public}d', statusCode)
      return []
    }

    return parseModelList(responseText)
  } finally {
    httpRequest.destroy()
  }
}

/**
 * 构造聊天补全请求 URL。
 *
 * @param endpoint - 用户配置的端点地址
 * @returns 完整的 /chat/completions URL
 */
function buildChatUrl(endpoint: string): string {
  let url: string = endpoint.replace(/\/+$/, '')
  if (!url.endsWith('/chat/completions')) {
    url = url + '/chat/completions'
  }
  return url
}

/**
 * 构造请求头。
 *
 * @param apiKey - API 密钥
 * @returns HTTP 请求头对象
 */
function buildHeaders(apiKey: string): Record<string, string> {
  const headers: Record<string, string> = {}
  headers['Content-Type'] = 'application/json'
  headers['Authorization'] = 'Bearer ' + apiKey
  return headers
}

/**
 * 构造请求体 JSON 字符串。
 *
 * @param profile - AI 提供方配置
 * @param messages - 消息列表
 * @param stream - 是否流式（当前固定 false）
 * @returns JSON 字符串
 */
function buildRequestBody(
  profile: AiProviderProfile,
  messages: ChatMessage[],
  stream: boolean
): string {
  const bodyObj: Record<string, Object> = {}
  bodyObj['model'] = profile.modelName
  bodyObj['messages'] = messages
  bodyObj['stream'] = stream
  bodyObj['temperature'] = profile.temperature
  bodyObj['max_tokens'] = profile.maxTokens

  return JSON.stringify(bodyObj)
}

/**
 * 从 OpenAI 兼容响应 JSON 中提取助手回复内容。
 *
 * @param responseText - 响应 JSON 字符串
 * @returns 助手回复文本
 */
function parseChatResponse(responseText: string): string {
  try {
    const json: Record<string, Object> = JSON.parse(responseText) as Record<string, Object>
    const choices: Object[] = json['choices'] as Object[]
    if (choices && choices.length > 0) {
      const firstChoice: Record<string, Object> = choices[0] as Record<string, Object>
      const message: Record<string, Object> = firstChoice['message'] as Record<string, Object>
      if (message) {
        return (message['content'] as string) ?? ''
      }
    }
    return ''
  } catch (e) {
    logger.error('parseChatResponse failed')
    return ''
  }
}

/**
 * 从 /models 接口响应 JSON 中提取模型 ID 列表。
 *
 * @param responseText - 响应 JSON 字符串
 * @returns 模型 ID 列表
 */
function parseModelList(responseText: string): string[] {
  const result: string[] = []
  try {
    const json: Record<string, Object> = JSON.parse(responseText) as Record<string, Object>
    const data: Object[] = json['data'] as Object[]
    if (data) {
      for (let i = 0; i < data.length; i++) {
        const item: Record<string, Object> = data[i] as Record<string, Object>
        const id: string = (item['id'] as string) ?? ''
        if (id.length > 0) {
          result.push(id)
        }
      }
    }
  } catch (e) {
    logger.error('parseModelList failed')
  }
  return result
}
