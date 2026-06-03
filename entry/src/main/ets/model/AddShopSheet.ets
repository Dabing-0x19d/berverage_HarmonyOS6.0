/**
 * 添加店铺弹窗组件
 */

@Component
export struct AddShopSheet {
  onAdd: (shopName: string) => void = () => {}
  onClose: () => void = () => {}

  @State newShopName: string = ''

  build() {
    Column() {
      // 标题栏
      Row() {
        Text("添加店铺")
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
        Text("关闭")
          .fontSize(15)
          .fontColor($r('app.color.tab_selected'))
          .onClick(() => {
            this.onClose()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20, top: 14, bottom: 12 })
      .border({ width: { bottom: 0.5 }, color: $r('app.color.divider_color') })

      // 输入框
      TextInput({ placeholder: '输入店铺名称', text: this.newShopName })
        .width('90%')
        .height(44)
        .onChange((value: string) => {
          this.newShopName = value
        })
        .padding({ left: 12, right: 12 })
        .margin({ top: 20 })

      // 添加按钮
      Text("添加")
        .width('90%')
        .height(40)
        .fontSize(16)
        .fontColor($r('app.color.text_on_primary'))
        .textAlign(TextAlign.Center)
        .backgroundColor(this.newShopName.trim() ? '#8D6B4F' : $r('app.color.button_disabled'))
        .borderRadius(20)
        .margin({ top: 20 })
        .onClick(() => {
          if (this.newShopName.trim()) {
            this.onAdd(this.newShopName.trim())
          }
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_secondary'))
  }
}

// Builder函数参数接口
interface AddShopBuilderParams {
  onAdd: (shopName: string) => void
  onClose: () => void
}

// Builder函数，用于bindSheet
@Builder
export function addShopBuilder($$: AddShopBuilderParams) {
  AddShopSheet({
    onAdd: $$.onAdd,
    onClose: $$.onClose
  })
}
