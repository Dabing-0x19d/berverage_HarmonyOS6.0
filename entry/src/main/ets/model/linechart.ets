/**
 * 咖啡因浓度曲线图组件
 *
 * 科学依据：
 * - 咖啡因半衰期：约5小时（个体差异3-7小时）
 * - 峰值时间：摄入后30-60分钟
 * - 代谢模型：一级动力学 C(t) = C0 * e^(-kt)，其中 k = ln(2) / 半衰期
 * - 多杯叠加：浓度 = 各杯浓度的线性叠加
 */

import { CoffeeRecord } from './CoffeeRecord'
import { DrinkItem } from './tianjia'

// 浓度数据点
interface ConcentrationPoint {
  time: number        // 时间（小时，0-24）
  concentration: number // 浓度（mg/L）
  source: string      // 来源饮品名称
}

// 摄入记录
interface IntakeRecord {
  time: number
  amount: number
  name: string
}

// 曲线图参数
interface LineChartParams {
  records: CoffeeRecord[]      // 今日咖啡记录
  drinks: DrinkItem[]          // 饮品信息
  chartWidth?: number          // 图表宽度
  chartHeight?: number         // 图表高度
}

// 饮品默认咖啡因含量（用于计算峰值）
const DEFAULT_CAFFEINE: Record<string, number> = {
  '美式咖啡': 150,
  '拿铁': 75,
  '抹茶拿铁': 40,
  '生椰拿铁': 75,
  '冰美式': 150,
  '燕麦拿铁': 75,
  '卡布奇诺': 75,
  '摩卡': 95,
  '红茶拿铁': 35
}

// 咖啡因半衰期（小时）
const CAFFEINE_HALF_LIFE: number = 5

// 峰值时间（小时），即达到最大浓度的时间
const PEAK_TIME: number = 0.75 // 45分钟

/**
 * 计算指定时间点的咖啡因浓度
 */
function calculateConcentration(intakeTime: number, caffeineAmount: number, currentTime: number): number {
  if (currentTime < intakeTime) {
    return 0
  }

  const elapsedTime = currentTime - intakeTime
  const k = Math.log(2) / CAFFEINE_HALF_LIFE
  const bloodVolume: number = 5
  const peakConcentration = (caffeineAmount / bloodVolume) * Math.pow(0.5, PEAK_TIME / CAFFEINE_HALF_LIFE)
  const concentration = peakConcentration * Math.pow(0.5, (elapsedTime - PEAK_TIME) / CAFFEINE_HALF_LIFE)

  return Math.max(0, concentration)
}

/**
 * Builder函数，用于在UI中复用
 */
@Builder
export function caffeineLineChartBuilder($$: LineChartParams) {
  CaffeineLineChart({
    records: $$.records,
    drinks: $$.drinks,
    chartWidth: 0,
    chartHeight: $$.chartHeight || 320
  })
}

/**
 * 咖啡因浓度曲线图组件
 */
@Component
export struct CaffeineLineChart {
  @Watch('onRecordsUpdated')
  @Prop records: CoffeeRecord[] = []
  @Prop drinks: DrinkItem[] = []
  @Prop chartWidth: number = 350
  @Prop chartHeight: number = 320

  @State private curvePoints: ConcentrationPoint[] = []
  @State private maxConcentration: number = 0
  @State private currentConc: number = 0
  @State private refreshKey: number = 0

  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D()

  aboutToAppear(): void {
    this.calculateData()
    setTimeout(() => {
      this.drawChart()
    }, 100)
  }

  onRecordsUpdated() {
    this.calculateData()
    setTimeout(() => {
      this.drawChart()
    }, 100)
  }

