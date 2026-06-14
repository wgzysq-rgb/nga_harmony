/**
 * 基于 token-bucket 的请求限流器。
 *
 * 按 domain（通常为请求域名）分桶，每桶独立维护「最大并发数 + 最小调度间隔」双重约束：
 * - 并发上限：单 domain 同时进行的请求不超过 maxConcurrency；
 * - 最小间隔：同一 domain 内两次 dispatch 之间至少相隔 minInterval 毫秒。
 *
 * 典型用法：发起请求前 `await acquire(domain)` 取得执行许可，请求结束（无论成功/失败）
 * 后调用 `release(domain)` 释放槽位并唤醒等待者。
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

  /**
   * 构造限流器，设置各 domain 桶共享的默认并发与间隔参数。
   *
   * @param maxConcurrent - 单 domain 最大并发请求数
   * @param minInterval - 同一 domain 内两次 dispatch 的最小间隔（毫秒）
   */
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

  /**
   * 申请 domain 的执行许可：若当前并发未满且距上次 dispatch 已超过最小间隔，立即 resolve；
   * 否则进入等待队列，待有空闲槽位且间隔满足时被唤醒。调用方取得许可后执行请求，
   * 完成后必须调用 {@link release} 释放槽位。
   *
   * @param domain - 限流维度（通常为请求域名）
   * @returns 许可授予后 resolve 的 Promise
   */
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

  /**
   * 释放 domain 的一个并发槽位，并唤醒等待队列中的下一个请求。
   *
   * 必须与 {@link acquire} 配对调用：每次 acquire 返回的请求执行完毕后
   * （无论成功/失败）都应调用一次，否则槽位泄漏导致后续请求永久阻塞。
   *
   * @param domain - 限流维度（通常为请求域名）
   */
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

  /**
   * 查询指定 domain 的桶状态（活跃运行数与排队等待数）。
   *
   * @param domain - 限流维度（通常为请求域名）
   * @returns 桶状态；该 domain 从未被使用时返回全 0
   */
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
