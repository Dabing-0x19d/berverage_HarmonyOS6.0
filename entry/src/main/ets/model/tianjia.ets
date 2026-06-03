/**
 * 添加记录底部弹窗组件
 */
import { ShopDrinkRecord } from './ShopDrinkRecord'

// 糖分选项
interface SugarOption {
  name: string
  sugar: number
}

const SUGAR_OPTIONS: SugarOption[] = [
  { name: '无糖', sugar: 0 },
  { name: '少少糖', sugar: 3 },
  { name: '少糖', sugar: 5 },
  { name: '五分糖', sugar: 8 },
  { name: '七分糖', sugar: 12 },
  { name: '全糖', sugar: 15 }
]

@Component
export struct TianjiaSheet {
  // 传入的数据（使用Link双向绑定以响应变化）
  @Link shops: string[]
  @Link shopDrinks: ShopDrinkRecord[]
  @Link selectedShop: string
  @Link selectedDrink: string
  @Link selectedSugar: number

  // 回调函数
  onClose: () => void = () => {}
  onConfirm: () => void = () => {}
  onShopChanged: (shopName: string) => void = () => {}

  // 处理店铺选择
  handleShopSelect(shopName: string) {
    this.selectedShop = shopName
    this.selectedDrink = ''
    if (this.onShopChanged) {
      this.onShopChanged(shopName)
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text("添加记录")
          .fontSize(17)
          .fontWeight(FontWeight.Bold)

        Text("关闭")
          .fontSize(15)
          .fontColor($r('app.color.tab_selected'))
          .onClick(() => this.onClose())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20, top: 14, bottom: 12 })
      .border({ width: { bottom: 0.5 }, color: $r('app.color.divider_color') })

      Scroll() {
        Column({ space: 20 }) {
          // 选择咖啡店（横向滑动）
          Column() {
            Text("选择咖啡店")
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Start)
              .padding({ left: 16, bottom: 12, top: 10 })

            Scroll() {
              Row({ space: 10 }) {
                ForEach(this.shops, (item: string) => {
                  Column() {
                    Text(item)
                      .fontSize(15)
                    if (this.selectedShop === item) {
                      Row()
                        .width(8)
                        .height(8)
                        .backgroundColor('#4CAF50')
                        .borderRadius(4)
                        .margin({ top: 4 })
                    }
                  }
                  .width(100)
                  .height(50)
                  .justifyContent(FlexAlign.Center)
                  .padding({ left: 8, right: 8 })
                  .onClick(() => {
                    this.handleShopSelect(item)
                  })
                }, (item: string) => item)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBarColor(Color.Transparent)
            .scrollBarWidth(0)
            .padding({ left: 16, right: 16 })
          }

          // 选择饮品（横向滑动）- 只在选择了店铺后显示
          if (this.selectedShop && this.shopDrinks.length > 0) {
            Column() {
              Text("选择饮品")
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .textAlign(TextAlign.Start)
                .padding({ left: 16, bottom: 12, top: 10 })

              Scroll() {
                Row({ space: 10 }) {
                  ForEach(this.shopDrinks, (item: ShopDrinkRecord) => {
                    Column() {
                      Text(item.drinkName)
                        .fontSize(15)
                      if (this.selectedDrink === item.drinkName) {
                        Row()
                          .width(8)
                          .height(8)
                          .backgroundColor('#4CAF50')
                          .borderRadius(4)
                          .margin({ top: 4 })
                      }
                    }
                    .width(90)
                    .height(50)
                    .justifyContent(FlexAlign.Center)
                    .padding({ left: 8, right: 8 })
                    .onClick(() => {
                      this.selectedDrink = item.drinkName
                    })
                  }, (item: ShopDrinkRecord) => item.id.toString())
                }
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBarColor(Color.Transparent)
              .scrollBarWidth(0)
              .padding({ left: 16, right: 16 })
            }
          } else if (this.selectedShop && this.shopDrinks.length === 0) {
            // 店铺已选择但没有饮品
            Column() {
              Text("该店铺暂无可选饮品")
                .fontSize(14)
                .fontColor($r('app.color.chart_safety_line'))
                .padding({ left: 16, top: 10 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }

          // 选择糖度（横向滑动）
          Column() {
            Text("选择糖度")
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Start)
              .padding({ left: 16, bottom: 12, top: 10 })

            Scroll() {
              Row({ space: 10 }) {
                ForEach(SUGAR_OPTIONS, (item: SugarOption) => {
                  Column() {
                    Text(`${item.name}`)
                      .fontSize(15)
                    if (this.selectedSugar === item.sugar) {
                      Row()
                        .width(8)
                        .height(8)
                        .backgroundColor('#4CAF50')
                        .borderRadius(4)
                        .margin({ top: 4 })
                    }
                  }
                  .width(80)
                  .height(48)
                  .justifyContent(FlexAlign.Center)
                  .padding({ left: 8, right: 8 })
                  .onClick(() => {
                    this.selectedSugar = item.sugar
                  })
                }, (item: SugarOption) => item.sugar.toString())
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBarColor(Color.Transparent)
            .scrollBarWidth(0)
            .padding({ left: 16, right: 16, bottom: 20 })
          }
        }
      }
      .scrollBarColor(Color.Transparent)

      // 确认按钮
      Text("确认添加")
        .width('90%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.selectedShop && this.selectedDrink ? $r('app.color.text_on_primary') : $r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .backgroundColor(this.selectedShop && this.selectedDrink ? $r('app.color.tab_selected') : $r('app.color.button_disabled'))
        .borderRadius(24)
        .margin({ top: 16, bottom: 40 })
        .onClick(() => this.onConfirm())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_secondary'))
  }
}

export interface DrinkItem {
  name: string
  icon: string
  caffeine: number
  cost: number
  sugar: number
}
