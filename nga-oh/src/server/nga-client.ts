import { request as httpsRequest } from 'node:https';
import { request as httpRequest } from 'node:http';
import { URL, URLSearchParams } from 'node:url';
import { publicEncrypt, constants as cryptoConstants } from 'node:crypto';
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { resolve, join } from 'node:path';
import iconv from 'iconv-lite';
import { snapAls } from './lib/snapshot.js';
import { ngaThrottler } from './lib/throttle.js';

/** NGA 登录用 RSA 公钥（从 account_copy.html 的 _encrypt 函数中提取） */
const NGA_RSA_PUBLIC_KEY = `-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyKzZWDimCN1OCprqWUhF
UPhcwxDE62/BFVP6LtQHJu+65dm4YNmDvzitmcfaXW9YbhXnd4oP7j+6vpcgJQ+p
3ucySo1ZnqO0Bb2JKEtxpCmxe7IYXhFEkJqHpFYBTiAxQz2n2mX4JZy/ehBUSMjz
gzd0NdG6Ai1C42oCzYltUOjNWZUNHn1nqpElSWHnUWqkdN8+5ISP/ZMKiQdFANkE
qDGw3/34qyF+E/hVgrGF4/CcWNP/LJCdB6DYtx7VPlQZF0tP1s+q/++rC4rQ2wmV
l2V8zGh1j7ojZbt62hVjy6byK1E/2XYo97ZtL4KDW7F5jJMvSDRFR7901UR8hCdf
4wIDAQAB
-----END PUBLIC KEY-----`;

/** RSA 加密密码（与 NGA 前端 JSEncrypt.encrypt 行为一致） */
function encryptPassword(password: string): string {
  const buffer = Buffer.from(password, 'utf-8');
  const encrypted = publicEncrypt({
    key: NGA_RSA_PUBLIC_KEY,
    padding: cryptoConstants.RSA_PKCS1_PADDING,
  }, buffer);
  return encrypted.toString('base64');
}

const DOMAINS = [
  'https://bbs.nga.cn',
  'https://ngabbs.com',
  'https://nga.178.com',
];

let activeDomainIndex = 0;

interface NgaRequestOptions {
  method?: 'GET' | 'POST';
  params?: Record<string, string | number | undefined>;
  body?: Record<string, string>;
  cookies?: { uid: string; cid: string };
  baseUrl?: string;
  extraHeaders?: Record<string, string>;
  rawResponse?: boolean;
  domainIndex?: number;
}

interface HttpResponse {
  body: Buffer;
  headers: Record<string, string | string[] | undefined>;
  statusCode: number;
}

interface MultipartField {
  value: string | Buffer;
  filename?: string;
  contentType?: string;
}

function buildMultipart(fields: Record<string, string>): { buffer: Buffer; contentType: string } {
  const boundary = `----FormBoundary${Math.random().toString(36).slice(2)}`;
  const parts: Buffer[] = [];
  for (const [key, value] of Object.entries(fields)) {
    parts.push(Buffer.from(
      `--${boundary}\r\nContent-Disposition: form-data; name="${key}"\r\n\r\n${value}\r\n`
    ));
  }
  parts.push(Buffer.from(`--${boundary}--\r\n`));
  return {
    buffer: Buffer.concat(parts),
    contentType: `multipart/form-data; boundary=${boundary}`,
  };
}

function buildMultipartWithFile(fields: Record<string, MultipartField>): { buffer: Buffer; contentType: string } {
  const boundary = `----FormBoundary${Math.random().toString(36).slice(2)}`;
  const parts: Buffer[] = [];
  for (const [name, field] of Object.entries(fields)) {
    if (field.filename) {
      const disposition = `--${boundary}\r\nContent-Disposition: form-data; name="${name}"; filename="${field.filename}"\r\nContent-Type: ${field.contentType ?? 'application/octet-stream'}\r\n\r\n`;
      parts.push(Buffer.concat([
        Buffer.from(disposition),
        typeof field.value === 'string' ? Buffer.from(field.value) : field.value,
        Buffer.from('\r\n'),
      ]));
    } else {
      parts.push(Buffer.from(
        `--${boundary}\r\nContent-Disposition: form-data; name="${name}"\r\n\r\n${field.value}\r\n`
      ));
    }
  }
  parts.push(Buffer.from(`--${boundary}--\r\n`));
  return {
    buffer: Buffer.concat(parts),
    contentType: `multipart/form-data; boundary=${boundary}`,
  };
}

