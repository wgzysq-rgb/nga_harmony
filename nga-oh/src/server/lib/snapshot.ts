import { AsyncLocalStorage } from 'node:async_hooks';
import { appendFile, mkdir, readdir, stat, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

const SNAP_DIR = resolve(process.cwd(), 'data', 'snapshots');
const MAX_FILE_BYTES = 50 * 1024 * 1024;
const KEEP_DAYS = 7;

export interface SnapStore {
  snapId: string;
  api: string;
  reqParams: Record<string, string>;
  startMs: number;
  ngaRaw?: any;
  ngaUrl?: string;
  ngaParams?: Record<string, string>;
}

export const snapAls = new AsyncLocalStorage<SnapStore>();

let _enabled = false;

export function initSnapshot() {
  const envFlag = process.env.SNAPSHOT;
  if (envFlag === '0' || envFlag === 'false') {
    _enabled = false;
    return;
  }
  _enabled = true;
  if (!existsSync(SNAP_DIR)) mkdir(SNAP_DIR, { recursive: true }).catch(() => {});
  cleanOldFiles();
}

export function isEnabled(): boolean {
  return _enabled;
}

function genId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

export function createSnapStore(api: string, reqParams: Record<string, string>): SnapStore {
  return { snapId: genId(), api, reqParams, startMs: Date.now() };
}

export interface SnapEntry {
  id: string;
  ts: string;
  api: string;
  reqParams: Record<string, string>;
  ngaUrl: string;
  ngaParams: Record<string, string>;
  ngaRaw: any;
  responseToClient: any;
  duration: number;
  hasError: boolean;
  errorMsg?: string;
}

export function writeSnap(entry: SnapEntry) {
  if (!_enabled) return;
  const today = new Date().toISOString().slice(0, 10);
  const file = resolve(SNAP_DIR, `${today}.jsonl`);
  const line = JSON.stringify(entry) + '\n';
  stat(file).then(s => {
    if (s.size > MAX_FILE_BYTES) return;
    return appendFile(file, line, 'utf-8');
  }).catch(() => {
    return appendFile(file, line, 'utf-8');
  }).catch(() => {});
}

export function buildAndWriteSnap(
  store: SnapStore,
  responseToClient: any,
  hasError: boolean,
  errorMsg?: string,
) {
  const ngaRaw = store.ngaRaw;
  if (ngaRaw === undefined && !hasError) return;
  writeSnap({
    id: store.snapId,
    ts: new Date().toISOString(),
    api: store.api,
    reqParams: store.reqParams,
    ngaUrl: store.ngaUrl ?? '',
    ngaParams: store.ngaParams ?? {},
    ngaRaw: truncateLarge(ngaRaw),
    responseToClient: truncateLarge(responseToClient),
    duration: Date.now() - store.startMs,
    hasError,
    errorMsg,
  });
}

function truncateLarge(data: any): any {
  if (data === undefined || data === null) return data;
  const str = JSON.stringify(data);
  if (str && str.length > 500_000) {
    return { __truncated: true, __originalLength: str.length, __head: str.slice(0, 100_000) };
  }
  return data;
}

function cleanOldFiles() {
  const now = Date.now();
  readdir(SNAP_DIR).then((files: string[]) => {
    for (const f of files.filter(f => f.endsWith('.jsonl'))) {
      const dateStr = f.replace('.jsonl', '');
      const fileTime = new Date(dateStr).getTime();
      if (!isNaN(fileTime) && now - fileTime > KEEP_DAYS * 24 * 3600 * 1000) {
        rm(resolve(SNAP_DIR, f)).catch(() => {});
      }
    }
  }).catch(() => {});
}
