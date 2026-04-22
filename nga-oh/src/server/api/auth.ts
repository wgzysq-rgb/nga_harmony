import { ServerResponse } from 'node:http';
import { randomBytes } from 'node:crypto';
import { GET, POST } from '../router.js';
import { ngaClient } from '../nga-client.js';
import { sessionStore } from '../session-store.js';
import { authMiddleware } from '../middleware/auth.js';
import { readBody } from '../lib/body-reader.js';
import { jsonRes } from '../lib/json-res.js';
import iconv from 'iconv-lite';

/** 临时登录会话（Step 1 → Step 2 之间存储凭据） */
interface LoginSession {
  username: string;
  password: string;
  createdAt: number;
}

const loginSessions = new Map<string, LoginSession>();

// 每 5 分钟清理过期的登录会话
setInterval(() => {
  const now = Date.now();
  for (const [key, session] of loginSessions) {
    if (now - session.createdAt > 5 * 60 * 1000) {
      loginSessions.delete(key);
    }
  }
}, 60 * 1000);

function extractNickName(setCookies: string[]): string {
  for (const cookie of setCookies) {
    const match = cookie.match(/ngaPassportUrlencodedUname=([^;]+)/);
    if (match) {
      try {
        const urlDecoded = decodeURIComponent(match[1]);
        return iconv.decode(Buffer.from(urlDecoded, 'binary'), 'utf-8');
      } catch {
        try { return decodeURIComponent(match[1]); } catch { /* fall through */ }
      }
    }
  }
  return '';
}

async function fetchNickNameFromNga(uid: string, cid: string, targetUid: string): Promise<{ nickName: string; avatarUrl: string } | null> {
  try {
    const raw = await ngaClient.get('/nuke.php', {
      __lib: 'ucp', __act: 'get', lite: 'js', noprefix: '', uid: targetUid,
    }, { uid, cid });
    const d = raw?.data?.['0'] ?? raw?.data;
    if (d?.username) {
      return {
        nickName: d.username,
        avatarUrl: d.avatar ?? `https://img4.nga.178.com/ngabbs/nga_classic/avatar/${targetUid}.png`,
      };
    }
  } catch {}
  return null;
}

GET('/api/auth/captcha', async (req, res) => {
  try {
    const url = new URL(req.url || '', `http://${req.headers.host}`);
    const captchaId = url.searchParams.get('id');
    if (!captchaId) {
      jsonRes(res, 400, { ok: false, error: '缺少 captchaId 参数' });
      return;
    }

    const imageBuffer = await ngaClient.getCaptchaV2(captchaId);
    const base64 = (imageBuffer as Buffer).toString('base64');
    jsonRes(res, 200, { ok: true, image: `data:image/png;base64,${base64}` });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '获取验证码失败' });
  }
});

POST('/api/auth/login', async (req, res) => {
  try {
    const body = JSON.parse(await readBody(req));
    const { loginToken, captchaId, captcha } = body;

    if (loginToken) {
      // Step 2：提交验证码
      await handleLoginStep2(res, loginToken, captchaId, captcha);
    } else {
      // Step 1：提交凭据
      await handleLoginStep1(res, body.username, body.password);
    }
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '登录失败' });
  }
});

async function handleLoginStep1(res: ServerResponse, username?: string, password?: string) {
  if (!username || !password) {
    jsonRes(res, 400, { ok: false, error: '请输入用户名和密码' });
    return;
  }

  // Web 浏览器登录始终需要先输入验证码（与 NGA 官方行为一致）
  const captchaId = `login${Date.now()}${Math.floor(Math.random() * 10000)}`;

  // 存储临时登录会话
  const loginToken = randomBytes(16).toString('hex');
  loginSessions.set(loginToken, {
    username, password,
    createdAt: Date.now(),
  });

  // 获取验证码图片
  let captchaImage = '';
  try {
    const imgBuf = await ngaClient.getCaptchaV2(captchaId);
    captchaImage = `data:image/png;base64,${(imgBuf as Buffer).toString('base64')}`;
  } catch {
    // 图片获取失败不阻塞，前端可手动刷新
  }

  jsonRes(res, 200, {
    ok: false,
    needCaptcha: true,
    loginToken,
    captchaId,
    captchaImage,
  });
}

