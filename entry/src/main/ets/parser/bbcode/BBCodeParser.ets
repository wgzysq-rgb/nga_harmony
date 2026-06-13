/**
 * BBCode 解析器公共入口（barrel）。
 * 实现按解析阶段拆分至：
 * - lexer.ets：ParseState / 节点工厂 / 文本预处理 / HTML 转义工具
 * - inline-parser.ets：parseInlineInto / checkInlineFormat / guessMediaTypeFromExt
 * - block-handlers/：tryMatchBlock 每个块级标签分支的独立 handler
 * - parser.ets：parseBBCode / parseBlockNodes 编排器
 */
export { parseBBCode } from './parser'