  /**
   * 计算所有数据
   */
  calculateData(): void {
    const now = new Date()
    const currentHour = now.getHours() + now.getMinutes() / 60

    // 筛选今日记录
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0).getTime()
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59).getTime()

    const todayRecords = this.records.filter(r => {
      const recordTime = new Date(r.createTime).getTime()
      return recordTime >= startOfDay && recordTime <= endOfDay
    })

    // 生成从0点到当前时间+1小时的完整曲线数据
    this.curvePoints = []
    const endTime = currentHour + 1

    for (let hour = 0; hour <= endTime; hour += 1/60) {
      let totalConc = 0

      todayRecords.forEach((record: CoffeeRecord) => {
        const recordDate = new Date(record.createTime)
        const intakeTime = recordDate.getHours() + recordDate.getMinutes() / 60
        const caffeine = record.caffeine || DEFAULT_CAFFEINE[record.drinkName] || 100
        totalConc += calculateConcentration(intakeTime, caffeine, hour)
      })

      this.curvePoints.push({
        time: hour,
        concentration: totalConc,
        source: ''
      })
    }

    // 计算当前浓度
    this.currentConc = 0
    todayRecords.forEach((record: CoffeeRecord) => {
      const recordDate = new Date(record.createTime)
      const intakeTime = recordDate.getHours() + recordDate.getMinutes() / 60
      const caffeine = record.caffeine || DEFAULT_CAFFEINE[record.drinkName] || 100
      this.currentConc += calculateConcentration(intakeTime, caffeine, currentHour)
    })

    // 计算最大浓度（用于Y轴）
    this.maxConcentration = 0
    this.curvePoints.forEach(p => {
      if (p.concentration > this.maxConcentration) {
        this.maxConcentration = p.concentration
      }
    })
    // Y轴最大值至少40，确保显示效果
    this.maxConcentration = Math.max(this.currentConc * 1.2, 40)
  }

  build() {
    Column() {
      Text($r('app.string.chart_title'))
        .fontSize(14)
        .fontColor($r('app.color.chart_text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: 16, top: 16, bottom: 8 })

      Text(`当前浓度: ${this.currentConc.toFixed(1)} mg/L`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentConc > 40 ? $r('app.color.chart_concentration_high') : $r('app.color.chart_concentration_normal'))
        .padding({ left: 16, bottom: 8 })

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
      .height(this.chartHeight)
      .padding({ left: 8, right: 8 })

      Row({ space: 20 }) {
        Row() {
          Row()
            .width(12)
            .height(3)
            .backgroundColor($r('app.color.chart_curve'))
          Text($r('app.string.chart_legend_curve'))
            .fontSize(12)
            .fontColor($r('app.color.chart_legend_indicator'))
            .margin({ left: 4 })
        }

        Row() {
          Row()
            .width(12)
            .height(1)
            .backgroundColor($r('app.color.chart_safety_line'))
          Text($r('app.string.chart_legend_safety_line'))
            .fontSize(12)
            .fontColor($r('app.color.chart_legend_indicator'))
            .margin({ left: 4 })
        }
      }
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 16, top: 8 })
    }
    .width('94%')
    .backgroundColor($r('app.color.chart_background'))
    .borderRadius(15)
    .shadow({
      radius: 20,
      color: $r('app.color.chart_shadow'),
      offsetY: 8
    })
    .margin({ top: 15 })
  }

  drawChart(): void {
    const ctx = this.canvasContext
    const width = this.canvasContext.width
    const height = this.canvasContext.height
    const padding = 30
    const bottomPadding = 40

    // 清空画布
    ctx.clearRect(0, 0, width, height)

    // 获取当前时间
    const now = new Date()
    const currentHour = now.getHours() + now.getMinutes() / 60
    const displayMinutes = 50  // 显示50分钟
    const endHour = currentHour + displayMinutes / 60
    const timeRange = displayMinutes / 60

    console.info(`[LineChart] drawChart: currentHour=${currentHour.toFixed(2)}, endHour=${endHour.toFixed(2)}`)

    // 图表区域
    const chartHeight = height - padding - bottomPadding
    const chartWidth = width - padding * 2

    // Y轴单位
    ctx.fillStyle = '#8e8e93'
    ctx.font = '30px sans-serif'
    ctx.fillText('mg/L', 4, padding - 5)

    // 绘制Y轴标签和网格线
    const gridLines = 5
    for (let i = 0; i <= gridLines; i++) {
      const y = padding + (i / gridLines) * chartHeight
      const value = this.maxConcentration * (1 - i / gridLines)

      ctx.beginPath()
      ctx.strokeStyle = '#e5e5ea'
      ctx.lineWidth = 0.5
      ctx.moveTo(padding, y)
      ctx.lineTo(width - padding, y)
      ctx.stroke()

      ctx.fillStyle = '#555555'
      ctx.font = '30px sans-serif'
      ctx.fillText(value.toFixed(0), 4, y + 10)
    }

    // 绘制X轴标签（每10分钟一个）
    const nodeCount = 6
    const minuteInterval = 10
    for (let i = 0; i < nodeCount; i++) {
      const hour = currentHour + (minuteInterval / 60) * i
      const x = padding + (i / (nodeCount - 1)) * chartWidth
      const mins = Math.round((hour % 1) * 60)
      const h = Math.floor(hour)
      const timeStr = `${h}:${mins.toString().padStart(2, '0')}`

      ctx.fillStyle = '#666666'
      ctx.font = '30px sans-serif'
      ctx.textAlign = 'center' as CanvasTextAlign
      ctx.fillText(timeStr, x, height - bottomPadding + 20)
      ctx.textAlign = 'start' as CanvasTextAlign
    }

    // X轴基线
    const baselineY = height - bottomPadding
    ctx.beginPath()
    ctx.strokeStyle = '#c6c6c8'
    ctx.lineWidth = 1
    ctx.moveTo(padding, baselineY)
    ctx.lineTo(width - padding, baselineY)
    ctx.stroke()

    // 安全线（40mg/L）
    const safetyY = padding + (1 - 40 / this.maxConcentration) * chartHeight
    ctx.beginPath()
    ctx.strokeStyle = '#FF6B6B'
    ctx.lineWidth = 1
    ctx.setLineDash([5, 3])
    ctx.moveTo(padding, safetyY)
    ctx.lineTo(width - padding, safetyY)
    ctx.stroke()
    ctx.setLineDash([])

    // 绘制曲线（从当前时间到50分钟后）
    if (this.curvePoints.length > 1) {
      // 构建曲线路径
      const path = new Path2D()

      for (let i = 0; i < this.curvePoints.length; i++) {
        const point = this.curvePoints[i]

        // 只绘制在显示范围内的点
        if (point.time < currentHour || point.time > endHour) continue

        const x = padding + ((point.time - currentHour) / timeRange) * chartWidth
        const y = padding + (1 - point.concentration / this.maxConcentration) * chartHeight

        path.moveTo(x, y)
      }

      // 填充区域（渐变）
      const fillPath = new Path2D()
      let started = false

      for (let i = 0; i < this.curvePoints.length; i++) {
        const point = this.curvePoints[i]
        if (point.time < currentHour || point.time > endHour) continue

        const x = padding + ((point.time - currentHour) / timeRange) * chartWidth
        const y = padding + (1 - point.concentration / this.maxConcentration) * chartHeight

        if (!started) {
          fillPath.moveTo(x, y)
          started = true
        } else {
          fillPath.lineTo(x, y)
        }
      }

      // 闭合到X轴
      fillPath.lineTo(padding + chartWidth, baselineY)
      fillPath.lineTo(padding, baselineY)
      fillPath.closePath()

      const gradient = ctx.createLinearGradient(0, padding, 0, baselineY)
      gradient.addColorStop(0, 'rgba(76, 175, 80, 0.35)')
      gradient.addColorStop(1, 'rgba(76, 175, 80, 0.05)')
      ctx.fillStyle = gradient
      ctx.fill(fillPath)

      // 绘制绿色粗实线
      ctx.beginPath()
      ctx.strokeStyle = '#4CAF50'
      ctx.lineWidth = 2.5
      ctx.lineCap = 'round'
      ctx.lineJoin = 'round'

      let lineStarted = false
      for (let i = 0; i < this.curvePoints.length; i++) {
        const point = this.curvePoints[i]
        if (point.time < currentHour || point.time > endHour) continue

        const x = padding + ((point.time - currentHour) / timeRange) * chartWidth
        const y = padding + (1 - point.concentration / this.maxConcentration) * chartHeight

        if (!lineStarted) {
          ctx.moveTo(x, y)
          lineStarted = true
        } else {
          ctx.lineTo(x, y)
        }
      }
      ctx.stroke()

      // 绘制当前时间点（蓝色竖线和圆点）
      const nowX = padding
      const nowY = padding + (1 - this.currentConc / this.maxConcentration) * chartHeight

      // 蓝色竖线
      ctx.beginPath()
      ctx.setLineDash([4, 4])
      ctx.strokeStyle = '#2196F3'
      ctx.lineWidth = 1.5
      ctx.moveTo(nowX, padding)
      ctx.lineTo(nowX, baselineY)
      ctx.stroke()
      ctx.setLineDash([])

      // 蓝色圆点
      ctx.beginPath()
      ctx.fillStyle = '#2196F3'
      ctx.arc(nowX, nowY, 5, 0, Math.PI * 2)
      ctx.fill()
    }
  }
}
