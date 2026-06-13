import media from '@ohos.multimedia.media'
import { ImageSize } from './ImageSizeUtil'
import { LruCache } from '../cache/LruCache'
import { RequestQueue } from '../concurrency/RequestQueue'

const cache: LruCache<ImageSize> = new LruCache<ImageSize>(100)
const pending: Map<string, Promise<ImageSize | null>> = new Map()

/** 视频元数据获取超时(毫秒) */
const FETCH_TIMEOUT: number = 15000

/** 视频尺寸预取并发上限 */
const MAX_CONCURRENT: number = 4
const queue: RequestQueue = new RequestQueue(MAX_CONCURRENT)

function applyOrientation(size: ImageSize, orientation: number): ImageSize {
  if (orientation === 90 || orientation === 270) {
    const w: number = size.width
    size.width = size.height
    size.height = w
  }
  return size
}

async function doFetch(url: string): Promise<ImageSize | null> {
  let extractor: media.AVMetadataExtractor | null = null
  try {
    extractor = await media.createAVMetadataExtractor()
    extractor.setUrlSource(url)
    const metadata: media.AVMetadata = await new Promise<media.AVMetadata>(
      (resolve: (value: media.AVMetadata) => void, reject: (reason?: Object) => void) => {
        const timer: number = setTimeout(() => {
          reject(new Error('获取视频元数据超时'))
        }, FETCH_TIMEOUT)
        extractor!.fetchMetadata().then((m: media.AVMetadata) => {
          clearTimeout(timer)
          resolve(m)
        }, (err: Object) => {
          clearTimeout(timer)
          reject(err)
        })
      }
    )
    const w: number = Number(metadata.videoWidth) || 0
    const h: number = Number(metadata.videoHeight) || 0
    if (w > 0 && h > 0) {
      const s: ImageSize = new ImageSize()
      s.width = w
      s.height = h
      const orient: number = Number(metadata.videoOrientation) || 0
      applyOrientation(s, orient)
      cache.set(url, s)
      return s
    }
    return null
  } catch (e) {
    return null
  } finally {
    if (extractor) {
      try {
        extractor.release()
      } catch (e) {
      }
    }
    queue.done()
  }
}

function startFetch(url: string): Promise<ImageSize | null> {
  return new Promise<ImageSize | null>((resolve: (value: ImageSize | null) => void) => {
    queue.schedule(() => {
      doFetch(url).then((result: ImageSize | null) => {
        resolve(result)
      }, () => {
        resolve(null)
      })
    })
  })
}

export function getCachedVideoSize(url: string): ImageSize | null {
  const r: ImageSize | undefined = cache.get(url)
  if (r) {
    return r
  }
  return null
}

export async function fetchVideoSize(url: string): Promise<ImageSize | null> {
  const cached: ImageSize | null = getCachedVideoSize(url)
  if (cached) return cached
  const p: Promise<ImageSize | null> | undefined = pending.get(url)
  if (p) return p
  const promise: Promise<ImageSize | null> = startFetch(url)
  pending.set(url, promise)
  const result: ImageSize | null = await promise
  pending.delete(url)
  return result
}
