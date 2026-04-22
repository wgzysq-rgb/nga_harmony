import { useState } from 'react'
import { useRouterStore } from '@/stores/router'
import { useAuthStore } from '@/stores/auth'
import { api } from '@/api/client'
import { motion } from 'framer-motion'

export default function LoginPage() {
  const resetAll = useRouterStore((s) => s.resetAll)
  const setAuth = useAuthStore((s) => s.setAuth)
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [loginToken, setLoginToken] = useState('')
  const [captchaId, setCaptchaId] = useState('')
  const [captchaImage, setCaptchaImage] = useState('')
  const [captcha, setCaptcha] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    if (!username || !password) {
      setError('请输入用户名和密码')
      return
    }

    setLoading(true)
    try {
      if (loginToken) {
        if (!captcha) { setError('请输入验证码'); setLoading(false); return }
        const res = await api.post<{
          ok: boolean; token?: string; user?: any; error?: string;
          needCaptcha?: boolean; loginToken?: string; captchaId?: string; captchaImage?: string;
        }>('/auth/login', { loginToken, captchaId, captcha })

        if (res.ok && res.token) {
          setAuth(res.token, res.user ?? null)
          resetAll()
        } else if (res.needCaptcha) {
          setLoginToken(res.loginToken ?? '')
          setCaptchaId(res.captchaId ?? '')
          setCaptchaImage(res.captchaImage ?? '')
          setError(res.error ?? '')
        } else {
          setError(res.error ?? '登录失败')
        }
      } else {
        const res = await api.post<{
          ok: boolean; token?: string; user?: any; error?: string;
          needCaptcha?: boolean; loginToken?: string; captchaId?: string; captchaImage?: string;
        }>('/auth/login', { username, password })

        if (res.ok && res.token) {
          setAuth(res.token, res.user ?? null)
          resetAll()
        } else if (res.needCaptcha) {
          setLoginToken(res.loginToken ?? '')
          setCaptchaId(res.captchaId ?? '')
          setCaptchaImage(res.captchaImage ?? '')
        } else {
          setError(res.error ?? '登录失败')
        }
      }
    } catch (err: any) {
      setError(err.message ?? '网络错误')
    } finally {
      setLoading(false)
    }
  }

  const handleInject = async () => {
    const input = document.createElement('input')
    input.type = 'file'
    input.accept = '.txt,.ini,.cfg'
    input.onchange = async () => {
      const file = input.files?.[0]
      if (!file) return
      setLoading(true)
      try {
        const content = await file.text()
        const res = await fetch('/api/auth/inject', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ content }),
        })
        const data = await res.json()
        if (data.ok && data.token) {
          setAuth(data.token, data.user ?? null)
          resetAll()
        } else {
          setError(data.error ?? '注入失败')
        }
      } catch (err: any) {
        setError(err.message ?? '注入失败')
      } finally {
        setLoading(false)
      }
    }
    input.click()
  }

  return (
    <div className="flex items-center justify-center min-h-dvh px-5 bg-bg-secondary">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: [0.2, 0.9, 0.3, 1] }}
        className="w-full max-w-[360px]"
      >
        <h1 className="text-[28px] font-bold text-center tracking-[12px] mb-10 text-text">N G A</h1>

        <form onSubmit={handleSubmit} className="flex flex-col gap-3">
          <input
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="用户名"
            autoComplete="username"
            className="w-full px-4 py-3 text-[17px] bg-bg-tertiary rounded-xl outline-none focus:ring-2 ring-primary transition-shadow"
          />
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="密码"
            autoComplete="current-password"
            className="w-full px-4 py-3 text-[17px] bg-bg-tertiary rounded-xl outline-none focus:ring-2 ring-primary transition-shadow"
          />

          {loginToken && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="space-y-3"
            >
              <p className="text-[13px] text-text-secondary">输入图形验证码(6字符)</p>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={captcha}
                  onChange={(e) => setCaptcha(e.target.value)}
                  placeholder="验证码"
                  maxLength={6}
                  autoFocus
                  className="flex-1 px-4 py-3 bg-bg-secondary rounded-lg outline-none focus:ring-2 ring-primary"
                />
                {captchaImage && (
                  <img
                    src={captchaImage}
                    alt="验证码"
                    className="w-[120px] h-[46px] rounded-lg bg-bg-secondary cursor-pointer object-cover"
                    onClick={async () => {
                      try {
                        const res = await api.get<{ ok: boolean; image: string; captchaId?: string }>(`/auth/captcha?id=${captchaId}`)
                        if (res.ok) {
                          setCaptchaImage(res.image)
                          if (res.captchaId) setCaptchaId(res.captchaId)
                        }
                      } catch {}
                    }}
                  />
                )}
              </div>
            </motion.div>
          )}

          {error && (
            <motion.p
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="text-destructive text-[13px] text-center"
            >
              {error}
            </motion.p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 text-[17px] font-semibold text-white bg-primary rounded-2xl mt-2 active:scale-[0.97] transition-transform disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {loading ? '...' : loginToken ? '继 续' : '登 录'}
          </button>
        </form>

        <div className="flex items-center my-4 text-text-tertiary text-[11px]">
          <div className="flex-1 h-px bg-separator-light" />
          <span className="px-3">或</span>
          <div className="flex-1 h-px bg-separator-light" />
        </div>

        <button
          onClick={handleInject}
          disabled={loading}
          className="w-full py-2.5 text-[13px] text-text-secondary bg-bg-tertiary rounded-2xl active:scale-[0.97] transition-transform disabled:opacity-60"
        >
          选择凭据文件注入
        </button>
      </motion.div>
    </div>
  )
}
