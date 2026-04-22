import { useState, useCallback } from 'react'
import { useNav } from '@/hooks/useNav'
import { useAuthStore } from '@/stores/auth'
import { useThemeStore } from '@/stores/theme'
import { useSettingsStore } from '@/stores/settings'
import { api } from '@/api/client'
import { cn } from '@/lib/utils'
import NavBar from '@/components/layout/NavBar'
import SettingRow from '@/components/SettingRow'
import { ActionSheet } from '@/components/ActionSheet'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Moon,
  Type,
  Globe,
  Ban,
  LogOut,
} from 'lucide-react'

const FONT_OPTIONS = [
  { label: '小', value: 13 },
  { label: '中', value: 15 },
  { label: '大', value: 17 },
  { label: '特大', value: 19 },
]

const DOMAIN_OPTIONS = [
  { label: 'bbs.nga.cn', value: 0 },
  { label: 'bbs.ngacn.cc', value: 1 },
  { label: 'nga.178.com', value: 2 },
]

function ToggleSwitch({ checked, onChange }: { checked: boolean; onChange: () => void }) {
  return (
    <button
      role="switch"
      aria-checked={checked}
      onClick={(e) => { e.stopPropagation(); onChange() }}
      className={cn(
        'relative w-[51px] h-[31px] rounded-full transition-colors duration-200 shrink-0',
        checked ? 'bg-primary' : 'bg-separator'
      )}
    >
      <motion.div
        layout
        transition={{ type: 'spring', stiffness: 500, damping: 30 }}
        className={cn(
          'absolute top-[2px] w-[27px] h-[27px] rounded-full bg-white shadow-sm',
          checked ? 'left-[22px]' : 'left-[2px]'
        )}
      />
    </button>
  )
}

export default function SettingsPage() {
  const { pushDetail, resetAll } = useNav()
  const logout = useAuthStore((s) => s.logout)
  const theme = useThemeStore((s) => s.theme)
  const toggleTheme = useThemeStore((s) => s.toggleTheme)
  const fontSize = useSettingsStore((s) => s.fontSize)
  const domainIndex = useSettingsStore((s) => s.domainIndex)
  const setFontSize = useSettingsStore((s) => s.setFontSize)
  const setDomainIndex = useSettingsStore((s) => s.setDomainIndex)

  const [sheetType, setSheetType] = useState<'font' | 'domain' | null>(null)
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false)

  const handleDomainChange = useCallback(
    async (index: number) => {
      try {
        const res = await api.post<{ ok: boolean }>('/settings/domain', {
          index: String(index),
        })
        if (res.ok) {
          setDomainIndex(index)
        }
      } catch {}
    },
    [setDomainIndex]
  )

  const handleLogout = useCallback(() => {
    logout()
    resetAll()
  }, [logout, resetAll])

  const domainLabel = DOMAIN_OPTIONS[domainIndex]?.label ?? 'bbs.nga.cn'
  const fontLabel = FONT_OPTIONS.find((f) => f.value === fontSize)?.label ?? '中'

  return (
    <>
      <NavBar showBack title="设置" />

      <div className="flex-1 pb-8 overflow-y-auto">
        <div className="mt-4 mx-4 bg-bg-tertiary rounded-xl overflow-hidden">
          <div className="relative">
            <SettingRow
              icon={<Moon size={17} className="text-white" />}
              iconColor="bg-[#5856D6]"
              label="深色模式"
              right={<ToggleSwitch checked={theme === 'dark'} onChange={toggleTheme} />}
              onClick={toggleTheme}
            />
            <div className="ml-[60px] h-[0.5px] bg-separator" />
            <SettingRow
              icon={<Type size={17} className="text-white" />}
              iconColor="bg-[#FF2D55]"
              label="字号"
              right={
                <span className="text-text-secondary text-[17px] mr-1">
                  {fontLabel}
                </span>
              }
              onClick={() => setSheetType('font')}
            />
            <div className="ml-[60px] h-[0.5px] bg-separator" />
            <SettingRow
              icon={<Globe size={17} className="text-white" />}
              iconColor="bg-[#5AC8FA]"
              label="NGA 域名"
              right={
                <span className="text-text-secondary text-[15px] mr-1">
                  {domainLabel}
                </span>
              }
              onClick={() => setSheetType('domain')}
            />
          </div>
        </div>

        <div className="mt-5 mx-4 bg-bg-tertiary rounded-xl overflow-hidden">
          <div className="relative">
            <SettingRow
              icon={<Ban size={17} className="text-white" />}
              iconColor="bg-text-secondary"
              label="黑名单管理"
              onClick={() => pushDetail({ type: 'blacklist' })}
            />
            <div className="ml-[60px] h-[0.5px] bg-separator" />
            <SettingRow
              icon={<LogOut size={17} className="text-white" />}
              iconColor="bg-destructive"
              label="退出登录"
              destructive
              onClick={() => setShowLogoutConfirm(true)}
            />
          </div>
        </div>
      </div>

      <AnimatePresence>
        {sheetType === 'font' && (
          <ActionSheet
            key="font-sheet"
            options={FONT_OPTIONS}
            selected={fontSize}
            onSelect={(val) => setFontSize(val as number)}
            onClose={() => setSheetType(null)}
          />
        )}
        {sheetType === 'domain' && (
          <ActionSheet
            key="domain-sheet"
            options={DOMAIN_OPTIONS}
            selected={domainIndex}
            onSelect={(val) => handleDomainChange(val as number)}
            onClose={() => setSheetType(null)}
          />
        )}
        {showLogoutConfirm && (
          <ConfirmDialog
            title="退出登录"
            message="确定要退出登录吗？"
            confirmLabel="退出"
            onConfirm={handleLogout}
            onCancel={() => setShowLogoutConfirm(false)}
          />
        )}
      </AnimatePresence>
    </>
  )
}
