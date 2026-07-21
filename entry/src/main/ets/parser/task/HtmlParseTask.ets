import { parseHtmlToRawJson } from '../nga/html-thread/index'

@Concurrent
function parseHtmlTask(html: string): Object {
  return parseHtmlToRawJson(html) as Object
}

export { parseHtmlTask }
