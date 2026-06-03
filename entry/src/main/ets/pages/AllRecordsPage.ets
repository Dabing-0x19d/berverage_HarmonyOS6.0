import { router } from '@kit.ArkUI';
import { Font } from "@kit.ArkUI";
import { CoffeeDao } from "../model/CoffeeDao.ets";
import { CoffeeRecord } from "../model/CoffeeRecord";
import { CoffeeDatabase } from "../model/CoffeeDatabase";

// 月份选项
const MONTH_OPTIONS: string[] = ['全部', '1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']

@Entry
@Component
export struct AllRecordsPage {

  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;


  @State allRecords: CoffeeRecord[] = []
  @State filteredRecords: CoffeeRecord[] = []
  @State selectedMonthIndex: number = 0 // 0=全部, 1-12=1-12月

  private coffeeDao: CoffeeDao = new CoffeeDao()
  private currentYear: number = new Date().getFullYear()

  async aboutToAppear(): Promise<void> {
    await CoffeeDatabase.init(getContext(this))
    await this.loadRecords()
  }

  async loadRecords(): Promise<void> {
    const records = await this.coffeeDao.queryAll()
    this.allRecords = records.sort((a, b) => b.createTime - a.createTime)
    this.filterByMonth()
  }

  filterByMonth(): void {
    if (this.selectedMonthIndex === 0) {
      // 全部
      this.filteredRecords = this.allRecords
    } else {
      const month = this.selectedMonthIndex // 1-12
      this.filteredRecords = this.allRecords.filter(record => {
        const date = new Date(record.createTime)
        return date.getMonth() + 1 === month && date.getFullYear() === this.currentYear
      })
    }
  }

  selectMonth(index: number): void {
    this.selectedMonthIndex = index
    this.filterByMonth()
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const month = date.getMonth() + 1
    const day = date.getDate()
    const hour = date.getHours().toString().padStart(2, '0')
    const minute = date.getMinutes().toString().padStart(2, '0')
    return `${month}月${day}日 ${hour}:${minute}`
  }

  build() {
    Column() {
      // 标题栏（避让状态栏）
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor($r('app.color.text_primary'))
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            // 返回上一页
            router.back()
          })

        Text("全部记录")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('')
          .width(40)
      }
      .width('100%')
      .height(50)
      .padding({ left: 10, right: 10 })
      .backgroundColor($r('app.color.background_primary'))

      // 月份选择条
      Scroll() {
        Row({ space: 10 }) {
          ForEach(MONTH_OPTIONS, (item: string, index: number) => {
            Column() {
              Text(item)
                .fontSize(14)
                .fontColor(this.selectedMonthIndex === index ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
              if (this.selectedMonthIndex === index) {
                Row()
                  .width(20)
                  .height(3)
                  .backgroundColor('#4CAF50')
                  .borderRadius(1.5)
                  .margin({ top: 4 })
              }
            }
            .width(50)
            .height(40)
            .justifyContent(FlexAlign.Center)
            .onClick(() => this.selectMonth(index))
          }, (item: string, index: number) => index.toString())
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBarColor(Color.Transparent)
      .scrollBarWidth(0)
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })

      // 记录列表
      List({ space: 0 }) {
        if (this.filteredRecords.length === 0) {
          ListItem() {
            Text("暂无记录")
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .padding(50)
              .width('100%')
          }
        } else {
          ForEach(this.filteredRecords, (item: CoffeeRecord, index: number) => {
            ListItem() {
              Column({ space: 6 }) {
                // 第一行：饮品名称（左）和金额（右）
                Row() {
                  Text(item.drinkName)
                    .fontSize(16)
                    .fontColor($r('app.color.text_primary'))
                  Text(`¥${item.cost.toFixed(1)}`)
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)

                // 第二行：糖、咖啡因、时间（左对齐）
                Text(`糖:${item.sugar}  咖啡因:${item.caffeine}mg  ${this.formatTime(item.createTime)}`)
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                  .textAlign(TextAlign.Start)

                // 分隔线
                if (index < this.filteredRecords.length - 1) {
                  Row()
                    .width('100%')
                    .height(0.5)
                    .backgroundColor($r('app.color.divider_color'))
                    .margin({ top: 8 })
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .alignItems(HorizontalAlign.Start)
            }
          }, (item: CoffeeRecord) => item.id.toString())
        }
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.None)
      .scrollBarColor(Color.Transparent)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),
      bottom: this.getUIContext().px2vp(this.bottomRectHeight)
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }
}
