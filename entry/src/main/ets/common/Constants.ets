/**
 * 颜色和常量定义
 */

// 主题色
export class AppColors {
  static readonly primary: string = '#C08A4A'
  static readonly primaryLight: string = '#FDF3E7'
  static readonly destructive: string = '#E45D4C'
  static readonly warning: string = '#E8933A'
  static readonly success: string = '#7BA05B'
  static readonly bg: string = '#FEFAF6'
  static readonly bgSecondary: string = '#F5EDE3'
  static readonly bgTertiary: string = '#FDF7F0'
  static readonly textPrimary: string = '#3E2A1D'
  static readonly textSecondary: string = '#9C8B7A'
  static readonly textTertiary: string = '#C4B5A0'
  static readonly separator: string = '#E8DCC8'
  static readonly dividerStrong: string = '#D0C0A8'
  static readonly white: string = '#FFFFFF'
  static readonly black: string = '#000000'
  static readonly overlay: string = '#33000000'
  static readonly overlayStrong: string = '#66000000'
  static readonly shadow: string = '#40000000'
  static readonly shadowLight: string = '#30000000'
  static readonly toastBg: string = '#CC000000'
  static readonly imageViewerBg: string = '#FF000000'
  static readonly warnBg: string = '#FFF2E5'
  static readonly warnBorder: string = '#E8B98A'
  static readonly warnText: string = '#A65D2E'
  static readonly chevron: string = '#C4B5A0'
  static readonly sheetIndicator: string = '#D4C8B0'
  static readonly quoteBorders: string[] = [
    'rgba(192, 138, 74, 0.3)',
    'rgba(192, 138, 74, 0.2)',
    'rgba(192, 138, 74, 0.12)',
  ]
}

// 深色模式颜色
export class AppColorsDark {
  static readonly primary: string = '#0A84FF'
  static readonly primaryLight: string = '#1C2B3A'
  static readonly destructive: string = '#FF453A'
  static readonly warning: string = '#FF9F0A'
  static readonly success: string = '#30D158'
  static readonly bg: string = '#000000'
  static readonly bgSecondary: string = '#1C1C1E'
  static readonly bgTertiary: string = '#2C2C2E'
  static readonly textPrimary: string = '#F2F2F7'
  static readonly textSecondary: string = '#98989D'
  static readonly textTertiary: string = '#636366'
  static readonly separator: string = '#38383A'
  static readonly dividerStrong: string = '#545458'
  static readonly white: string = '#FFFFFF'
  static readonly black: string = '#000000'
  static readonly overlay: string = '#33000000'
  static readonly overlayStrong: string = '#66000000'
  static readonly shadow: string = '#40000000'
  static readonly shadowLight: string = '#30000000'
  static readonly toastBg: string = '#CC000000'
  static readonly imageViewerBg: string = '#FF000000'
  static readonly warnBg: string = '#3D2E00'
  static readonly warnBorder: string = '#665500'
  static readonly warnText: string = '#FF9999'
  static readonly chevron: string = '#48484A'
  static readonly sheetIndicator: string = '#38383A'
  static readonly quoteBorders: string[] = [
    'rgba(10, 132, 255, 0.3)',
    'rgba(10, 132, 255, 0.2)',
    'rgba(10, 132, 255, 0.12)',
  ]
}

// 品牌图标背景色（不随主题变化）
export class IconColors {
  static readonly mail: string = '#007AFF'
  static readonly bell: string = '#FF3B30'
  static readonly star: string = '#FF9500'
  static readonly clock: string = '#8E8E93'
  static readonly checkin: string = '#34C759'
  static readonly settings: string = '#5856D6'
  static readonly moon: string = '#5856D6'
  static readonly textFields: string = '#FF2D55'
  static readonly globe: string = '#5AC8FA'
  static readonly block: string = '#8E8E93'
}

// 字号选项
export interface FontOption {
  label: string
  value: number
}

export const FONT_OPTIONS: FontOption[] = [
  { label: '小', value: 13 },
  { label: '中', value: 15 },
  { label: '大', value: 17 },
  { label: '特大', value: 19 },
]

// 域名选项
export interface DomainOption {
  label: string
  value: number
}

export const DOMAIN_OPTIONS: DomainOption[] = [
  { label: 'bbs.nga.cn', value: 0 },
  { label: 'ngabbs.com', value: 1 },
  { label: 'nga.178.com', value: 2 },
]

// 标题字体颜色映射
export const FONT_COLORS: Record<number, string> = {
  1: '#FF3B30',  // red
  2: '#C08A4A',  // gold
  4: '#34C759',  // green
  8: '#FF9500',  // orange
  16: '#8E8E93', // gray
}

// 排序模式
export interface SortMode {
  key: string
  label: string
}

export const SORT_MODES: SortMode[] = [
  { key: 'latest', label: '最新' },
  { key: 'recommend', label: '推荐' },
  { key: 'hot', label: '24h热门' },
]

// ============== 响应式断点 ==============

export class BreakpointConstants {
  static readonly BREAKPOINT_SM: string = 'sm'
  static readonly BREAKPOINT_MD: string = 'md'
  static readonly BREAKPOINT_LG: string = 'lg'
  static readonly CURRENT_BREAKPOINT: string = 'currentBreakpoint'
}

// 断点值工具类，根据当前断点返回不同值
export class BreakpointType<T> {
  readonly sm: T
  readonly md: T
  readonly lg: T

  constructor(sm: T, md: T, lg: T) {
    this.sm = sm
    this.md = md
    this.lg = lg
  }

  getValue(breakpoint: string): T {
    if (breakpoint === 'md') {
      return this.md
    }
    if (breakpoint === 'lg') {
      return this.lg
    }
    return this.sm
  }
}

// 通知类型映射
export interface NotiTypeInfo {
  label: string
  category: string // 'thread' | 'message'
}

export const NOTI_TYPE_MAP: Record<number, NotiTypeInfo> = {
  1: { label: '回复了你的主题', category: 'thread' },
  2: { label: '回复了你的帖子', category: 'thread' },
  3: { label: '评论了你的主题', category: 'thread' },
  4: { label: '评论了你的帖子', category: 'thread' },
  7: { label: '在主题中@了你', category: 'thread' },
  8: { label: '在帖子中@了你', category: 'thread' },
  10: { label: '给你发了私信', category: 'message' },
  11: { label: '回复了你的私信', category: 'message' },
}

export function getNotiIcon(type: number): Resource {
  const map: Record<number, Resource> = {
    1: $r('app.media.icon_chat_bubble'),
    2: $r('app.media.icon_chat_bubble'),
    3: $r('app.media.icon_chat_bubble'),
    4: $r('app.media.icon_chat_bubble'),
    7: $r('app.media.icon_at'),
    8: $r('app.media.icon_at'),
    10: $r('app.media.icon_mail'),
    11: $r('app.media.icon_mail'),
  }
  return map[type] || $r('app.media.icon_clipboard')
}
