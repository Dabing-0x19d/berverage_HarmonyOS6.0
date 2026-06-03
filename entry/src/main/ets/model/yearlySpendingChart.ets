/**
 * 消费金额柱状图组件
 *
 * 功能：
 * - 支持每周/每年切换
 * - 每周模式：X轴周日到周六
 * - 每年模式：X轴1月到12月
 * - Y轴：消费金额（不显示坐标值）
 * - 金额显示在柱状图顶部
 */

import { CoffeeRecord } from './CoffeeRecord'

// 柱状图参数
interface BarChartParams {
  records: CoffeeRecord[]  // 所有咖啡记录
  chartWidth?: number      // 图表宽度
  chartHeight?: number     // 图表高度
}

// 星期标签（周日到周六）
const WEEKDAY_LABELS: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
// 月份标签
const MONTH_LABELS: string[] = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']

// 显示模式
type ChartMode = 'weekly' | 'yearly'

/**
 * Builder函数，用于在UI中复用
 */
@Builder
export function yearlySpendingChartBuilder($$: BarChartParams) {
  SpendingChart({
    records: $$.records,
    chartWidth: 0,
    chartHeight: $$.chartHeight || 320
  })
}

/**
 * 消费金额柱状图组件
 */
@Component
export struct SpendingChart {
  @Watch('onRecordsUpdated')
  @Prop records: CoffeeRecord[] = []
  @Prop chartWidth: number = 350
  @Prop chartHeight: number = 320

  @State private chartMode: ChartMode = 'weekly'
  @State private weeklySpending: number[] = new Array(7).fill(0)
  @State private yearlySpending: number[] = new Array(12).fill(0)
  @State private maxSpending: number = 0
  @State private totalSpending: number = 0
  @State private chartTitle: string = ''

  // Canvas颜色
  @State private chartLabelColor: string = '#666666'
  @State private chartBaselineColor: string = '#C6C6C8'

  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D()

  // 用于监听配置变化的占位属性
  @StorageProp('bottomRectHeight')
  dummyProp: number = 0

  aboutToAppear(): void {
    this.calculateData()
    this.drawChart()
  }

  /**
   * 当配置变化时（深色/浅色模式切换）触发，重新绘制
   */
  onConfigurationUpdate(): void {
    this.drawChart()
  }

  onRecordsUpdated() {
    this.calculateData()
    setTimeout(() => {
      this.drawChart()
    }, 100)
  }

  /**
   * 切换图表模式
   */
  toggleMode() {
    this.chartMode = this.chartMode === 'weekly' ? 'yearly' : 'weekly'
    this.calculateData()
    setTimeout(() => {
      this.drawChart()
    }, 100)
  }

  /**
   * 计算消费数据
   */
  calculateData(): void {
    if (this.chartMode === 'weekly') {
      this.calculateWeeklyData()
    } else {
      this.calculateYearlyData()
    }
  }

  /**
   * 计算本周消费金额（周日到周六）
   */
  calculateWeeklyData(): void {
    const now = new Date()

    // 获取本周的周日（第一天）和周六（最后一天）
    const currentDayOfWeek = now.getDay() // 0=周日, 1=周一, ..., 6=周六
    const weekStart = new Date(now)
    weekStart.setDate(now.getDate() - currentDayOfWeek) // 回到周日
    weekStart.setHours(0, 0, 0, 0)

    const weekEnd = new Date(weekStart)
    weekEnd.setDate(weekStart.getDate() + 6) // 周六
    weekEnd.setHours(23, 59, 59, 999)

    // 初始化
    this.weeklySpending = new Array(7).fill(0)
    this.totalSpending = 0

    // 显示日期范围
    const startMonth = weekStart.getMonth() + 1
    const startDay = weekStart.getDate()
    const endMonth = weekEnd.getMonth() + 1
    const endDay = weekEnd.getDate()
    this.chartTitle = `${startMonth}月${startDay}日 - ${endMonth}月${endDay}日`

    // 统计本周每天的消费
    this.records.forEach((record: CoffeeRecord) => {
      const recordDate = new Date(record.createTime)
      if (recordDate >= weekStart && recordDate <= weekEnd) {
        const dayOfWeek = recordDate.getDay()
        const cost = record.cost || 0
        this.weeklySpending[dayOfWeek] += cost
        this.totalSpending += cost
      }
    })

    // 计算最大金额（用于Y轴）
    this.maxSpending = 0
    this.weeklySpending.forEach(amount => {
      if (amount > this.maxSpending) {
        this.maxSpending = amount
      }
    })
    this.maxSpending = Math.max(this.maxSpending * 1.2, 50)
  }

