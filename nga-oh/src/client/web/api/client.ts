const BASE = '/api'

let _blacklist: string[] = []

export function setBlacklistHeader(ids: string[]) {
  _blacklist = ids
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem('nga_token')
  const headers: Record<string, string> = {
    ...(options.headers as Record<string, string> ?? {}),
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  if (_blacklist.length > 0) {
    headers['X-Blacklist'] = _blacklist.join(',')
  }

  const res = await fetch(`${BASE}${path}`, { ...options, headers })

  if (!res.ok) {
    if (res.status === 401) {
      localStorage.removeItem('nga_token')
      window.dispatchEvent(new CustomEvent('auth:unauthorized'))
    }
    const err = await res.json().catch(() => ({ error: 'Network Error' }))
    throw new Error(err.error ?? `HTTP ${res.status}`)
  }

  return res.json()
}

export const api = {
  get: <T>(path: string) => request<T>(path),

  post: <T>(path: string, body: Record<string, unknown>) =>
    request<T>(path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    }),
}
