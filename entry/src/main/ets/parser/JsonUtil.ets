export function preprocessJson(text: string): string {
  let t = text;
  t = t.replace('window.script_muti_get_var_store=', '');
  t = t.replace(/\/\*\$js\$\*\//g, '');
  t = t.replace(/\/\*error fill content\*\//g, '');
  t = t.replace(/"content":\+(\d+),/g, '"content":"+$1",');
  t = t.replace(/"subject":\+(\d+),/g, '"subject":"+$1",');
  t = t.replace(/"content":(0\d+),/g, '"content":"$1",');
  t = t.replace(/"subject":(0\d+),/g, '"subject":"$1",');
  t = t.replace(/"author":(0\d+),/g, '"author":"$1",');

  let inString = false;
  let escaped = false;
  let result = '';
  for (let i = 0; i < t.length; i++) {
    const ch = t[i];
    const code = t.charCodeAt(i);
    if (escaped) {
      result += ch;
      escaped = false;
      continue;
    }
    if (ch === '\\') {
      result += ch;
      escaped = true;
      continue;
    }
    if (ch === '"') {
      inString = !inString;
      result += ch;
      continue;
    }
    if (inString && code < 0x20) {
      if (code === 0x09) result += '\\t';
      else if (code === 0x0a) result += '\\n';
      else if (code === 0x0d) result += '\\r';
      else result += '\\u' + code.toString(16).padStart(4, '0');
      continue;
    }
    result += ch;
  }
  return result;
}

