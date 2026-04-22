import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { BrowseHistoryEntry } from '../../shared/types/browse-history.js';

export type { BrowseHistoryEntry } from '../../shared/types/browse-history.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DATA_DIR = resolve(__dirname, '../../data');
const HISTORY_FILE = resolve(DATA_DIR, 'browse-history.json');
const MAX_COUNT = 500;

class BrowseHistoryStore {
  private data = new Map<string, BrowseHistoryEntry[]>();
  private dirty = false;

  constructor() {
    this.load();
    setInterval(() => this.flush(), 5_000);
    process.on('exit', () => this.flushSync());
  }

  get(uid: string): BrowseHistoryEntry[] {
    const list = this.data.get(uid);
    return list ? [...list] : [];
  }

  add(uid: string, entry: Omit<BrowseHistoryEntry, 'ts'>): void {
    let list = this.data.get(uid) ?? [];
    list = list.filter((h) => h.tid !== entry.tid);
    list.unshift({ ...entry, ts: Date.now() });
    if (list.length > MAX_COUNT) list = list.slice(0, MAX_COUNT);
    this.data.set(uid, list);
    this.dirty = true;
  }

  remove(uid: string, tid: string): void {
    const list = this.data.get(uid);
    if (!list) return;
    const filtered = list.filter((h) => h.tid !== tid);
    if (filtered.length !== list.length) {
      this.data.set(uid, filtered);
      this.dirty = true;
    }
  }

  clear(uid: string): void {
    this.data.delete(uid);
    this.dirty = true;
  }

  private load(): void {
    try {
      const raw = readFileSync(HISTORY_FILE, 'utf-8');
      const parsed: [string, BrowseHistoryEntry[]][] = JSON.parse(raw);
      for (const [uid, entries] of parsed) {
        this.data.set(uid, entries);
      }
      console.log(`[browse-history] loaded history for ${this.data.size} users`);
    } catch {
      console.log('[browse-history] no persisted data, starting fresh');
    }
  }

  flush(): void {
    if (!this.dirty) return;
    this.dirty = false;
    try {
      mkdirSync(DATA_DIR, { recursive: true });
      writeFileSync(HISTORY_FILE, this.serialize());
    } catch (err) {
      console.error('[browse-history] flush failed:', err);
    }
  }

  private flushSync(): void {
    if (!this.dirty) return;
    try {
      mkdirSync(DATA_DIR, { recursive: true });
      writeFileSync(HISTORY_FILE, this.serialize());
    } catch (err) {
      console.error('[browse-history] flushSync failed:', err);
    }
  }

  private serialize(): string {
    return JSON.stringify([...this.data.entries()]);
  }
}

export const browseHistoryStore = new BrowseHistoryStore();
