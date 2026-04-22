import type { DetailEntry, DetailScreen } from '@/stores/router'
import ThreadPage from '@/pages/ThreadPage'
import ProfilePage from '@/pages/ProfilePage'
import NotificationPage from '@/pages/NotificationPage'
import MessageListPage from '@/pages/MessageListPage'
import MessageDetailPage from '@/pages/MessageDetailPage'
import SearchPage from '@/pages/SearchPage'
import BlacklistPage from '@/pages/BlacklistPage'
import TopicListPage from '@/pages/TopicListPage'
import SettingsPage from '@/pages/SettingsPage'
import BrowseHistoryPage from '@/pages/BrowseHistoryPage'

function DetailScreenRenderer({ screen }: { screen: DetailScreen }) {
  switch (screen.type) {
    case 'thread':
      return <ThreadPage tid={screen.tid} page={screen.page} pid={screen.pid} />
    case 'profile':
      return <ProfilePage uid={screen.uid} />
    case 'notifications':
      return <NotificationPage />
    case 'messages':
      return <MessageListPage />
    case 'messageDetail':
      return <MessageDetailPage mid={screen.mid} />
    case 'search':
      return <SearchPage />
    case 'blacklist':
      return <BlacklistPage />
    case 'authorPosts':
      return <TopicListPage authorid={screen.authorid} name={screen.name} searchpost={screen.searchpost} showBack />
    case 'favorites':
      return <TopicListPage fid="__favorites__" name="我的收藏" showBack />
    case 'browseHistory':
      return <BrowseHistoryPage />
    case 'settings':
      return <SettingsPage />
  }
}

export default function DetailPane({ entry }: { entry: DetailEntry }) {
  return <DetailScreenRenderer screen={entry.screen} />
}
