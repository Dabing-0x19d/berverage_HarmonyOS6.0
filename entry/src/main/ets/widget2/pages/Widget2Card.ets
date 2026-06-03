@Entry
@Component
struct Widget2Card {
  // 店铺消费数据 - 前3名
  // 卡片数据需要通过 updateForm() 方法主动推送更新，无法由应用直接修改
  // 注意：卡片应用只支持 @LocalStorageProp，数据更新依赖 updateForm() 推送
  @LocalStorageProp('shop1') @Watch('onDataChange') shop1: string = '';
  @LocalStorageProp('count1') @Watch('onDataChange') count1: string = '0';
  @LocalStorageProp('shop2') @Watch('onDataChange') shop2: string = '';
  @LocalStorageProp('count2') @Watch('onDataChange') count2: string = '0';
  @LocalStorageProp('shop3') @Watch('onDataChange') shop3: string = '';
  @LocalStorageProp('count3') @Watch('onDataChange') count3: string = '0';
  // 时间戳 - 用于触发 @Watch 监听器
  @LocalStorageProp('_timestamp') @Watch('onDataChange') timestamp: string = '';

  // 生命周期：卡片初始化时打印数据
  aboutToAppear(): void {
    console.info(`[Widget2Card] aboutToAppear: shop1=${this.shop1}, count1=${this.count1}`)
  }

  // 生命周期：卡片显示时打印当前数据
  onShow(): void {
    console.info(`[Widget2Card] onShow: shop1=${this.shop1}, count1=${this.count1}, shop2=${this.shop2}, count2=${this.count2}`)
  }

  // 数据变化时打印日志
  onDataChange(): void {
    console.info(`[Widget2Card] onDataChange: shop1=${this.shop1}, count1=${this.count1}, shop2=${this.shop2}, count2=${this.count2}`)
  }

  // 获取店铺显示名称（截断过长名称）
  getShopName(shop: string): string {
    if (!shop) return '-'
    if (shop.length > 5) {
      return shop.substring(0, 4) + '..'
    }
    return shop
  }

  // 获取排名颜色
  getRankColor(index: number): string {
    const colors: string[] = ['#FF6B6B', '#FFA94D', '#FFD93D']
    return colors[index] || '#888888'
  }

  build() {
    Column() {
      // 标题
      Text('店铺榜单')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 16, bottom: 8 })

      // 榜单列表 - 直接渲染，不用@Builder
      Column({ space: 0 }) {
        // 第1名
        Row() {
          Text('1')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getRankColor(0))
            .width(20)
          Text(this.getShopName(this.shop1))
            .fontSize(13)
            .layoutWeight(1)
          Text(`${this.count1}杯`)
            .fontSize(12)
        }
        .width('100%')
        .height(32)
        .alignItems(VerticalAlign.Center)

        // 第2名
        Row() {
          Text('2')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getRankColor(1))
            .width(20)
          Text(this.getShopName(this.shop2))
            .fontSize(13)
            .layoutWeight(1)
          Text(`${this.count2}杯`)
            .fontSize(12)
        }
        .width('100%')
        .height(32)
        .alignItems(VerticalAlign.Center)

        // 第3名
        Row() {
          Text('3')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getRankColor(2))
            .width(20)
          Text(this.getShopName(this.shop3))
            .fontSize(13)
            .layoutWeight(1)
          Text(`${this.count3}杯`)
            .fontSize(12)
        }
        .width('100%')
        .height(32)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .height('100%')
    // .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .clip(true)
  }
}
