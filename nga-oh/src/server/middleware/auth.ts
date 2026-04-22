import { IncomingMessage } from 'node:http';
import { sessionStore } from '../session-store.js';

export function authMiddleware(req: IncomingMessage): { uid: string; cid: string; nickName: string; avatarUrl: string } | null {
  let token = req.headers.authorization?.replace('Bearer ', '') ?? '';
  if (!token) {
    const cookieHeader = req.headers.cookie as string | undefined;
    if (cookieHeader) {
      const match = cookieHeader.match(/(?:^|;\s*)nga_token=([^;]+)/);
      if (match) token = match[1];
    }
  }
  if (!token) return null;
  const session = sessionStore.get(token);
  if (!session) return null;
  return { uid: session.uid, cid: session.cid, nickName: session.nickName, avatarUrl: session.avatarUrl };
}

export function extractBlacklist(req: IncomingMessage): Set<string> {
  const header = req.headers['x-blacklist'] as string | undefined;
  if (!header) return new Set();
  return new Set(header.split(',').map(s => s.trim()).filter(Boolean));
}
