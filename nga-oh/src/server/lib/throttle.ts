export interface ThrottleConfig {
  maxConcurrent: number;
  minInterval: number;
}

const DEFAULT_CONFIG: ThrottleConfig = {
  maxConcurrent: 6,
  minInterval: 150,
};

function loadConfigFromEnv(): Partial<ThrottleConfig> {
  const result: Partial<ThrottleConfig> = {};
  const envConcurrent = process.env.NGA_THROTTLE_CONCURRENT;
  const envInterval = process.env.NGA_THROTTLE_INTERVAL;
  if (envConcurrent !== undefined && envConcurrent !== '') {
    const n = parseInt(envConcurrent, 10);
    if (!Number.isNaN(n) && n >= 1) result.maxConcurrent = n;
  }
  if (envInterval !== undefined && envInterval !== '') {
    const n = parseInt(envInterval, 10);
    if (!Number.isNaN(n) && n >= 1) result.minInterval = n;
  }
  return result;
}

interface Bucket {
  concurrency: number;
  maxConcurrency: number;
  minInterval: number;
  lastDispatch: number;
  waiters: Array<{ resolve: () => void }>;
  drainTimer: ReturnType<typeof setTimeout> | null;
}

function createBucket(config: ThrottleConfig): Bucket {
  return {
    concurrency: 0,
    maxConcurrency: config.maxConcurrent,
    minInterval: config.minInterval,
    lastDispatch: 0,
    waiters: [],
    drainTimer: null,
  };
}

function tryDispatch(bucket: Bucket): void {
  if (bucket.drainTimer !== null) {
    clearTimeout(bucket.drainTimer);
    bucket.drainTimer = null;
  }

  while (bucket.waiters.length > 0 && bucket.concurrency < bucket.maxConcurrency) {
    const now = Date.now();
    const elapsed = now - bucket.lastDispatch;
    if (elapsed < bucket.minInterval) {
      bucket.drainTimer = setTimeout(() => {
        bucket.drainTimer = null;
        tryDispatch(bucket);
      }, bucket.minInterval - elapsed);
      return;
    }
    const waiter = bucket.waiters.shift()!;
    bucket.concurrency += 1;
    bucket.lastDispatch = now;
    waiter.resolve();
  }
}

function release(bucket: Bucket): void {
  if (bucket.concurrency <= 0) {
    console.warn('[Throttle] release called with concurrency <= 0, possible double release');
    return;
  }
  bucket.concurrency -= 1;
  if (bucket.waiters.length > 0) {
    tryDispatch(bucket);
  }
}

function acquire(bucket: Bucket): Promise<void> {
  if (bucket.concurrency < bucket.maxConcurrency) {
    const now = Date.now();
    const elapsed = now - bucket.lastDispatch;
    if (elapsed >= bucket.minInterval) {
      bucket.concurrency += 1;
      bucket.lastDispatch = now;
      return Promise.resolve();
    }
  }
  return new Promise<void>((resolve) => {
    bucket.waiters.push({ resolve });
    tryDispatch(bucket);
  });
}

function bucketStatus(bucket: Bucket): { running: number; queued: number } {
  return {
    running: bucket.concurrency,
    queued: bucket.waiters.length,
  };
}

export interface Throttler {
  acquire: (domain: string) => Promise<void>;
  release: (domain: string) => void;
  status: (domain?: string) => Record<string, { running: number; queued: number }>;
}

export function createThrottler(config?: Partial<ThrottleConfig>): Throttler {
  const resolved: ThrottleConfig = { ...DEFAULT_CONFIG, ...config, ...loadConfigFromEnv() };
  const buckets = new Map<string, Bucket>();

  function getBucket(domain: string): Bucket {
    let b = buckets.get(domain);
    if (!b) {
      b = createBucket(resolved);
      buckets.set(domain, b);
    }
    return b;
  }

  return {
    async acquire(domain: string) {
      await acquire(getBucket(domain));
    },
    release(domain: string) {
      release(getBucket(domain));
    },
    status(domain?: string) {
      if (domain) {
        return { [domain]: bucketStatus(getBucket(domain)) };
      }
      const result: Record<string, { running: number; queued: number }> = {};
      for (const [d] of buckets) {
        result[d] = bucketStatus(getBucket(d));
      }
      return result;
    },
  };
}

export const ngaThrottler = createThrottler();
