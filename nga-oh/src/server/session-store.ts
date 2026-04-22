import { randomBytes } from 'node:crypto';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

interface Session {
  uid: string;
  cid: string;
  nickName: string;
  avatarUrl: string;
  createdAt: number;
}

const __dirname = dirname(fileURLToPath(import.meta.url));
const DATA_DIR = resolve(__dirname, '../../data');
const SESSION_FILE = resolve(DATA_DIR, 'sessions.json');

class SessionStore {
  private sessions = new Map<string, Session>();
  private dirty = false;
  private flushTimer: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    this.load();
    this.cleanup();
    setInterval(() => this.cleanup(), 60 * 60 * 1000);
    setInterval(() => this.flush(), 5_000);
    process.on('exit', () => this.flushSync());
  }

  create(uid: string, cid: string, nickName: string, avatarUrl: string): string {
    const token = randomBytes(32).toString('hex');
    this.sessions.set(token, { uid, cid, nickName, avatarUrl, createdAt: Date.now() });
    this.markDirty();
    return token;
  }

  get(token: string): Session | null {
    return this.sessions.get(token) ?? null;
  }

  update(token: string, patch: Partial<Pick<Session, 'nickName' | 'avatarUrl'>>): void {
    const session = this.sessions.get(token);
    if (!session) return;
    Object.assign(session, patch);
    this.markDirty();
  }

  destroy(token: string): void {
    if (this.sessions.delete(token)) {
      this.markDirty();
    }
  }

  cleanup(maxAge = 7 * 24 * 3600 * 1000): void {
    const now = Date.now();
    let changed = false;
    for (const [token, session] of this.sessions) {
      if (now - session.createdAt > maxAge) {
        this.sessions.delete(token);
        changed = true;
      }
    }
    if (changed) this.markDirty();
  }

  private load(): void {
    try {
      const raw = readFileSync(SESSION_FILE, 'utf-8');
      const entries: [string, Session][] = JSON.parse(raw);
      for (const [token, session] of entries) {
        this.sessions.set(token, session);
      }
      console.log(`[session] loaded ${this.sessions.size} sessions from disk`);
    } catch {
      console.log('[session] no persisted sessions found, starting fresh');
    }
  }

  private markDirty(): void {
    this.dirty = true;
  }

  private serialize(): string {
    return JSON.stringify([...this.sessions.entries()]);
  }

  flush(): void {
    if (!this.dirty) return;
    this.dirty = false;
    try {
      mkdirSync(DATA_DIR, { recursive: true });
      writeFileSync(SESSION_FILE, this.serialize());
    } catch (err) {
      console.error('[session] flush failed:', err);
    }
  }

  private flushSync(): void {
    if (!this.dirty) return;
    try {
      mkdirSync(DATA_DIR, { recursive: true });
      writeFileSync(SESSION_FILE, this.serialize());
    } catch (err) {
      console.error('[session] flushSync failed:', err);
    }
  }
}

export const sessionStore = new SessionStore();