  /**
   * 计算本年度消费金额（1月到12月）
   */
  calculateYearlyData(): void {
    const now = new Date()
    const currentYear = now.getFullYear()

    // 初始化
    this.yearlySpending = new Array(12).fill(0)
    this.totalSpending = 0
    this.chartTitle = `${currentYear}年`

    // 统计本年度每月的消费
    this.records.forEach((record: CoffeeRecord) => {
      const recordDate = new Date(record.createTime)
      if (recordDate.getFullYear() === currentYear) {
        const month = recordDate.getMonth() // 0-11
        const cost = record.cost || 0
        this.yearlySpending[month] += cost
        this.totalSpending += cost
      }
    })

    // 计算最大金额（用于Y轴）
    this.maxSpending = 0
    this.yearlySpending.forEach(amount => {
      if (amount > this.maxSpending) {
        this.maxSpending = amount
      }
    })
    this.maxSpending = Math.max(this.maxSpending * 1.2, 50)
  }

  /**
   * 获取当前显示的数据
   */
  getCurrentData(): number[] {
    return this.chartMode === 'weekly' ? this.weeklySpending : this.yearlySpending
  }

  /**
   * 获取当前显示的标签
   */
  getCurrentLabels(): string[] {
    return this.chartMode === 'weekly' ? WEEKDAY_LABELS : MONTH_LABELS
  }

  /**
   * 获取柱状图数量
   */
  getBarCount(): number {
    return this.chartMode === 'weekly' ? 7 : 12
  }

  build() {
    Column() {
      // 标题栏：标题 + 切换按钮
      Row() {
        Text(this.chartTitle)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))

        // 切换按钮
        Row({ space: 4 }) {
          Text('周')
            .fontSize(12)
            .fontColor(this.chartMode === 'weekly' ? $r('app.color.text_on_primary') : $r('app.color.text_primary'))
          Text('/')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text('年')
            .fontSize(12)
            .fontColor(this.chartMode === 'yearly' ? $r('app.color.text_on_primary') : $r('app.color.text_primary'))
        }
        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
        .backgroundColor(this.chartMode === 'weekly' ? $r('app.color.tab_selected') : $r('app.color.button_disabled'))
        .borderRadius(12)
        .onClick(() => {
          this.toggleMode()
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, top: 16, bottom: 4 })

      // 总金额
      Text(`¥${this.totalSpending.toFixed(2)}`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding({ left: 16, bottom: 8 })

      // 图表
      Stack() {
        Column() {
          Canvas(this.canvasContext)
            .width('100%')
            .height('100%')
            .onReady(() => {
              this.drawChart()
            })
        }
      }
      .width('100%')
      .height(240)
      .padding({ left: 8, right: 8 })
    }
    .width('94%')
    .backgroundColor($r('app.color.background_card'))
    .borderRadius(15)
    .shadow({
      radius: 20,
      color: $r('app.color.shadow_color'),
      offsetY: 8
    })
    .margin({ top: 15 })
  }

  drawChart(): void {
    const ctx = this.canvasContext
    const width = this.canvasContext.width
    const height = this.canvasContext.height

    const padding = 40
    const bottomPadding = 55
    const leftPadding = 10
    const rightPadding = 10

    // 清空画布
    ctx.clearRect(0, 0, width, height)

    // 图表区域
    const chartHeight = height - padding - bottomPadding
    const chartWidth = width - leftPadding - rightPadding

    // 柱状图参数
    const barCount = this.getBarCount()
    const barWidth = chartWidth / barCount * 0.6
    const barGap = chartWidth / barCount * 0.4

    // 绘制X轴标签
    ctx.fillStyle = this.chartLabelColor
    ctx.font = '40px sans-serif'
    ctx.textAlign = 'center' as CanvasTextAlign

    // X轴基线
    const baselineY = height - bottomPadding

    // 绘制标签
    const labels = this.getCurrentLabels()
    for (let i = 0; i < barCount; i++) {
      const x = leftPadding + (i + 0.5) * (chartWidth / barCount)
      ctx.fillText(labels[i], x, baselineY + 30)
    }
    ctx.textAlign = 'start' as CanvasTextAlign

    // 绘制X轴线
    ctx.beginPath()
    ctx.strokeStyle = this.chartBaselineColor
    ctx.lineWidth = 1
    ctx.moveTo(leftPadding, baselineY)
    ctx.lineTo(width - rightPadding, baselineY)
    ctx.stroke()

    // 绘制柱状图和金额标签
    const data = this.getCurrentData()
    for (let i = 0; i < barCount; i++) {
      const amount = data[i]
      const barHeight = (amount / this.maxSpending) * chartHeight * 0.85
      const x = leftPadding + i * (chartWidth / barCount) + barGap / 2
      const y = baselineY - barHeight

      // 绘制柱状图
      const gradient = ctx.createLinearGradient(0, y, 0, baselineY)
      gradient.addColorStop(0, '#81C784')
      gradient.addColorStop(1, '#4CAF50')

      ctx.fillStyle = gradient
      ctx.fillRect(x, y, barWidth, barHeight)

      // 绘制金额标签（柱状图顶部）
      if (amount > 0) {
        ctx.fillStyle = this.chartLabelColor
        ctx.font = 'bold 44px sans-serif'
        ctx.textAlign = 'center' as CanvasTextAlign
        ctx.fillText(`¥${amount.toFixed(0)}`, x + barWidth / 2, y - 8)
        ctx.textAlign = 'start' as CanvasTextAlign
      }
    }
  }
}
