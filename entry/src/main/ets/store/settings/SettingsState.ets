import { ImageLoadStrategy, ThreadNavMode } from '../../common/constants/Constants'
import { FilterKeyword } from '../../model/FilterKeyword'
import type { UserNoteEntry } from '../../model/NoteInfo'

/** 收藏版块 */
export class FavBoard {
  fid: number = 0
  stid: number = 0
  name: string = ''
}

/** 黑名单条目 */
export interface BlacklistEntry {
  userId: string
  nickName: string
}

/**
 * 用户设置持久化根状态。
 *
 * 24 个字段对应 8 个设置域（主题/显示/媒体/阅读/社交列表/关键词屏蔽/便签/自动签到）。
 * 由各域子 store 通过共享引用直接读写，保持 @Observed 响应式不断。
 */
@Observed
export class SettingsState {
  blacklist: BlacklistEntry[] = []
  filterKeywords: FilterKeyword[] = []
  favorites: FavBoard[] = []
  fontSize: number = 15
  domainIndex: number = 0
  theme: string = 'light'
  autoCheckin: boolean = false
  lastCheckinDate: string = ''
  notes: UserNoteEntry[] = []
  holdingHand: number = 2
  smartGrip: boolean = true
  showSignature: boolean = true
  ttsPerson: number = 13
  ttsSpeed: number = 1.0
  ttsVolume: number = 1.0
  ttsPitch: number = 1.0
  imageLoadStrategy: string = ImageLoadStrategy.ALWAYS
  enableImageSizePrefetch: boolean = true
  threadNavMode: string = ThreadNavMode.SEAMLESS
  /** 预加载页数（0=关闭，1~5=向前预加载 N 页） */
  prefetchPageCount: number = 3
  /** 视频默认是否静音（全局开关，false=有声） */
  videoMuted: boolean = false
}