async function handleLoginStep2(res: ServerResponse, loginToken: string, captchaId?: string, captcha?: string) {
  if (!captcha || !captchaId) {
    jsonRes(res, 400, { ok: false, error: '请输入验证码' });
    return;
  }

  const session = loginSessions.get(loginToken);
  if (!session || Date.now() - session.createdAt > 5 * 60 * 1000) {
    jsonRes(res, 400, { ok: false, error: '登录会话已过期，请重试' });
    return;
  }

  const result = await ngaClient.loginPassword({
    username: session.username,
    password: session.password,
    captchaId,
    captcha,
  });

  if (result.success && result.uid && result.cid) {
    loginSessions.delete(loginToken);
    let nickName = result.setCookies ? extractNickName(result.setCookies) : '';
    let avatarUrl = `https://img4.nga.178.com/ngabbs/nga_classic/avatar/${result.uid}.png`;
    if (!nickName) {
      const fetched = await fetchNickNameFromNga(result.uid, result.cid, result.uid);
      if (fetched) {
        nickName = fetched.nickName;
        avatarUrl = fetched.avatarUrl;
      } else {
        nickName = session.username;
      }
    }
    const token = sessionStore.create(result.uid, result.cid, nickName, avatarUrl);
    jsonRes(res, 200, { ok: true, token, user: { uid: result.uid, nickName, avatarUrl } });
    return;
  }

  // 验证码错误或其他失败 — 刷新验证码让用户重试
  const newCaptchaId = `login${Date.now()}${Math.floor(Math.random() * 10000)}`;
  let captchaImage = '';
  try {
    const imgBuf = await ngaClient.getCaptchaV2(newCaptchaId);
    captchaImage = `data:image/png;base64,${(imgBuf as Buffer).toString('base64')}`;
  } catch { /* ignore */ }

  jsonRes(res, 200, {
    ok: false,
    needCaptcha: true,
    loginToken,
    captchaId: newCaptchaId,
    captchaImage,
    error: result.error ?? '验证码错误',
  });
}

GET('/api/auth/me', async (req, res) => {
  const rawToken = req.headers.authorization?.replace('Bearer ', '') ?? (() => {
    const cookieHeader = req.headers.cookie as string | undefined;
    if (cookieHeader) {
      const match = cookieHeader.match(/(?:^|;\s*)nga_token=([^;]+)/);
      if (match) return match[1];
    }
    return '';
  })();
  const session = authMiddleware(req);
  if (!session) {
    jsonRes(res, 401, { ok: false, error: '未登录' });
    return;
  }

  if (session.nickName === `User${session.uid}` || !session.nickName) {
    const fetched = await fetchNickNameFromNga(session.uid, session.cid, session.uid);
    if (fetched) {
      session.nickName = fetched.nickName;
      session.avatarUrl = fetched.avatarUrl;
      if (rawToken) {
        sessionStore.update(rawToken, { nickName: fetched.nickName, avatarUrl: fetched.avatarUrl });
      }
    }
  }

  jsonRes(res, 200, {
    ok: true,
    user: { uid: session.uid, nickName: session.nickName, avatarUrl: session.avatarUrl },
  });
});

POST('/api/auth/inject', async (req, res) => {
  try {
    let content: string;
    const body = JSON.parse(await readBody(req));
    if (body.content && typeof body.content === 'string') {
      content = body.content;
    } else {
      const { readFileSync } = await import('node:fs');
      const { resolve } = await import('node:path');
      const pwPath = resolve(import.meta.dirname ?? '.', '../../pw.txt');
      content = readFileSync(pwPath, 'utf-8');
    }
    const uidMatch = content.match(/NGA_UID\s*=\s*(\S+)/);
    const cidMatch = content.match(/NGA_CID\s*=\s*(\S+)/);
    if (!uidMatch || !cidMatch) {
      jsonRes(res, 400, { ok: false, error: '文件格式无效，需要包含 NGA_UID 和 NGA_CID' });
      return;
    }
    const uid = uidMatch[1];
    const cid = cidMatch[1];
    let nickName = `User${uid}`;
    let avatarUrl = `https://img4.nga.178.com/ngabbs/nga_classic/avatar/${uid}.png`;
    const fetched = await fetchNickNameFromNga(uid, cid, uid);
    if (fetched) {
      nickName = fetched.nickName;
      avatarUrl = fetched.avatarUrl;
    }
    const token = sessionStore.create(uid, cid, nickName, avatarUrl);
    jsonRes(res, 200, { ok: true, token, user: { uid, nickName, avatarUrl } });
  } catch (err: any) {
    jsonRes(res, 500, { ok: false, error: err.message ?? '注入失败' });
  }
});

POST('/api/auth/logout', async (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (token) {
    sessionStore.destroy(token);
  }
  jsonRes(res, 200, { ok: true });
});
