import DOMPurify from 'dompurify'
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function escHtml(s: string): string {
  const d = document.createElement('div')
  d.textContent = s
  return d.innerHTML
}

export function escAttr(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
}

export function proxyUrl(url: string): string {
  if (!url) return url
  if (url.startsWith('/') || url.startsWith('data:')) return url
  return `/api/image-proxy?url=${encodeURIComponent(url)}`
}

export function getAvatarUrl(avatar: string, uid?: number | string): string {
  if (!avatar) return ''
  if (avatar.startsWith('http')) return proxyUrl(avatar)
  if (avatar.startsWith('/')) return proxyUrl(`https://img.nga.178.com${avatar}`)
  return proxyUrl(`https://img4.nga.178.com/ngabbs/nga_classic/avatar/${avatar}`)
}

export function formatTime(ts: number | string): string {
  if (!ts) return ''
  const numTs = typeof ts === 'string' ? Number(ts) : ts
  if (isNaN(numTs)) return String(ts)
  const d = new Date(numTs > 1e12 ? numTs : numTs * 1000)
  if (isNaN(d.getTime())) return String(ts)
  const diff = Date.now() - d.getTime()
  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
  if (diff < 2592000000) return `${Math.floor(diff / 86400000)}天前`
  const isThisYear = d.getFullYear() === new Date().getFullYear()
  if (isThisYear) {
    return `${d.getMonth() + 1}-${d.getDate()} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
  }
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${d.getDate()}`
}

export function fmtNum(n: string | number): string {
  const num = Number(n)
  if (isNaN(num)) return String(n)
  if (num >= 10000) return (num / 10000).toFixed(1) + 'w'
  if (num >= 1000) return (num / 1000).toFixed(1) + 'k'
  return String(num)
}

export function getOriginalUrl(url: string): string {
  if (url.startsWith('/api/image-proxy?')) {
    try {
      const params = new URLSearchParams(url.split('?')[1])
      const realUrl = params.get('url') || url
      const cleaned = decodeURIComponent(realUrl)
        .replace(/\.thumb_s\.\w+$/i, '')
        .replace(/\.thumb_m\.\w+$/i, '')
        .replace(/\.medium\.\w+$/i, '')
        .replace(/\.thumb\.\w+$/i, '')
      return `/api/image-proxy?url=${encodeURIComponent(cleaned)}`
    } catch {
      return url
    }
  }
  return url
    .replace(/\.thumb_s\.\w+$/i, '')
    .replace(/\.thumb_m\.\w+$/i, '')
    .replace(/\.medium\.\w+$/i, '')
    .replace(/\.thumb\.\w+$/i, '')
}

export function sanitize(html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'img', 'blockquote', 'span', 'div', 'font', 'u', 's', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li', 'table', 'tr', 'td', 'th', 'hr', 'pre', 'code', 'sub', 'sup', 'br'],
    ALLOWED_ATTR: ['href', 'src', 'alt', 'title', 'class', 'style', 'target', 'rel', 'color', 'size', 'width', 'height'],
    ALLOW_DATA_ATTR: false,
  })
}
