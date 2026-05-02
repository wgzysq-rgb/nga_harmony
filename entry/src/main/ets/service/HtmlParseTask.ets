import { parseHtmlToRawJson } from '../parser/HtmlThreadParser'

@Concurrent
function parseHtmlTask(html: string): Object {
  return parseHtmlToRawJson(html) as Object
}

export { parseHtmlTask }