const MAX_REDIRECTS = 5;
const REQUEST_TIMEOUT = 30_000;
const MAX_RESPONSE_SIZE = 20 * 1024 * 1024;

function snapFill(ngaUrl: string, ngaParams: Record<string, string | number | undefined>, ngaRaw: any) {
  const store = snapAls.getStore();
  if (!store) return;
  store.ngaUrl = ngaUrl;
  store.ngaParams = Object.fromEntries(
    Object.entries(ngaParams).filter(([, v]) => v !== undefined).map(([k, v]) => [k, String(v)])
  );
  store.ngaRaw = ngaRaw;
}

function httpReq(
  url: URL, method: string, headers: Record<string, string>, body?: Buffer, _redirects?: number
): Promise<Buffer> {
  const redirectCount = _redirects ?? 0;
  return new Promise((resolve, reject) => {
    if (redirectCount >= MAX_REDIRECTS) {
      reject(new Error(`too many redirects (>${MAX_REDIRECTS})`));
      return;
    }
    const isHttps = url.protocol === 'https:';
    const requester = isHttps ? httpsRequest : httpRequest;
    const req = requester(url, { method, headers }, (res) => {
      if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        const next = new URL(res.headers.location, url);
        httpReq(next, 'GET', headers, undefined, redirectCount + 1).then(resolve, reject);
        return;
      }
      const chunks: Buffer[] = [];
      let totalSize = 0;
      res.on('data', (chunk: Buffer) => {
        totalSize += chunk.length;
        if (totalSize > MAX_RESPONSE_SIZE) {
          reject(new Error(`Response too large (>${MAX_RESPONSE_SIZE} bytes)`));
          res.destroy();
          return;
        }
        chunks.push(chunk);
      });
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    });
    req.on('error', reject);
    req.setTimeout(REQUEST_TIMEOUT, () => {
      req.destroy(new Error(`Request timeout (${REQUEST_TIMEOUT}ms)`));
    });
    if (body) req.write(body);
    req.end();
  });
}

function httpReqFull(
  url: URL, method: string, headers: Record<string, string>, body?: Buffer
): Promise<HttpResponse> {
  return new Promise((resolve, reject) => {
    const isHttps = url.protocol === 'https:';
    const requester = isHttps ? httpsRequest : httpRequest;
    const req = requester(url, { method, headers }, (res) => {
      const chunks: Buffer[] = [];
      let totalSize = 0;
      res.on('data', (chunk: Buffer) => {
        totalSize += chunk.length;
        if (totalSize > MAX_RESPONSE_SIZE) {
          reject(new Error(`Response too large (>${MAX_RESPONSE_SIZE} bytes)`));
          res.destroy();
          return;
        }
        chunks.push(chunk);
      });
      res.on('end', () => resolve({
        body: Buffer.concat(chunks),
        headers: res.headers as Record<string, string | string[] | undefined>,
        statusCode: res.statusCode ?? 0,
      }));
      res.on('error', reject);
    });
    req.on('error', reject);
    req.setTimeout(REQUEST_TIMEOUT, () => {
      req.destroy(new Error(`Request timeout (${REQUEST_TIMEOUT}ms)`));
    });
    if (body) req.write(body);
    req.end();
  });
}

