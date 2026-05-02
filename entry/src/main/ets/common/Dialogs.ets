/**
 * 确认对话框 + ActionSheet 组件
 */
import { AppColors } from '../common/Constants'

// 确认对话框
@CustomDialog
export struct ConfirmDialog {
  controller: CustomDialogController
  @Prop title: string = ''
  @Prop message: string = ''
  @Prop confirmLabel: string = '确定'
  @Prop destructive: boolean = false
  onConfirm?: () => void
  onCancel?: () => void
  icon?: Resource

  build() {
    Column() {
      if (this.icon !== undefined) {
        Image(this.icon).width(36).height(36).fillColor(AppColors.destructive)
          .margin({ top: 24, bottom: 12 })
      }

      Text(this.title)
        .fontSize(17)
        .fontColor(AppColors.textPrimary)
        .fontWeight(FontWeight.Bold)
        .margin({ top: this.icon !== undefined ? 0 : 20, bottom: 8 })

      Text(this.message)
        .fontSize(14)
        .fontColor(AppColors.textSecondary)
        .margin({ bottom: 20 })
        .textAlign(TextAlign.Center)

      Divider().color(AppColors.separator)

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(Color.Transparent)
          .fontColor(AppColors.primary)
          .onClick(() => {
            this.controller.close()
            if (this.onCancel) this.onCancel()
          })

        Divider().vertical(true).height(24).color(AppColors.separator)

        Button(this.confirmLabel)
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.destructive ? AppColors.destructive : Color.Transparent)
          .fontColor(this.destructive ? AppColors.white : AppColors.primary)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.controller.close()
            if (this.onConfirm) this.onConfirm()
          })
      }
    }
    .constraintSize({ maxWidth: 340, minWidth: 260 })
    .padding({ left: 20, right: 20 })
      .backgroundColor(AppColors.bgTertiary)
    .borderRadius(14)
    .alignItems(HorizontalAlign.Center)
  }
}

// ActionSheet 选项接口
export interface ActionOption {
  label: string
  value: number
}

// ActionSheet
@CustomDialog
export struct ActionSheetDialog {
  controller: CustomDialogController
  @Prop title: string = ''
  options: ActionOption[] = []
  selected: number = 0
  onSelect?: (value: number) => void
  onCancel?: () => void
  getLabelFontSize?: (value: number) => number

  build() {
    Column() {
      // 拖拽指示条
      Divider()
        .width(36)
        .height(4)
        .borderRadius(2)
        .color(AppColors.sheetIndicator)
        .margin({ top: 8, bottom: 12 })

      Text(this.title)
        .fontSize(15)
        .fontColor(AppColors.textSecondary)
        .margin({ bottom: 4 })

      // 选项列表
      List() {
        ForEach(this.options, (opt: ActionOption) => {
          ListItem() {
            Row() {
              Text(opt.label)
                .fontSize(this.getLabelFontSize ? this.getLabelFontSize(opt.value) : 17)
                .fontColor(AppColors.textPrimary)
                .fontWeight(opt.value === this.selected ? FontWeight.Medium : FontWeight.Regular)
                .layoutWeight(1)

              if (opt.value === this.selected) {
                Image($r('app.media.icon_checkmark'))
                  .width(18).height(18).fillColor(AppColors.primary)
              }
            }
            .width('100%')
            .height(52)
            .padding({ left: 20, right: 20 })
            .backgroundColor(opt.value === this.selected ? AppColors.primaryLight : Color.Transparent)
            .onClick(() => {
              this.controller.close()
              if (this.onSelect) this.onSelect(opt.value)
            })
          }
        })
      }
      .width('100%')
      .divider({ strokeWidth: 0.5, color: AppColors.separator })

      // 取消按钮
      Divider().color(AppColors.separator).margin({ top: 8 })
      Button('取消')
        .width('100%')
        .height(50)
        .backgroundColor(Color.Transparent)
        .fontColor(AppColors.primary)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          this.controller.close()
          if (this.onCancel) this.onCancel()
        })
    }
    .width('100%').constraintSize({ maxWidth: 420 })
      .backgroundColor(AppColors.bgTertiary)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .padding({ bottom: 20 })
  }
}
