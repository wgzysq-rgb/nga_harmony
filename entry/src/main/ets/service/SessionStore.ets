import { hilog } from '@kit.PerformanceAnalysisKit'
import { Context } from '@kit.AbilityKit'
import { PreferencesStore } from '../store/PreferencesStore'

const TAG = 'SessionStore'
const DOMAIN = 0x0000
const KEY_SESSIONS = 'sessions'
const MAX_AGE = 7 * 24 * 3600 * 1000

export interface Session {
  uid: string;
  cid: string;
  nickName: string;
  avatarUrl: string;
  createdAt: number;
}

export class SessionStore {
  private sessions: Map<string, Session> = new Map();
  private dirty: boolean = false;
  private store: PreferencesStore = new PreferencesStore();

  async init(context: Context): Promise<void> {
    try {
      await this.store.init(context, 'nga_sessions')
      await this.load()
      this.cleanup()
      hilog.info(DOMAIN, TAG, 'SessionStore initialized, %d sessions', this.sessions.size)
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to init SessionStore: %{public}s', JSON.stringify(e))
    }
  }

  async create(uid: string, cid: string, nickName: string, avatarUrl: string): Promise<string> {
    const token = this.generateToken()
    this.sessions.set(token, { uid, cid, nickName, avatarUrl, createdAt: Date.now() })
    this.dirty = true
    await this.flush()
    return token
  }

  get(token: string): Session | null {
    return this.sessions.get(token) ?? null
  }

  async update(token: string, nickName?: string, avatarUrl?: string): Promise<void> {
    const session = this.sessions.get(token)
    if (!session) return
    if (nickName !== undefined) session.nickName = nickName
    if (avatarUrl !== undefined) session.avatarUrl = avatarUrl
    this.dirty = true
    await this.flush()
  }

  async destroy(token: string): Promise<void> {
    if (this.sessions.delete(token)) {
      this.dirty = true
      await this.flush()
    }
  }

  cleanup(): void {
    const now = Date.now()
    let changed = false
    const keys = Array.from(this.sessions.keys())
    for (const token of keys) {
      const session = this.sessions.get(token)!
      if (now - session.createdAt > MAX_AGE) {
        this.sessions.delete(token)
        changed = true
      }
    }
    if (changed) {
      this.dirty = true
    }
  }

  private async load(): Promise<void> {
    const saved = await this.store.getJSON<Array<Array<Object>>>(KEY_SESSIONS)
    if (!saved) return
    for (let i = 0; i < saved.length; i++) {
      const entry = saved[i]
      const token = String(entry[0])
      const sessionObj = entry[1] as Record<string, Object>
      const session: Session = {
        uid: String(sessionObj['uid'] ?? ''),
        cid: String(sessionObj['cid'] ?? ''),
        nickName: String(sessionObj['nickName'] ?? ''),
        avatarUrl: String(sessionObj['avatarUrl'] ?? ''),
        createdAt: Number(sessionObj['createdAt'] ?? 0),
      }
      this.sessions.set(token, session)
    }
  }

  flushNow(): void {
    this.flush()
  }

  private async flush(): Promise<void> {
    if (!this.dirty) return
    this.dirty = false
    const entries: Array<Array<Object>> = []
    const keys = Array.from(this.sessions.keys())
    for (const key of keys) {
      const session = this.sessions.get(key)
      if (session) {
        entries.push([key, session])
      }
    }
    await this.store.putJSON(KEY_SESSIONS, entries)
  }

  private generateToken(): string {
    const chars = '0123456789abcdef'
    let result = ''
    for (let i = 0; i < 64; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }
}

export const sessionStore = new SessionStore()
