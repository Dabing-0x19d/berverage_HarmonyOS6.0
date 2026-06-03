/**
 * 同步状态指示组件
 *
 * 功能：显示同步状态占位符
 */
@Component
export struct SyncStatusIndicator {
  @State syncStatus: string = 'local';

  build() {
    Row() {
      Image($r('sys.symbol.cloud'))
        .width(16)
        .height(16)
        .margin({ right: 8 })
        .fillColor('#666666')

      Text('本地存储')
        .fontSize(13)
        .fontColor('#666666')
        .fontWeight(FontWeight.Medium);
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .border({
      radius: 20,
      width: 1,
      color: '#E0E0E0'
    })
    .backgroundColor('#FAFAFA')
  }
}
