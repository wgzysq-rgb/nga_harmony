import { useState, useCallback } from 'react'
import { useNav } from '@/hooks/useNav'
import { useQuery } from '@tanstack/react-query'
import { motion } from 'framer-motion'
import { Mail, FileText, Ban, MapPin, Calendar, Users, Award, Coins, Star, Shield, MessageCircle, Bell, CheckCircle, Settings, Clock } from 'lucide-react'
import { api } from '@/api/client'
import { cn, escHtml, formatTime, fmtNum, sanitize } from '@/lib/utils'
import NavBar from '@/components/layout/NavBar'
import Avatar from '@/components/Avatar'
import SettingRow from '@/components/SettingRow'
import { useSettingsStore } from '@/stores/settings'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/components/Toast'
import { useUnreadCounts } from '@/hooks/useUnreadCounts'
import type { UserProfile } from '../../../shared/types/index.ts'

interface ProfileResponse {
  ok: boolean
  data: UserProfile
}

function ProfileStat({ label, value, icon }: { label: string; value: string; icon: React.ReactNode }) {
  return (
    <div className="flex items-center gap-2 py-2">
      <div className="text-text-tertiary">{icon}</div>
      <span className="text-[14px] text-text-secondary">{label}</span>
      <span className="ml-auto text-[14px] text-text font-medium">{value}</span>
    </div>
  )
}

