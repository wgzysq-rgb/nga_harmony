import media from '@ohos.multimedia.media'
import { ImageSize } from './ImageSizeUtil'

const cache: Map<string, ImageSize> = new Map()
const pending: Map<string, Promise<ImageSize | null>> = new Map()
const MAX_CACHE_SIZE: number = 100
const cacheOrder: string[] = []

function touchCache(url: string): void {
  for (let i: number = 0; i < cacheOrder.length; i++) {
    if (cacheOrder[i] === url) {
      cacheOrder.splice(i, 1)
      break
    }
  }
  cacheOrder.push(url)
}

function trimCache(): void {
  while (cache.size > MAX_CACHE_SIZE) {
    const oldest: string | undefined = cacheOrder.shift()
    if (oldest !== undefined) {
      cache.delete(oldest)
    }
  }
}

function applyOrientation(size: ImageSize, orientation: number): ImageSize {
  if (orientation === 90 || orientation === 270) {
    const w: number = size.width
    size.width = size.height
    size.height = w
  }
  return size
}

const MAX_CONCURRENT: number = 4
let activeCount: number = 0
const requestQueue: (() => void)[] = []

function scheduleRequest(run: () => void): void {
  if (activeCount < MAX_CONCURRENT) {
    activeCount++
    run()
  } else {
    requestQueue.push(run)
  }
}

function onRequestDone(): void {
  activeCount--
  while (requestQueue.length > 0 && activeCount < MAX_CONCURRENT) {
    const next: (() => void) | undefined = requestQueue.shift()
    if (next) {
      activeCount++
      next()
    }
  }
}

async function doFetch(url: string): Promise<ImageSize | null> {
  let extractor: media.AVMetadataExtractor | null = null
  try {
    extractor = await media.createAVMetadataExtractor()
    extractor.setUrlSource(url)
    const metadata: media.AVMetadata = await extractor.fetchMetadata()
    const w: number = Number(metadata.videoWidth) || 0
    const h: number = Number(metadata.videoHeight) || 0
    if (w > 0 && h > 0) {
      const s: ImageSize = new ImageSize()
      s.width = w
      s.height = h
      const orient: number = Number(metadata.videoOrientation) || 0
      applyOrientation(s, orient)
      cache.set(url, s)
      touchCache(url)
      trimCache()
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
    onRequestDone()
  }
}

function startFetch(url: string): Promise<ImageSize | null> {
  return new Promise<ImageSize | null>((resolve: (value: ImageSize | null) => void) => {
    scheduleRequest(() => {
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
    touchCache(url)
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
