import { type BoardSlot } from '../store/RouterStore'
import { TopicListPanel } from './TopicListPanel'
import { SearchPanel } from './SearchPanel'

@Component
export struct BoardPanelComponent {
  @Prop boardSlot: BoardSlot | null

  build() {
    Column() {
      if (this.boardSlot) {
        if (this.boardSlot.type === 'search') {
          SearchPanel()
        } else {
          TopicListPanel({
            boardFid: this.boardSlot.fid,
            boardName: this.boardSlot.name,
            boardStid: this.boardSlot.stid,
            showBack: false,
            isFavorites: this.boardSlot.fid === -9999,
            authorid: this.boardSlot.authorid,
            favor: this.boardSlot.favor,
            searchKey: this.boardSlot.searchKey,
            author: this.boardSlot.author,
            searchpost: this.boardSlot.searchpost
          })
        }
      }
    }
    .width('100%').height('100%')
  }
}
