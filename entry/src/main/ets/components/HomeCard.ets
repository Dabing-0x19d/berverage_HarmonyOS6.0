import { router } from '@kit.ArkUI';
import { CoffeeRecord } from '../model/CoffeeRecord'

/**
 * 今日统计卡片组件
 */
@Component
export struct TodayStatsCard {
  @Prop todayCups: number = 0
  @Prop todayCaffeine: number = 0
  @Prop todaySugar: number = 0

  build() {
    Column() {
      Row() {
        Text("今日")
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 10 })

      Row() {
        Column() {
          Text(this.todayCups.toString())
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text("杯")
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('33%')

        Column() {
          Text(this.todayCaffeine.toString())
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text("mg 咖啡因")
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('33%')

        Column() {
          Row({ space: 2 }) {
            Text("≈")
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text(this.todaySugar.toString())
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          }
          Text("克 糖")
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
    .margin({ top: 15 })
  }
}

/**
 * 我的榜单卡片组件
 */
@Component
export struct ShopRankCard {
  @Prop shops: string[] = []
  onShopClick: (shop: string) => void = () => {}
  onShareClick: () => void = () => {}

  build() {
    Column() {
      Row() {
        Text("我的榜单")
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))

        Blank()

        Row() {
          SymbolGlyph($r('sys.symbol.share'))
            .fontSize(16)
            .fontColor([$r('app.color.symbol_primary')])
        }
        .width(32)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onShareClick())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 10 })

      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.shops, (shop: string, index: number) => {
            Column() {
              Text(`${index + 1}`)
                .fontSize(13)
                .fontColor(Color.Green)
              Text(shop)
                .fontSize(13)
                .margin({ top: 2 })
            }
            .width(70)
            .height(48)
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)
            .onClick(() => this.onShopClick(shop))
          }, (shop: string) => shop)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBarColor(Color.Transparent)
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
    .margin({ top: 15 })
  }
}

// 店铺统计数据接口
export interface ShopCountData {
  name: string;
  count: number;
}

/**
 * 榜单分享卡片组件 - 简洁列表样式
 */
@Component
export struct RankShareCard {
  @Prop shopData: ShopCountData[] = []
  onClose: () => void = () => {}

  build() {
    Column() {
      // 关闭按钮
      Row() {
        Blank()
        Text("×")
          .fontSize(24)
          .fontColor($r('app.color.text_secondary'))
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .onClick(() => this.onClose())
      }
      .width('100%')
      .padding({ right: 8 })

      Text("我的店铺榜单")
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 8, bottom: 16 })

      // 从上到下排名列表
      Column({ space: 8 }) {
        ForEach(this.shopData, (item: ShopCountData, index: number) => {
          Row() {
            // 排名数字
            Text(`${index + 1}`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getRankColor(index))
              .width(28)
              .textAlign(TextAlign.Center)

            // 店铺名称
            Text(item.name)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            // 消费次数
            Text(`${item.count}次`)
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor($r('app.color.background_elevated'))
          .borderRadius(8)
        }, (item: ShopCountData) => item.name)
      }
      .width('90%')
      .margin({ bottom: 16 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background_card'))
    .borderRadius(16)
    .shadow({
      radius: 20,
      color: $r('app.color.shadow_color'),
      offsetY: 8
    })
    .id('rankShareCard')
  }

  // 获取排名颜色
  getRankColor(index: number): ResourceStr {
    if (index === 0) return '#FFD700'  // 金色
    if (index === 1) return '#C0C0C0'  // 银色
    if (index === 2) return '#CD7F32'  // 铜色
    return $r('app.color.text_secondary')
  }
}

/**
 * 最近记录卡片组件
 */
@Component
export struct RecentRecordsCard {
  @Prop recentRecords: CoffeeRecord[] = []
  @Prop drinkIcons: Record<string, string> = {}
  onDelete: (id: number) => Promise<void> = () => Promise.resolve()
  onFormatTime: (timestamp: number) => string = () => ''

  // 过滤出最近一周的记录
  getRecentWeekRecords(): CoffeeRecord[] {
    const now = new Date()
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
    oneWeekAgo.setHours(0, 0, 0, 0)

    return this.recentRecords.filter(record => {
      const recordDate = new Date(record.createTime)
      return recordDate >= oneWeekAgo
    }).sort((a, b) => b.createTime - a.createTime) // 按时间倒序
  }

  // 删除按钮构建器
  @Builder
  deleteItemBuilder(id: number) {
    Row() {
      Text('删除')
        .fontSize(16)
        .fontColor(Color.White)
        .width(60)
        .height(36)
        .textAlign(TextAlign.Center)
        .backgroundColor('#4CAF50')
        .borderRadius(8)
        .onClick(async () => {
          await this.onDelete(id)
        })
    }
    .justifyContent(FlexAlign.Center)
    .padding({ right: 16 })
    .height('100%')
  }

  // 获取饮品图标
  getDrinkIcon(drinkName: string): string {
    return this.drinkIcons[drinkName] || '☕'
  }

  build() {
    Column() {
      // 标题行：最近 + 全部按钮
      Row() {
        Text("最近")
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))

        Text("全部 >")
          .fontSize(13)
          .fontColor($r('app.color.tab_selected'))
          .onClick(() => {
            router.pushUrl({ url: 'pages/AllRecordsPage' })
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, top: 16, bottom: 10 })

      List({ space: 0 }) {
        ForEach(this.getRecentWeekRecords(), (item: CoffeeRecord, index: number) => {
          ListItem() {
            Column() {
              Row() {
                Text(item.drinkName)
                  .fontSize(16)
                Text(`糖:${item.sugar} 咖啡因:${item.caffeine}mg ${this.onFormatTime(item.createTime)}`)
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .height(60)
              .justifyContent(FlexAlign.Center)

              // 分隔线
              if (index < this.getRecentWeekRecords().length - 1) {
                Row()
                  .width('100%')
                  .height(0.5)
                  .backgroundColor($r('app.color.divider_color'))
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          }
          .swipeAction({
            end: {
              builder: () => {
                this.deleteItemBuilder(item.id)
              },
              actionAreaDistance: 10
            }
          })
        }, (item: CoffeeRecord) => item.id.toString())
      }
      .height(300)
      .edgeEffect(EdgeEffect.None)
      .scrollBarColor(Color.Transparent)
    }
    .width('94%')
    .backgroundColor($r('app.color.background_card'))
    .borderRadius(15)
    .margin({ top: 15 })
    .shadow({
      radius: 20,
      color: $r('app.color.shadow_color'),
      offsetY: 8
    })
    .padding({ top: 10, bottom: 10 })
  }
}
