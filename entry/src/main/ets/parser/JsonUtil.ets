interface BracketCount {
  braces: number;
  brackets: number;
}

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

function countBrackets(text: string): BracketCount {
  let braces = 0;
  let brackets = 0;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === '{') braces++;
    else if (ch === '}') braces--;
    else if (ch === '[') brackets++;
    else if (ch === ']') brackets--;
  }
  const result: BracketCount = { braces, brackets };
  return result;
}

export function repairTruncatedJson(text: string): object | null {
  if (text.length < 100 || !text.startsWith('{')) return null;

  const tIdx = text.lastIndexOf('"__T"');
  if (tIdx > 100) {
    const beforeT = text.slice(0, tIdx).replace(/,\s*$/, '');
    const counts = countBrackets(beforeT);
    if (counts.braces >= 0 && counts.brackets >= 0) {
      try {
        const suffix = '}'.repeat(counts.braces) + ']'.repeat(counts.brackets);
        const repaired = beforeT + suffix;
        const parsed = JSON.parse(repaired) as Record<string, Object>;
        if (parsed) return parsed;
      } catch (e) {
        // fall through
      }
    }
  }

  for (let attempt = 0; attempt < 10; attempt++) {
    const lastComma = text.lastIndexOf(',', text.length - attempt - 1);
    if (lastComma < 50) continue;
    const candidate = text.slice(0, lastComma);
    const counts = countBrackets(candidate);
    if (counts.braces < 0 || counts.brackets < 0) continue;
    try {
      const suffix = '}'.repeat(counts.braces) + ']'.repeat(counts.brackets);
      const repaired = candidate + suffix;
      const parsed = JSON.parse(repaired) as Record<string, Object>;
      if (parsed) return parsed;
    } catch (e) {
      // continue
    }
  }
  return null;
}
