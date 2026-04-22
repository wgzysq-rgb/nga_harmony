import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Context } from '@kit.AbilityKit';

const TAG = 'SessionStore';
const DOMAIN = 0x0000;
const PREF_NAME = 'nga_sessions';
const KEY_SESSIONS = 'sessions';
const MAX_AGE = 7 * 24 * 3600 * 1000; // 7天

export interface Session {
  uid: string;
  cid: string;
  nickName: string;
  avatarUrl: string;
  createdAt: number;
}

/**
 * 会话持久化管理
 * 使用 Preferences 存储，替代原 Node.js 的文件存储
 */
export class SessionStore {
  private sessions: Map<string, Session> = new Map();
  private dirty: boolean = false;
  private pref: preferences.Preferences | null = null;
  private context: Context | null = null;

  async init(context: Context): Promise<void> {
    this.context = context;
    try {
      this.pref = await preferences.getPreferences(context, PREF_NAME);
      await this.load();
      this.cleanup();
      hilog.info(DOMAIN, TAG, 'SessionStore initialized, %d sessions', this.sessions.size);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to init SessionStore: %{public}s', JSON.stringify(e));
    }
  }

  async create(uid: string, cid: string, nickName: string, avatarUrl: string): Promise<string> {
    // 生成随机 token
    const token = this.generateToken();
    this.sessions.set(token, { uid, cid, nickName, avatarUrl, createdAt: Date.now() });
    this.dirty = true;
    await this.flush();
    return token;
  }

  get(token: string): Session | null {
    return this.sessions.get(token) ?? null;
  }

  async update(token: string, nickName?: string, avatarUrl?: string): Promise<void> {
    const session = this.sessions.get(token);
    if (!session) return;
    if (nickName !== undefined) session.nickName = nickName;
    if (avatarUrl !== undefined) session.avatarUrl = avatarUrl;
    this.dirty = true;
    await this.flush();
  }

  async destroy(token: string): Promise<void> {
    if (this.sessions.delete(token)) {
      this.dirty = true;
      await this.flush();
    }
  }

  cleanup(): void {
    const now = Date.now();
    let changed = false;
    const keys = Array.from(this.sessions.keys());
    for (const token of keys) {
      const session = this.sessions.get(token)!;
      if (now - session.createdAt > MAX_AGE) {
        this.sessions.delete(token);
        changed = true;
      }
    }
    if (changed) {
      this.dirty = true;
    }
  }

  private async load(): Promise<void> {
    if (!this.pref) return;
    try {
      const raw = await this.pref.get(KEY_SESSIONS, '[]') as string;
      const entries: Array<Array<Object>> = JSON.parse(raw);
      for (let i = 0; i < entries.length; i++) {
        const entry = entries[i];
        const token = String(entry[0]);
        const sessionObj = entry[1] as Record<string, Object>;
        const session: Session = {
          uid: String(sessionObj['uid'] ?? ''),
          cid: String(sessionObj['cid'] ?? ''),
          nickName: String(sessionObj['nickName'] ?? ''),
          avatarUrl: String(sessionObj['avatarUrl'] ?? ''),
          createdAt: Number(sessionObj['createdAt'] ?? 0),
        };
        this.sessions.set(token, session);
      }
    } catch (e) {
      hilog.info(DOMAIN, TAG, 'No persisted sessions found');
    }
  }

  flushNow(): void {
    this.flush()
  }

  private async flush(): Promise<void> {
    if (!this.dirty || !this.pref) return;
    this.dirty = false;
    try {
      const entries: Array<Array<Object>> = [];
      const keys = Array.from(this.sessions.keys());
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const session = this.sessions.get(key);
        if (session) {
          entries.push([key, session]);
        }
      }
      await this.pref.put(KEY_SESSIONS, JSON.stringify(entries));
      await this.pref.flush();
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Flush failed: %{public}s', JSON.stringify(e));
    }
  }

  private generateToken(): string {
    const chars = '0123456789abcdef';
    let result = '';
    for (let i = 0; i < 64; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }
}

export const sessionStore = new SessionStore();