export default function ProfilePage({ uid, showBack = true }: { uid: string; showBack?: boolean }) {
  const { pushDetail } = useNav()
  const addBlacklist = useSettingsStore((s) => s.addBlacklist)
  const currentUser = useAuthStore((s) => s.currentUser)
  const isOwnProfile = currentUser?.uid === uid

  const { unreadNotifications, unreadMessages } = useUnreadCounts(isOwnProfile)
  const [checkinLoading, setCheckinLoading] = useState(false)
  const [checkinResult, setCheckinResult] = useState<string | null>(null)

  const handleCheckin = useCallback(async () => {
    setCheckinLoading(true)
    setCheckinResult(null)
    try {
      const res = await api.post<{ ok: boolean; error?: string }>('/checkin', {})
      if (res.ok) {
        setCheckinResult('签到成功')
      } else {
        setCheckinResult(res.error ?? '签到失败')
      }
    } catch (err: any) {
      setCheckinResult(err.message ?? '网络错误')
    } finally {
      setCheckinLoading(false)
      setTimeout(() => setCheckinResult(null), 3000)
    }
  }, [])

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['profile', uid],
    queryFn: async () => {
      const res = await api.get<ProfileResponse>(`/user/${uid}`)
      return res.data
    },
    enabled: !!uid,
  })

  const showToast = useToastStore((s) => s.showToast)

  const handleAddBlacklist = useCallback(() => {
    if (!data) return
    addBlacklist({ userId: String(data.uid), nickName: data.userName || `User${data.uid}` })
    showToast('已加入黑名单')
  }, [data, addBlacklist, showToast])

  const profile = data

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.2 }}
      className="flex flex-col h-full"
    >
      <NavBar showBack={showBack} title="用户资料" />

      {isLoading && (
        <div className="text-center py-20 text-text-secondary">加载中...</div>
      )}

      {isError && (
        <div className="text-center py-20 text-destructive">
          {(error as Error)?.message ?? '加载失败'}
        </div>
      )}

      {profile && (
        <div className="flex-1 pb-8 overflow-y-auto">
          <div className="flex flex-col items-center pt-6 pb-4 bg-bg-tertiary">
            <Avatar
              avatar={profile.avatarUrl}
              uid={profile.uid}
              name={profile.userName}
              size={80}
              className="ring-3 ring-bg-secondary"
            />
            <div className="mt-3 text-[20px] font-semibold">{escHtml(profile.userName)}</div>
            <div className="flex items-center gap-2 mt-1.5 text-[13px] text-text-secondary">
              {profile.group && (
                <span className="px-2 py-0.5 rounded bg-primary/10 text-primary font-medium text-[12px]">
                  {escHtml(profile.group)}
                </span>
              )}
              <span>UID: {escHtml(profile.uid)}</span>
              {profile.ipLoc && (
                <>
                  <span className="text-text-tertiary">·</span>
                  <span className="flex items-center gap-0.5">
                    <MapPin size={12} />
                    {escHtml(profile.ipLoc)}
                  </span>
                </>
              )}
            </div>
            {profile.title && (
              <div className="mt-1.5 text-[13px] text-text-tertiary">{escHtml(profile.title)}</div>
            )}
            {profile.honor && (
              <div className="mt-1 text-[12px] text-warning font-medium">{escHtml(profile.honor)}</div>
            )}
          </div>

          <div className="mx-4 mt-4 bg-bg-tertiary rounded-xl overflow-hidden">
            <div className="px-4">
              <ProfileStat
                label="发帖数"
                value={fmtNum(profile.posts)}
                icon={<MessageCircle size={16} />}
              />
              <div className="h-[0.5px] bg-separator" />
              <ProfileStat
                label="金钱"
                value={fmtNum(profile.money)}
                icon={<Coins size={16} />}
              />
              <div className="h-[0.5px] bg-separator" />
              <ProfileStat
                label="威望"
                value={fmtNum(profile.rvrc)}
                icon={<Award size={16} />}
              />
              <div className="h-[0.5px] bg-separator" />
              <ProfileStat
                label="注册日期"
                value={profile.regdate ? formatTime(profile.regdate) : '未知'}
                icon={<Calendar size={16} />}
              />
              <div className="h-[0.5px] bg-separator" />
              <ProfileStat
                label="会员组"
                value={profile.group || '普通会员'}
                icon={<Users size={16} />}
              />
              {profile.fame > 0 && (
                <>
                  <div className="h-[0.5px] bg-separator" />
                  <ProfileStat
                    label="声望"
                    value={fmtNum(profile.fame)}
                    icon={<Star size={16} />}
                  />
                </>
              )}
              {profile.followByNum > 0 && (
                <>
                  <div className="h-[0.5px] bg-separator" />
                  <ProfileStat
                    label="被关注"
                    value={String(profile.followByNum)}
                    icon={<Shield size={16} />}
                  />
                </>
              )}
            </div>
          </div>

          {profile.medal && (
            <div className="mx-4 mt-4 bg-bg-tertiary rounded-xl overflow-hidden px-4 py-3">
              <div className="text-[13px] text-text-secondary mb-1">勋章</div>
              <div
                className="text-[14px] text-text [&_img]:inline [&_img]:max-w-full [&_img]:h-auto"
                dangerouslySetInnerHTML={{ __html: sanitize(profile.medal) }}
              />
            </div>
          )}

          {profile.sign && (
            <div className="mx-4 mt-4 bg-bg-tertiary rounded-xl overflow-hidden px-4 py-3">
              <div className="text-[13px] text-text-secondary mb-1">签名</div>
              <div
                className="text-[14px] text-text leading-relaxed [&_img]:inline [&_img]:max-w-full [&_img]:h-auto [&_a]:text-primary [&_a]:underline"
                dangerouslySetInnerHTML={{ __html: sanitize(profile.sign) }}
              />
            </div>
          )}

          {profile.reputationEntryList && profile.reputationEntryList.length > 0 && (
            <div className="mx-4 mt-4 bg-bg-tertiary rounded-xl overflow-hidden">
              <div className="px-4 pt-3 pb-1 text-[13px] font-semibold text-text-secondary">
                威望记录
              </div>
              {profile.reputationEntryList.map((entry, i) => (
                <div key={i} className="px-4 py-2 border-t border-separator first:border-t-0">
                  <div className="flex items-center justify-between">
                    <span className={cn(
                      'text-[13px] font-medium',
                      entry.reputation! > 0 ? 'text-success' : entry.reputation! < 0 ? 'text-destructive' : 'text-text-tertiary'
                    )}>
                      {entry.reputation! > 0 ? '+' : ''}{entry.reputation}
                    </span>
                    <span className="text-[12px] text-text-tertiary">
                      {entry.time ? formatTime(entry.time) : ''}
                    </span>
                  </div>
                  {entry.topicSubject && (
                    <div className="text-[13px] text-text mt-0.5 truncate">{escHtml(entry.topicSubject)}</div>
                  )}
                  {entry.postContent && (
                    <div className="text-[12px] text-text-tertiary mt-0.5 line-clamp-2">{escHtml(entry.postContent)}</div>
                  )}
                  <div className="text-[12px] text-text-tertiary mt-0.5">来自: {escHtml(entry.author ?? '')}</div>
                </div>
              ))}
            </div>
          )}

          {isOwnProfile ? (
            <div className="mx-4 mt-6 bg-bg-tertiary rounded-xl overflow-hidden">
              <SettingRow
                icon={<Mail size={17} className="text-white" />}
                iconColor="bg-primary"
                label="私信"
                right={unreadMessages > 0 ? (
                  <span className="bg-destructive text-white text-[12px] font-semibold rounded-full min-w-[20px] h-[20px] flex items-center justify-center px-1.5">
                    {unreadMessages > 99 ? '99+' : unreadMessages}
                  </span>
                ) : undefined}
                onClick={() => pushDetail({ type: 'messages' })}
              />
              <div className="ml-[60px] h-[0.5px] bg-separator" />
              <SettingRow
                icon={<Bell size={17} className="text-white" />}
                iconColor="bg-destructive"
                label="通知"
                right={unreadNotifications > 0 ? (
                  <span className="bg-destructive text-white text-[12px] font-semibold rounded-full min-w-[20px] h-[20px] flex items-center justify-center px-1.5">
                    {unreadNotifications > 99 ? '99+' : unreadNotifications}
                  </span>
                ) : undefined}
                onClick={() => pushDetail({ type: 'notifications' })}
              />
              <div className="ml-[60px] h-[0.5px] bg-separator" />
              <SettingRow
                icon={<Star size={17} className="text-white" />}
                iconColor="bg-warning"
                label="收藏主题"
                onClick={() => pushDetail({ type: 'favorites' })}
              />
              <div className="ml-[60px] h-[0.5px] bg-separator" />
              <SettingRow
                icon={<Clock size={17} className="text-white" />}
                iconColor="bg-[#8E8E93]"
                label="浏览历史"
                onClick={() => pushDetail({ type: 'browseHistory' })}
              />
              <div className="ml-[60px] h-[0.5px] bg-separator" />
              <SettingRow
                icon={<CheckCircle size={17} className="text-white" />}
                iconColor="bg-success"
                label={checkinLoading ? '签到中...' : checkinResult ?? '每日签到'}
                onClick={handleCheckin}
              />
              <div className="ml-[60px] h-[0.5px] bg-separator" />
              <SettingRow
                icon={<Settings size={17} className="text-white" />}
                iconColor="bg-[#5856D6]"
                label="设置"
                onClick={() => pushDetail({ type: 'settings' })}
              />
            </div>
          ) : (
            <div className="mx-4 mt-6 flex gap-3">
              <button
                onClick={() => pushDetail({ type: 'messages' })}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-primary text-white rounded-xl text-[15px] font-medium active:scale-[0.97] transition-transform"
              >
                <Mail size={17} />
                发私信
              </button>
              <button
                onClick={() => pushDetail({ type: 'authorPosts', authorid: profile.uid, name: profile.userName + '的主题' })}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-bg-tertiary text-text rounded-xl text-[15px] font-medium active:scale-[0.97] transition-transform"
              >
                <FileText size={17} />
                主题
              </button>
              <button
                onClick={() => pushDetail({ type: 'authorPosts', authorid: profile.uid, name: profile.userName + '的回帖', searchpost: true })}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-bg-tertiary text-text rounded-xl text-[15px] font-medium active:scale-[0.97] transition-transform"
              >
                <FileText size={17} />
                回帖
              </button>
              <button
                onClick={handleAddBlacklist}
                className="flex items-center justify-center gap-2 px-4 py-2.5 bg-bg-tertiary text-destructive rounded-xl text-[15px] font-medium active:scale-[0.97] transition-transform"
              >
                <Ban size={17} />
                加黑
              </button>
            </div>
          )}
        </div>
      )}

    </motion.div>
  )
}
