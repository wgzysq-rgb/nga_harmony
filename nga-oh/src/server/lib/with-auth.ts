import { IncomingMessage, ServerResponse } from 'node:http';
import { authMiddleware } from '../middleware/auth.js';
import { readBody } from '../lib/body-reader.js';
import { jsonRes } from '../lib/json-res.js';

type AuthedHandler = (req: IncomingMessage, res: ServerResponse, params: Record<string, string>, session: NonNullable<ReturnType<typeof authMiddleware>>) => Promise<void> | void;

export function requireAuth(handler: AuthedHandler) {
  return async (req: IncomingMessage, res: ServerResponse, params: Record<string, string>) => {
    const session = authMiddleware(req);
    if (!session) {
      jsonRes(res, 401, { ok: false, error: '未登录' });
      return;
    }
    return handler(req, res, params, session);
  };
}

export async function parseJsonBody(req: IncomingMessage): Promise<any> {
  return JSON.parse(await readBody(req));
}
