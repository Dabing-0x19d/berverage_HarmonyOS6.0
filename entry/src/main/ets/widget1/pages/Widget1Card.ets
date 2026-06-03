@Entry
@Component
struct Widget1Card {
  // 卡片应用只支持 @LocalStorageProp
  @LocalStorageProp('sunday') @Watch('onDataChange') sunday: string = '0';
  @LocalStorageProp('monday') @Watch('onDataChange') monday: string = '0';
  @LocalStorageProp('tuesday') @Watch('onDataChange') tuesday: string = '0';
  @LocalStorageProp('wednesday') @Watch('onDataChange') wednesday: string = '0';
  @LocalStorageProp('thursday') @Watch('onDataChange') thursday: string = '0';
  @LocalStorageProp('friday') @Watch('onDataChange') friday: string = '0';
  @LocalStorageProp('saturday') @Watch('onDataChange') saturday: string = '0';
  @LocalStorageProp('total') @Watch('onDataChange') total: string = '0';
  @LocalStorageProp('dateRange') @Watch('onDataChange') dateRange: string = '';

  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D()
  private weekdayLabels: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

  // 数据变化时重新绘制图表
  onDataChange(): void {
    this.drawChart()
  }

  getData(): number[] {
    return [
      Number(this.sunday), Number(this.monday), Number(this.tuesday),
      Number(this.wednesday), Number(this.thursday), Number(this.friday), Number(this.saturday)
    ];
  }

  build() {
    Column() {
      // 顶部标题区域：总金额在左，日期在右
      Row() {
        // 总金额 - 左边，加粗
        Text(`¥${Number(this.total).toFixed(2)}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        // 日期范围 - 右边，不加粗
        Text(this.dateRange)
          .fontSize(20)
          .fontWeight(FontWeight.Normal)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, top: 12 })

      // 柱状图区域
      Stack() {
        Canvas(this.canvasContext)
          .width('100%')
          .height('100%')
          .onReady(() => {
            this.drawChart()
          })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8 })

      // X轴标签 - 整体居中，绿点标记当天
      Row({ space: 4 }) {
        ForEach(this.weekdayLabels, (label: string, index: number) => {
          Row({ space: 4 }) {
            if (index === new Date().getDay()) {
              Circle({ width: 6, height: 6 })
                .fill('#4CAF50')
            }
            Text(label)
              .fontSize(10)
              .fontColor('#888888')
          }
          .width(40)
          .justifyContent(FlexAlign.Center)
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ bottom: 12, left: 8, right: 8 })
    }
    .width('100%')
    .height('100%')


    .borderRadius(16)
    .clip(true)
  }

  drawChart(): void {
    const ctx = this.canvasContext
    const width = this.canvasContext.width
    const height = this.canvasContext.height

    if (width === 0 || height === 0) return

    const leftPadding = 8
    const rightPadding = 8
    const chartWidth = width - leftPadding - rightPadding
    const chartHeight = height - 10

    const data = this.getData()
    const maxSpending = Math.max(...data, 50) * 1.2

    ctx.clearRect(0, 0, width, height)

    // X轴基线
    const baselineY = height - 2
    ctx.beginPath()
    ctx.strokeStyle = '#E0E0E0'
    ctx.lineWidth = 1
    ctx.moveTo(leftPadding, baselineY)
    ctx.lineTo(width - rightPadding, baselineY)
    ctx.stroke()

    // 柱状图
    const barCount = 7
    const barWidth = chartWidth / barCount * 0.4
    const barGap = chartWidth / barCount * 0.6

    for (let i = 0; i < barCount; i++) {
      const amount = data[i]
      const barHeight = (amount / maxSpending) * chartHeight * 0.75
      const x = leftPadding + i * (chartWidth / barCount) + barGap / 2
      const y = baselineY - barHeight

      // 渐变柱状图
      const gradient = ctx.createLinearGradient(0, y, 0, baselineY)
      gradient.addColorStop(0, '#81C784')
      gradient.addColorStop(1, '#4CAF50')

      ctx.fillStyle = gradient
      ctx.fillRect(x, y, barWidth, barHeight)

      // 金额标签
      if (amount > 0) {
        ctx.fillStyle = '#666666'
        ctx.font = 'bold 40px sans-serif'
        ctx.textAlign = 'center' as CanvasTextAlign
        ctx.fillText(`¥${amount.toFixed(0)}`, x + barWidth / 2, y - 3)
      }
    }
    ctx.textAlign = 'start' as CanvasTextAlign
  }
}
