/**
 * 饼图组件 - 使用 Progress Ring 实现
 */

// 饼图参数接口
interface PieChartParams {
  completed: number
  total: number
  size?: number
  strokeWidth?: number
  completedColor?: string
  bgColor?: string
}

// Builder函数，用于简单复用
@Builder
export function pieChartBuilder($$: PieChartParams) {
  Column() {
    // 饼图（使用两个 Progress 实现）
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        // 剩余部分（背景圆环）
        Progress({
          value: 0,
          total: $$.total,
          type: ProgressType.Ring
        })
          .width($$.size || 100)
          .height($$.size || 100)
          .style({
            strokeWidth: $$.strokeWidth || 20,
            scaleCount: 30,
            scaleWidth: $$.strokeWidth || 20
          })
          .color($$.bgColor || '#e5e5ea')

        // 完成部分（圆环）
        Progress({
          value: $$.completed,
          total: $$.total,
          type: ProgressType.Ring
        })
          .width($$.size || 100)
          .height($$.size || 100)
          .style({
            strokeWidth: $$.strokeWidth || 20,
            scaleCount: 30,
            scaleWidth: $$.strokeWidth || 20
          })
          .color($$.completedColor || '#4CAF50')

        // 中间显示百分比
        Text(Math.round($$.completed / $$.total * 100) + "%")
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }

      // 图例
      Column() {
        Row() {
          Row()
            .width(10)
            .height(10)
            .backgroundColor($$.completedColor || '#4CAF50')
            .borderRadius(5)
          Text("完成 " + $$.completed + " 天")
            .fontSize(12)
            .margin({ left: 6 })
        }
        .margin({ bottom: 4 })

        Row() {
          Row()
            .width(10)
            .height(10)
            .backgroundColor($$.bgColor || '#e5e5ea')
            .borderRadius(5)
          Text("剩余 " + ($$.total - $$.completed) + " 天")
            .fontSize(12)
            .margin({ left: 6 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16 })
    }
  }
}
