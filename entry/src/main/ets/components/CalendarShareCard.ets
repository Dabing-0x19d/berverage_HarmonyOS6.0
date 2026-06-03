/**
 * 日历分享卡片组件
 * 用于生成可分享的图片
 */
@Component
export struct CalendarShareCard {
  @Prop year: number = new Date().getFullYear()
  @Prop month: number = new Date().getMonth() + 1
  @Prop completedDays: number[] = []
  @Prop totalCount: number = 0

  private weekDays: string[] = ['日', '一', '二', '三', '四', '五', '六']

  build() {
    Column({ space: 12 }) {
      // 标题
      Text('☕ 咖啡日历')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text(`${this.year}年${this.month}月`)
        .fontSize(16)
        .fontColor('rgba(255, 255, 255, 0.9)')
        .margin({ top: 4 })

      // 统计信息
      Row({ space: 20 }) {
        Column() {
          Text(this.totalCount.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('本月天数')
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.7)')
        }

        Column() {
          Text(this.completedDays.length.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          Text('打卡天数')
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.7)')
        }

        Column() {
          Text(`${this.getCompletionRate()}%`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#A5D6A7')
          Text('完成率')
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.7)')
        }
      }
      .margin({ top: 12 })

      Divider()
        .color('rgba(255, 255, 255, 0.2)')
        .margin({ top: 12, bottom: 8 })

      // 星期标题
      Row() {
        ForEach(this.weekDays, (day: string) => {
          Text(day)
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.7)')
            .width('14.28%')
            .textAlign(TextAlign.Center)
        })
      }
      .margin({ bottom: 4 })

      // 日期网格
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.buildCalendarData(), (day: number | null) => {
          Column() {
            Text(day !== null ? day.toString() : '')
              .fontSize(14)
              .fontColor(day !== null ? '#FFFFFF' : Color.Transparent)
              .width(28)
              .height(28)
              .textAlign(TextAlign.Center)
              .backgroundColor(day !== null && this.isToday(day) ? 'rgba(165, 214, 167, 0.5)' : Color.Transparent)
              .borderRadius(14)

            if (day !== null && this.isCompleted(day)) {
              Row()
                .width(6)
                .height(6)
                .backgroundColor('#4CAF50')
                .borderRadius(3)
                .margin({ top: 2 })
            }
          }
          .width('14.28%')
          .height(40)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        })
      }
      .margin({ top: 4 })

      // 底部提示
      Row({ space: 8 }) {
        Row() {
          Row()
            .width(8)
            .height(8)
            .backgroundColor('#4CAF50')
            .borderRadius(4)
        }
        Text('已打卡')
          .fontSize(11)
          .fontColor('rgba(255, 255, 255, 0.6)')
      }
      .margin({ top: 12 })

      Text('来自一杯一档')
        .fontSize(11)
        .fontColor('rgba(255, 255, 255, 0.5)')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#6B5B4F')
    .borderRadius(20)
    .id('calendarShareCard')
  }

  getDaysInMonth(year: number, month: number): number {
    return new Date(year, month, 0).getDate()
  }

  getFirstDayOfWeek(year: number, month: number): number {
    return new Date(year, month - 1, 1).getDay()
  }

  buildCalendarData(): (number | null)[] {
    const daysInMonth = this.getDaysInMonth(this.year, this.month)
    const firstDay = this.getFirstDayOfWeek(this.year, this.month)
    const data: (number | null)[] = []
    for (let i = 0; i < firstDay; i++) data.push(null)
    for (let i = 1; i <= daysInMonth; i++) data.push(i)
    return data
  }

  isCompleted(day: number): boolean {
    return this.completedDays.includes(day)
  }

  isToday(day: number): boolean {
    const now = new Date()
    return day === now.getDate() && this.year === now.getFullYear() && this.month === now.getMonth() + 1
  }

  getCompletionRate(): number {
    const daysInMonth = this.getDaysInMonth(this.year, this.month)
    if (daysInMonth === 0) return 0
    return Math.round((this.completedDays.length / daysInMonth) * 100)
  }
}
