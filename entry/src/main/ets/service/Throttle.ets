/**
 * 基于 token-bucket 的请求限流器
 */

interface Bucket {
  concurrency: number;
  maxConcurrency: number;
  minInterval: number;
  lastDispatch: number;
  waiters: Array<() => void>;
  drainTimerId: number;
}

interface BucketStatus {
  running: number;
  queued: number;
}

const DEFAULT_MAX_CONCURRENT = 6;
const DEFAULT_MIN_INTERVAL = 150;

export class Throttler {
  private buckets: Map<string, Bucket> = new Map();
  private maxConcurrency: number;
  private minInterval: number;

  constructor(maxConcurrent: number = DEFAULT_MAX_CONCURRENT,
    minInterval: number = DEFAULT_MIN_INTERVAL) {
    this.maxConcurrency = maxConcurrent;
    this.minInterval = minInterval;
  }

  private getBucket(domain: string): Bucket {
    let b = this.buckets.get(domain);
    if (!b) {
      const newBucket: Bucket = {
        concurrency: 0,
        maxConcurrency: this.maxConcurrency,
        minInterval: this.minInterval,
        lastDispatch: 0,
        waiters: [],
        drainTimerId: -1,
      };
      this.buckets.set(domain, newBucket);
      b = newBucket;
    }
    return b;
  }

  private tryDispatch(bucket: Bucket): void {
    if (bucket.drainTimerId !== -1) {
      clearTimeout(bucket.drainTimerId);
      bucket.drainTimerId = -1;
    }

    while (bucket.waiters.length > 0 && bucket.concurrency < bucket.maxConcurrency) {
      const now = Date.now();
      const elapsed = now - bucket.lastDispatch;
      if (elapsed < bucket.minInterval) {
        bucket.drainTimerId = setTimeout(() => {
          bucket.drainTimerId = -1;
          this.tryDispatch(bucket);
        }, bucket.minInterval - elapsed);
        return;
      }
      const resolve = bucket.waiters.shift()!;
      bucket.concurrency += 1;
      bucket.lastDispatch = now;
      resolve();
    }
  }

  acquire(domain: string): Promise<void> {
    const bucket = this.getBucket(domain);

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
      bucket.waiters.push(() => resolve());
      this.tryDispatch(bucket);
    });
  }

  release(domain: string): void {
    const bucket = this.getBucket(domain);
    if (bucket.concurrency <= 0) {
      return;
    }
    bucket.concurrency -= 1;
    if (bucket.waiters.length > 0) {
      this.tryDispatch(bucket);
    }
  }

  getStatus(domain: string): BucketStatus {
    const bucket = this.buckets.get(domain);
    if (!bucket) {
      const empty: BucketStatus = { running: 0, queued: 0 };
      return empty;
    }
    const status: BucketStatus = { running: bucket.concurrency, queued: bucket.waiters.length };
    return status;
  }
}

export const ngaThrottler = new Throttler();
