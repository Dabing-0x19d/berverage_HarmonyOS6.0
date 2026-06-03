import { router } from '@kit.ArkUI';

/**
 * 榜单分享卡片组件
 * 用于生成可分享的图片，包含前三名颁奖效果
 */
@Component
export struct RankShareCard {
  @Prop shops: string[] = []
  @Prop shopCounts: Map<string, number> = new Map()

  build() {
    Column({ space: 12 }) {
      // 标题
      Text('☕ 我的咖啡榜单')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text('TOP 10 咖啡店排行')
        .fontSize(14)
        .fontColor('rgba(255, 255, 255, 0.8)')
        .margin({ top: 4 })

      Divider()
        .color('rgba(255, 255, 255, 0.3)')
        .margin({ top: 8, bottom: 8 })

      // 榜单列表（取前10名）
      Column({ space: 8 }) {
        ForEach(this.shops.slice(0, 10), (shop: string, index: number) => {
          this.buildRankItem(shop, index)
        }, (shop: string) => shop)
      }
      .width('100%')

      // 底部
      Text('来自一杯一档')
        .fontSize(12)
        .fontColor('rgba(255, 255, 255, 0.6)')
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#8D6B4F')
    .borderRadius(20)
    .id('rankShareCard')
  }

  @Builder
  buildRankItem(shop: string, index: number) {
    Row({ space: 12 }) {
      // 排名徽章
      this.buildRankBadge(index)

      // 店铺名称
      Text(shop)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)

      // 消费次数
      Text(`${this.shopCounts.get(shop) || 0}次`)
        .fontSize(13)
        .fontColor('rgba(255, 255, 255, 0.8)')
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.getItemBgColor(index))
    .borderRadius(12)
  }

  @Builder
  buildRankBadge(index: number) {
    if (index === 0) {
      // 金牌
      Row() {
        Text('🥇')
          .fontSize(18)
        Text('1')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFD700')
      }
      .width(32)
      .height(32)
      .backgroundColor('rgba(255, 215, 0, 0.2)')
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    } else if (index === 1) {
      // 银牌
      Row() {
        Text('🥈')
          .fontSize(18)
        Text('2')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#C0C0C0')
      }
      .width(32)
      .height(32)
      .backgroundColor('rgba(192, 192, 192, 0.2)')
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    } else if (index === 2) {
      // 铜牌
      Row() {
        Text('🥉')
          .fontSize(18)
        Text('3')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#CD7F32')
      }
      .width(32)
      .height(32)
      .backgroundColor('rgba(205, 127, 50, 0.2)')
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    } else {
      // 其他排名
      Text(`${index + 1}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('rgba(255, 255, 255, 0.8)')
        .width(32)
        .height(32)
        .textAlign(TextAlign.Center)
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(16)
    }
  }

  getItemBgColor(index: number): string {
    if (index === 0) {
      return 'rgba(255, 215, 0, 0.15)'
    } else if (index === 1) {
      return 'rgba(192, 192, 192, 0.15)'
    } else if (index === 2) {
      return 'rgba(205, 127, 50, 0.15)'
    } else {
      return 'rgba(255, 255, 255, 0.08)'
    }
  }
}