function preprocessJson(text: string): string {
  text = text.replace('window.script_muti_get_var_store=', '');
  text = text.replace(/\/\*\$js\$\*\//g, '');
  text = text.replace(/\/\*error fill content\*\//g, '');
  text = text.replace(/"content":\+(\d+),/g, '"content":"+$1",');
  text = text.replace(/"subject":\+(\d+),/g, '"subject":"+$1",');
  text = text.replace(/"content":(0\d+),/g, '"content":"$1",');
  text = text.replace(/"subject":(0\d+),/g, '"subject":"$1",');
  text = text.replace(/"author":(0\d+),/g, '"author":"$1",');

  let inString = false;
  let escaped = false;
  let result = '';
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    const code = text.charCodeAt(i);
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

const PARSE_ERROR_DIR = resolve(process.cwd(), 'data', 'parse-errors');

function saveParseError(url: string, rawText: string, preprocessed: string, errorMsg: string): void {
  try {
    if (!existsSync(PARSE_ERROR_DIR)) {
      mkdirSync(PARSE_ERROR_DIR, { recursive: true });
    }
    const ts = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `${ts}.json`;
    const entry = {
      time: new Date().toISOString(),
      url,
      error: errorMsg,
      rawLength: rawText.length,
      rawHead: rawText.slice(0, 2000),
      rawTail: rawText.slice(-500),
      preprocessedHead: preprocessed.slice(0, 2000),
      preprocessedTail: preprocessed.slice(-500),
    };
    writeFileSync(join(PARSE_ERROR_DIR, filename), JSON.stringify(entry, null, 2), 'utf-8');
    console.log(`[ParseError] saved to data/parse-errors/${filename}  url=${url}`);
  } catch {
    // never let dump logic break the request
  }
}

function repairTruncatedJson(text: string): any | null {
  if (text.length < 100 || !text.startsWith('{')) return null;
  const tIdx = text.lastIndexOf('"__T"');
  if (tIdx > 100) {
    const beforeT = text.slice(0, tIdx).replace(/,\s*$/, '');
    let braces = 0, brackets = 0;
    for (const ch of beforeT) {
      if (ch === '{') braces++;
      else if (ch === '}') braces--;
      else if (ch === '[') brackets++;
      else if (ch === ']') brackets--;
    }
    if (braces >= 0 && brackets >= 0) {
      try {
        const parsed = JSON.parse(beforeT + '}'.repeat(braces) + ']'.repeat(brackets));
        if (parsed && typeof parsed === 'object') return parsed;
      } catch {}
    }
  }
  for (let attempt = 0; attempt < 10; attempt++) {
    const lastComma = text.lastIndexOf(',', text.length - attempt - 1);
    if (lastComma < 50) continue;
    const candidate = text.slice(0, lastComma);
    let braces = 0, brackets = 0;
    for (const ch of candidate) {
      if (ch === '{') braces++;
      else if (ch === '}') braces--;
      else if (ch === '[') brackets++;
      else if (ch === ']') brackets--;
    }
    if (braces < 0 || brackets < 0) continue;
    try {
      const parsed = JSON.parse(candidate + '}'.repeat(braces) + ']'.repeat(brackets));
      if (parsed && typeof parsed === 'object') return parsed;
    } catch {}
  }
  return null;
}

async function ngaRequest(path: string, options: NgaRequestOptions = {}): Promise<any> {
  const {
    method = 'GET',
    params = {},
    body,
    cookies,
    baseUrl,
    extraHeaders = {},
    rawResponse = false,
    domainIndex,
  } = options;

  const domainIdx = domainIndex ?? activeDomainIndex;
  const resolvedBaseUrl = baseUrl ?? DOMAINS[domainIdx];
  const throttleDomain = new URL(resolvedBaseUrl).hostname;

  await ngaThrottler.acquire(throttleDomain);

  let released = false;
  try {
    const url = new URL(path, resolvedBaseUrl);

    if (!params.__inchst) params.__inchst = 'UTF8';

    Object.entries(params).forEach(([key, val]) => {
      if (val !== undefined) {
        url.searchParams.set(key, String(val));
      }
    });

    const headers: Record<string, string> = {
      'User-Agent': 'NGA_WP_JW',
      'X-User-Agent': 'Nga_Official',
      ...extraHeaders,
    };

    if (cookies) {
      headers['Cookie'] = `ngaPassportUid=${cookies.uid}; ngaPassportCid=${cookies.cid}`;
    }

    let requestBody: Buffer | undefined;
    if (body) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
      requestBody = Buffer.from(new URLSearchParams(body).toString());
      headers['Content-Length'] = String(requestBody.length);
    }

    let responseBuffer: Buffer;
    try {
      responseBuffer = await httpReq(url, method, headers, requestBody);
    } catch (firstError) {
      ngaThrottler.release(throttleDomain);
      released = true;
      const retryDomainIdx = (domainIdx + 1) % DOMAINS.length;
      const retryBaseUrl = baseUrl ?? DOMAINS[retryDomainIdx];
      const retryDomain = new URL(retryBaseUrl).hostname;
      await ngaThrottler.acquire(retryDomain);
      try {
        const retryUrl = new URL(path, retryBaseUrl);
        Object.entries(params).forEach(([key, val]) => {
          if (val !== undefined && val !== '') {
            retryUrl.searchParams.set(key, String(val));
          }
        });
        console.log(`[NgaClient] 请求失败，自动切换域名重试: ${DOMAINS[domainIdx]} -> ${DOMAINS[retryDomainIdx]}`);
        responseBuffer = await httpReq(retryUrl, method, headers, requestBody);
      } catch {
        throw firstError;
      } finally {
        ngaThrottler.release(retryDomain);
      }
    }

    if (rawResponse) {
      return responseBuffer;
    }

    const rawText = iconv.decode(responseBuffer, 'gb18030');

    if (rawText.trimStart().startsWith('<!DOCTYPE') || rawText.trimStart().startsWith('<html')) {
      const msgMatch = rawText.match(/<!--msginfostart-->([\s\S]*?)<!--msginfoend-->/);
      const codeMatch = rawText.match(/<!--msgcodestart-->(\d+)<!--msgcodeend-->/);
      const titleMatch = rawText.match(/<title>([\s\S]*?)<\/title>/);
      const htmlError = msgMatch ? msgMatch[1].replace(/<[^>]+>/g, '').trim()
        : titleMatch ? titleMatch[1].trim()
        : '服务器返回了非预期的HTML页面';
      const result = { error: { '0': htmlError }, error_code: codeMatch ? Number(codeMatch[1]) : undefined };
      snapFill(path, params, result);
      return result;
    }

    let text = preprocessJson(rawText);

    try {
      const result = JSON.parse(text);
      snapFill(path, params, result);
      return result;
    } catch (e: any) {
      const repaired = repairTruncatedJson(text);
      if (repaired) {
        console.log(`[JSON Repair] repaired truncated JSON for ${url.pathname} (original ${text.length} chars)`);
        snapFill(path, params, repaired);
        return repaired;
      }
      saveParseError(url.toString(), rawText, text, e.message);
      const errResult = { __parseError: true, __rawLength: text.length, __snippet: text.slice(0, 500), error: e.message };
      snapFill(path, params, errResult);
      return errResult;
    }
  } finally {
    if (!released) {
      ngaThrottler.release(throttleDomain);
    }
  }
}

interface LoginResult {
  success: boolean;
  uid?: string;
  cid?: string;
  rawBody?: string;
  statusCode: number;
  setCookies?: string[];
  error?: string;
}

interface LoginV2Result extends LoginResult {
  captchaRequired?: boolean;
  captchaId?: string;
}

export const ngaClient = {
  get(path: string, params: Record<string, string | number | undefined>, cookies?: { uid: string; cid: string }, extraHeaders?: Record<string, string>) {
    return ngaRequest(path, { method: 'GET', params, cookies, extraHeaders });
  },

  post(path: string, body: Record<string, string>, cookies?: { uid: string; cid: string }) {
    return ngaRequest(path, { method: 'POST', body, cookies });
  },

  getRaw(path: string, params: Record<string, string | number | undefined>, baseUrlOrHeaders?: string | Record<string, string>) {
    if (typeof baseUrlOrHeaders === 'string') {
      return ngaRequest(path, { method: 'GET', params, rawResponse: true, baseUrl: baseUrlOrHeaders });
    }
    return ngaRequest(path, { method: 'GET', params, rawResponse: true, extraHeaders: baseUrlOrHeaders });
  },

  getWithBaseUrl(path: string, params: Record<string, string | number | undefined>, baseUrl: string, cookies?: { uid: string; cid: string }) {
    return ngaRequest(path, { method: 'GET', params, baseUrl, cookies });
  },

  async uploadFile(
    fileBuffer: Buffer,
    fileName: string,
    fileContentType: string,
    formFields: Record<string, string>,
    cookies: { uid: string; cid: string },
  ): Promise<any> {
    const url = new URL('/attach.php', 'https://img8.nga.cn');
    const throttleDomain = url.hostname;
    Object.entries(formFields).forEach(([key, val]) => {
      if (val !== undefined && val !== '') {
        url.searchParams.set(key, val);
      }
    });

    const fields: Record<string, MultipartField> = {};
    for (const [key, val] of Object.entries(formFields)) {
      fields[key] = { value: val };
    }
    fields['attachment_file1'] = {
      value: fileBuffer,
      filename: fileName,
      contentType: fileContentType,
    };
    fields['attachment_file1_url_utf8_name'] = { value: fileName };
    fields['attachment_file1_img'] = { value: '1' };
    fields['attachment_file1_auto_size'] = { value: fileBuffer.length > 4 * 1024 * 1024 ? '1' : '' };
    fields['attachment_file1_watermark'] = { value: '' };
    fields['attachment_file1_dscp'] = { value: '' };

    const { buffer: reqBody, contentType: ct } = buildMultipartWithFile(fields);

    const headers: Record<string, string> = {
      'User-Agent': 'NGA_WP_JW',
      'X-User-Agent': 'Nga_Official',
      'Cookie': `ngaPassportUid=${cookies.uid}; ngaPassportCid=${cookies.cid}`,
      'Content-Type': ct,
      'Content-Length': String(reqBody.length),
      'Origin': 'https://bbs.nga.cn',
      'Referer': 'https://bbs.nga.cn/',
    };

    await ngaThrottler.acquire(throttleDomain);
    try {
      const responseBuffer = await httpReq(url, 'POST', headers, reqBody);
      let text = iconv.decode(responseBuffer, 'gb18030');
      text = preprocessJson(text);
      try {
        return JSON.parse(text);
      } catch {
        return { error: text.slice(0, 500) };
      }
    } finally {
      ngaThrottler.release(throttleDomain);
    }
  },

  setActiveDomainIndex(index: number) {
    activeDomainIndex = index;
    console.log(`[NgaClient] 域名手动切换到: ${DOMAINS[index]}`);
  },

  /** v2: 获取验证码图片 */
  async loginPassword(params: {
    username: string;
    password: string;
    captchaId: string;
    captcha: string;
    type?: string;
  }): Promise<LoginV2Result> {
    const url = new URL('/nuke.php', 'https://bbs.nga.cn');
    const encryptedPassword = encryptPassword(params.password);

    const fields: Record<string, string> = {
      __lib: 'login',
      __output: '1',
      __act: 'login',
      __inchst: 'UTF-8',
      app_id: '5004',
      device: '',
      name: params.username,
      type: params.type ?? '',
      password: encryptedPassword,
      rid: params.captchaId,
      captcha: params.captcha.toUpperCase(),
    };

    const { buffer: reqBody, contentType } = buildMultipart(fields);
    const reqHeaders: Record<string, string> = {
      'User-Agent': 'NGA_WP_JW',
      'X-User-Agent': 'Nga_Official',
      'Referer': 'https://bbs.nga.cn/nuke/account_copy.html?login',
      'Origin': 'https://bbs.nga.cn',
      'Content-Type': contentType,
      'Content-Length': String(reqBody.length),
      'Accept': '*/*',
    };

    const resp = await httpReqFull(url, 'POST', reqHeaders, reqBody);
    const bodyText = iconv.decode(resp.body, 'gb18030');

    const setCookieHeader = resp.headers['set-cookie'];
    const cookies = Array.isArray(setCookieHeader) ? setCookieHeader
      : setCookieHeader ? [setCookieHeader] : [];

    let uid: string | undefined;
    let cid: string | undefined;
    for (const c of cookies) {
      const uidMatch = c.match(/ngaPassportUid=(\d+)/);
      const cidMatch = c.match(/ngaPassportCid=([^;]+)/);
      if (uidMatch) uid = uidMatch[1];
      if (cidMatch) cid = cidMatch[1];
    }

    // Also check response body for uid/cid (NGA may return them in JSON data instead of cookies)
    if (!uid || !cid) {
      const cleaned = preprocessJson(bodyText);
      let parsed: any;
      try { parsed = JSON.parse(cleaned); } catch { parsed = null; }
      if (parsed?.data?.['1'] && parsed?.data?.['2']) {
        uid = String(parsed.data['1']);
        cid = String(parsed.data['2']);
      }
    }

    if (uid && cid) {
      return {
        success: true, uid, cid,
        statusCode: resp.statusCode,
        setCookies: cookies,
      };
    }

    const cleaned = preprocessJson(bodyText);
    let parsed: any;
    try { parsed = JSON.parse(cleaned); } catch { parsed = null; }

    const errorMsg = parsed?.error?.['0'] ?? bodyText.slice(0, 300);

    return {
      success: false,
      statusCode: resp.statusCode,
      setCookies: cookies,
      rawBody: bodyText,
      error: errorMsg,
    };
  },

  /** v2: 获取验证码图片 */
  async getCaptchaV2(captchaId: string): Promise<Buffer> {
    return ngaClient.getRaw(
      '/login_check_code.php',
      { id: captchaId, from: 'login' },
      { Referer: 'https://bbs.nga.cn/nuke/account_copy.html?login' }
    ) as Promise<Buffer>;
  },
};
