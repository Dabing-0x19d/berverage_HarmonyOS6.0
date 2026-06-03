/**
 * 编辑店铺饮品弹窗组件
 */
import { ShopDrinkRecord } from './ShopDrinkRecord'
import { ShopDrinkDao } from './ShopDrinkDao'

@Component
export struct EditShopDrinkSheet {
  @Prop shopId: number = 0
  @Prop shopName: string = ''
  @Prop drinks: ShopDrinkRecord[] = []

  // 新建饮品
  @State newDrinkName: string = ''
  @State newDrinkCaffeine: number = 0
  @State newDrinkCost: number = 15

  // 编辑饮品
  @State editingDrinkId: number = 0
  @State editingDrinkName: string = ''
  @State editingDrinkCaffeine: number = 0
  @State editingDrinkCost: number = 15

  private shopDrinkDao: ShopDrinkDao = new ShopDrinkDao()

  onClose: () => void = () => {}
  onSaved: () => void = () => {}

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(`编辑饮品 - ${this.shopName}`)
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
        Column({ space: 15 }) {
          // 新建饮品卡片
          Column() {
            Text("新建饮品")
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Start)
              .padding({ left: 16, bottom: 8, top: 10 })

            // 饮品名称输入
            TextInput({ placeholder: '输入饮品名称（必填）', text: this.newDrinkName })
              .width('90%')
              .height(44)
              .onChange((value: string) => {
                this.newDrinkName = value
              })
              .padding({ left: 12, right: 12 })

            // 咖啡因选择（滑动条）
            Row() {
              Text("咖啡因")
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
              Text("（健康成人每日单次不超过200mg；孕妇/哺乳期不超过200mg/天）")
                .fontSize(10)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .padding({ left: 16, top: 12, right: 16 })

            Row() {
              Text(`${this.newDrinkCaffeine}mg`)
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
                .width(60)
                .textAlign(TextAlign.End)
              Slider({
                value: this.newDrinkCaffeine,
                min: 0,
                max: 400,
                step: 5,
                style: SliderStyle.OutSet
              })
                .layoutWeight(1)
                .trackColor($r('app.color.border_color'))
                .selectedColor($r('app.color.tab_selected'))
                .onChange((value: number) => {
                  this.newDrinkCaffeine = value
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8 })

            // 金额选择（滑动条）
            Text("金额")
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Start)
              .padding({ left: 16, top: 12, right: 16 })

            Row() {
              Text(`¥${this.newDrinkCost.toFixed(1)}`)
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
                .width(60)
                .textAlign(TextAlign.End)
              Slider({
                value: this.newDrinkCost,
                min: 0,
                max: 50,
                step: 0.5,
                style: SliderStyle.OutSet
              })
                .layoutWeight(1)
                .trackColor($r('app.color.border_color'))
                .selectedColor($r('app.color.chart_concentration_normal'))
                .onChange((value: number) => {
                  this.newDrinkCost = value
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 10 })

            // 添加按钮
            Text("添加")
              .width('90%')
              .height(40)
              .fontSize(16)
              .fontColor(this.newDrinkName.trim() ? $r('app.color.text_on_primary') : $r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
              .backgroundColor(this.newDrinkName.trim() ? '#8D6B4F' : $r('app.color.button_disabled'))
              .borderRadius(20)
              .margin({ top: 8, bottom: 10 })
              .onClick(() => {
                if (this.newDrinkName.trim()) {
                  this.addNewDrink()
                }
              })
          }
          .width('94%')
          // .backgroundColor('#f2f2f7')
          .borderRadius(12)
          .padding({ bottom: 10 })

          // 已有饮品列表卡片
          if (this.drinks.length > 0) {
            Column() {
              Text("已有饮品（点击可编辑）")
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .textAlign(TextAlign.Start)
                .padding({ left: 16, top: 10, bottom: 8 })

              ForEach(this.drinks, (drink: ShopDrinkRecord) => {
                this.drinkItemBuilder(drink)
              }, (drink: ShopDrinkRecord) => drink.id.toString())
            }
            .width('94%')
            // .backgroundColor('#f2f2f7')
            .borderRadius(12)
          } else {
            Text("暂无饮品")
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .padding(20)
          }
        }
      }
      .scrollBarColor(Color.Transparent)
      .padding({ bottom: 60 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_secondary'))
  }

  // 饮品列表项构建器
  @Builder
  drinkItemBuilder(drink: ShopDrinkRecord) {
    Row() {
      if (this.editingDrinkId === drink.id) {
        // 编辑模式 - 显示编辑控件
        Column({ space: 8 }) {
          // 名称输入
          TextInput({ text: this.editingDrinkName, placeholder: '输入名称' })
            .width('100%')
            .height(36)
            .onChange((value: string) => {
              this.editingDrinkName = value
            })

          // 咖啡因选择（滑动条）
          Row() {
            Text("咖啡因")
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
            Text("（健康成人每日单次不超过200mg；孕妇/哺乳期不超过200mg/天）")
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding({ right: 16, top: 16 })

          Row() {
            Text(`${this.editingDrinkCaffeine}mg`)
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .width(60)
              .textAlign(TextAlign.End)
            Slider({
              value: this.editingDrinkCaffeine,
              min: 0,
              max: 400,
              step: 5,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .trackColor('#e5e5ea')
              .selectedColor('#4CAF50')
              .onChange((value: number) => {
                this.editingDrinkCaffeine = value
              })
          }
          .width('100%')
          .padding({ top: 8 })

          // 金额选择（滑动条）
          Text("金额")
            .fontSize(16)
            .fontColor('#000000')
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ top: 16 })

          Row() {
            Text(`¥${this.editingDrinkCost.toFixed(1)}`)
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .width(60)
              .textAlign(TextAlign.End)
            Slider({
              value: this.editingDrinkCost,
              min: 0,
              max: 50,
              step: 0.5,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .trackColor('#e5e5ea')
              .selectedColor('#81C784')
              .onChange((value: number) => {
                this.editingDrinkCost = value
              })
          }
          .width('100%')
          .padding({ top: 8 })

          // 操作按钮
          Row() {
            Text("保存")
              .fontSize(16)
              .fontColor(Color.White)
              .width(80)
              .height(40)
              .textAlign(TextAlign.Center)
              .backgroundColor('#7CB342') // 品牌色保持
              .borderRadius(8)
              .onClick(() => this.saveDrink(drink))

            Text("删除")
              .fontSize(16)
              .fontColor(Color.White)
              .width(80)
              .height(40)
              .textAlign(TextAlign.Center)
              .backgroundColor('#E57373') // 品牌色保持
              .borderRadius(8)
              .onClick(() => this.deleteDrink(drink))

            Text("取消")
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .width(80)
              .height(40)
              .textAlign(TextAlign.Center)
              .backgroundColor($r('app.color.button_disabled'))
              .borderRadius(8)
              .onClick(() => this.cancelEdit())
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .padding(12)
        .backgroundColor($r('app.color.background_secondary'))
      } else {
        // 显示模式
        Column() {
          Text(drink.drinkName)
            .fontSize(16)
            .width('100%')
            .textAlign(TextAlign.Start)

          Text(`咖啡因:${drink.caffeine}mg ¥${drink.cost.toFixed(1)}`)
            .fontSize(12)
            .fontColor('#8e8e93')
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ top: 2 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding({ left: 4 })

        // 编辑图标
        Text("编辑")
          .fontSize(16)
          .fontColor('#8D6B4F') // 品牌色保持
          .width(50)
          .height(36)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.editingDrinkId = drink.id
            this.editingDrinkName = drink.drinkName
            this.editingDrinkCaffeine = drink.caffeine
            this.editingDrinkCost = drink.cost
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.background_secondary'))
  }

  // 添加新饮品
  async addNewDrink(): Promise<void> {
    if (!this.newDrinkName.trim()) return

    const newDrink: ShopDrinkRecord = {
      id: 0,
      shopId: this.shopId,
      drinkName: this.newDrinkName.trim(),
      caffeine: this.newDrinkCaffeine,
      cost: this.newDrinkCost,
      sugar: 0,
      createTime: Date.now()
    }

    const rowId = await this.shopDrinkDao.insert(newDrink)
    if (rowId > 0) {
      this.newDrinkName = ''
      this.newDrinkCaffeine = 0
      this.newDrinkCost = 15
      this.onSaved()
    }
  }

  // 保存饮品
  async saveDrink(drink: ShopDrinkRecord): Promise<void> {
    if (!this.editingDrinkName.trim()) {
      this.cancelEdit()
      return
    }

    const updatedDrink: ShopDrinkRecord = {
      id: drink.id,
      shopId: drink.shopId,
      drinkName: this.editingDrinkName.trim(),
      caffeine: this.editingDrinkCaffeine,
      cost: this.editingDrinkCost,
      sugar: drink.sugar,
      createTime: drink.createTime
    }

    await this.shopDrinkDao.update(updatedDrink)
    this.cancelEdit()
    this.onSaved()
  }

  // 删除饮品
  async deleteDrink(drink: ShopDrinkRecord): Promise<void> {
    await this.shopDrinkDao.delete(drink.id)
    this.cancelEdit()
    this.onSaved()
  }

  // 取消编辑
  cancelEdit(): void {
    this.editingDrinkId = 0
    this.editingDrinkName = ''
    this.editingDrinkCaffeine = 0
    this.editingDrinkCost = 15
  }
}

// Builder函数参数接口
interface EditShopDrinkBuilderParams {
  shopId: number
  shopName: string
  drinks: ShopDrinkRecord[]
  onClose: () => void
  onSaved: () => void
}

// Builder函数，用于bindSheet
@Builder
export function editShopDrinkBuilder($$: EditShopDrinkBuilderParams) {
  EditShopDrinkSheet({
    shopId: $$.shopId,
    shopName: $$.shopName,
    drinks: $$.drinks,
    onClose: $$.onClose,
    onSaved: $$.onSaved
  })
}
