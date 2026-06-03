import { pieChartBuilder } from '../model/barchart';
import { CoffeeDao } from '../model/CoffeeDao';
import { CoffeeRecord } from '../model/CoffeeRecord';
import { CoffeeDatabase } from '../model/CoffeeDatabase';
import { GlobalState } from './Index';
import { Font } from '@kit.ArkUI';
import { yearlySpendingChartBuilder } from '../model/yearlySpendingChart';

@Entry
@Component
export struct CalendarPage {
  // 监听全局刷新状态
  @State @Watch('onRefreshKeyChanged') globalRefreshKey: number = GlobalState.refreshCalendar

  // 刷新触发时的回调
  onRefreshKeyChanged() {
    this.loadData()
  }

  // 统计数据
  @State yearTotal: number = 0
  @State yearCompleted: number = 0
  @State yearSpending: number = 0
  @State weekTotal: number = 7
  @State weekCompleted: number = 0
  // 月统计饼图数据
  @State monthCompleted: number = 0
  @State monthTotal: number = 0

  // DAO 实例
  private coffeeDao: CoffeeDao = new CoffeeDao()

  // 最近记录（用于柱状图）
  @State recentRecords: CoffeeRecord[] = []

  // 页面加载
  async aboutToAppear(): Promise<void> {
    // 等待数据库初始化完成
    await CoffeeDatabase.init(getContext(this))
    this.loadData()

    // 启动定时器监听全局刷新状态
    setInterval(() => {
      if (this.globalRefreshKey !== GlobalState.refreshCalendar) {
        this.globalRefreshKey = GlobalState.refreshCalendar
      }
    }, 500)
  }

  // 从数据库加载数据
  loadData() {
    this.coffeeDao.queryAll().then((records: CoffeeRecord[]) => {
      // 更新最近记录
      this.recentRecords = [...records]
      // 更新统计数据
      this.updateStats(records)
      // 更新月统计
      this.updateMonthStats(records)
    })
  }

  // 更新月统计
  updateMonthStats(records: CoffeeRecord[]) {
    const now = new Date()
    const currentMonth = now.getMonth() + 1
    const days: number[] = []
    records.forEach(record => {
      const date = new Date(record.createTime)
      if (date.getFullYear() === now.getFullYear() && date.getMonth() + 1 === currentMonth) {
        if (!days.includes(date.getDate())) days.push(date.getDate())
      }
    })
    this.monthTotal = new Date(now.getFullYear(), currentMonth, 0).getDate()
    this.monthCompleted = days.length
  }

  // 更新统计数据
  updateStats(records: CoffeeRecord[]) {
    const now = new Date()
    const currentYear = now.getFullYear()

    // 年度统计 - 计算今年已过的天数和剩余天数
    const isLeapYear = (currentYear % 4 === 0 && currentYear % 100 !== 0) || (currentYear % 400 === 0)
    const totalDaysInYear = isLeapYear ? 366 : 365

    // 使用日期计算今天是第几天
    const month = now.getMonth() // 0-11，12月=11
    const day = now.getDate()
    const daysInMonths = [31, isLeapYear ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    let todayDayOfYear = day
    for (let i = 0; i < month; i++) {
      todayDayOfYear += daysInMonths[i]
    }

    // 剩余天数 = 年总天数 - 今天是一年中的第几天
    this.yearTotal = totalDaysInYear - todayDayOfYear

    console.info(`年度统计: 今天是${month + 1}月${day}日, 一年第${todayDayOfYear}天, 剩余${this.yearTotal}天, 平年${totalDaysInYear}天`)

    const yearUniqueDays: Set<string> = new Set()
    let totalSpending = 0
    records.filter(r => {
      const date = new Date(r.createTime)
      return date.getFullYear() === currentYear
    }).forEach(r => {
      const recordDay = new Date(r.createTime).getDate()
      const recordMonth = new Date(r.createTime).getMonth()
      yearUniqueDays.add(`${recordMonth}-${recordDay}`)
      totalSpending += r.cost || 0
    })
    this.yearCompleted = yearUniqueDays.size
    this.yearSpending = totalSpending
  }

  // 副文本颜色
  getSubTextColor(): string {
    return '#8e8e93'
  }

  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;

  build() {
    Column() {
      Row() {
        Text('总计')
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 20 })
      }
      .width("100%")
      .justifyContent(FlexAlign.Start)
      .height(50)
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 15 }) {
          // 年统计卡片
          Column() {
            Row() {
              Text("年统计")
                .fontSize(13)
                .fontColor(this.getSubTextColor())
            }
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 10 })

            Row() {
              Column() {
                Text(this.yearCompleted.toString())
                  .fontSize(28)
                  .fontColor($r('app.color.text_primary'))
                  .fontWeight(FontWeight.Bold)
                Text("完成天数")
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('33%')

              Column() {
                Text(this.yearTotal.toString())
                  .fontSize(28)
                  .fontColor($r('app.color.text_primary'))
                  .fontWeight(FontWeight.Bold)
                Text("剩余天数")
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('33%')

              Column() {
                Text(`¥${this.yearSpending.toFixed(0)}`)
                  .fontSize(28)
                  .fontColor($r('app.color.text_primary'))
                  .fontWeight(FontWeight.Bold)
                Text("年消费")
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('33%')
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })
          }
          .width('94%')
          .backgroundColor($r('app.color.background_card'))
          .borderRadius(15)
          .shadow({
            radius: 20,
            color: $r('app.color.shadow_color'),
            offsetY: 8
          })
          .margin({ left: '3%', right: '3%', top: 15 })

          // 年度消费柱状图
          yearlySpendingChartBuilder({
            records: this.recentRecords
          })

          // 月统计饼图
          Column() {
            Text("月统计")
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Start)
              .padding({ left: 16, top: 16, bottom: 10 })

            pieChartBuilder({
              completed: this.monthCompleted,
              total: this.monthTotal,
              size: 100,
              strokeWidth: 20,
              completedColor: '#4CAF50',
              bgColor: '#e5e5ea'
            })

            Text(`${this.monthCompleted}/${this.monthTotal}天`)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 8 })
          }
          .width('94%')
          .backgroundColor($r('app.color.background_card'))
          .borderRadius(16)
          .shadow({
            radius: 20,
            color: $r('app.color.shadow_color'),
            offsetY: 8
          })
          .padding(12)
          .margin({ left: '3%', right: '3%', top: 15 })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.background_primary'))
        .padding({ bottom: 80 })
      }
      .scrollBarColor(Color.Transparent)
      .width('100%')
    }
    .width('100%')
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),
      bottom: this.getUIContext().px2vp(this.bottomRectHeight)
    })
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }
}
