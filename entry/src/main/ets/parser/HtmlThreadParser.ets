/**
 * HtmlThreadParser — barrel re-export。
 *
 * 实现已按职责拆分到 parser/nga/html-thread/ 下：
 * - index.ets：顶层装配（parseHtmlToRawJson）+ 整型/字符串变量提取
 * - ScanState.ets：平衡扫描状态机（extractBalancedBraces / scanBalanced）
 * - PostArgScanner.ets：postArg.proc / setAll / setDefault 参数扫描
 * - DomMarkerExtractor.ets：DOM 标记内容提取
 * - AttachParser.ets：附件数据解析
 *
 * 此处保留导出，使唯一调用方 parser/task/HtmlParseTask.ets 的 import 路径零改动。
 */
export { parseHtmlToRawJson } from './nga/html-thread/index';
