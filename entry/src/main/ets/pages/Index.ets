
import { Home } from "../pages/Home"
import { setting } from "../pages/setting"
import { CalendarPage } from "../pages/cacender"
import { ShopManagePage } from "../pages/ShopManagePage"
import { CoffeeDatabase } from "../model/CoffeeDatabase"



// 全局刷新状态
export class GlobalState {
  static refreshCalendar: number = 0
  static incrementCalendarRefresh() {
    GlobalState.refreshCalendar++
  }
}

@Entry
@Component
struct zhuye {
  @State currentTabIndex: number = 0



  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;


  aboutToAppear(): void {
    // 初始化数据库
    CoffeeDatabase.init(getContext(this)).then(() => {
      console.info('Database initialized successfully')
    })
  }

  @Builder
  TabBuilder(index: number, title: string) {
    Column() {
      Text(title)
        .fontSize(15)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
      Column()
        .width(24)
        .height(3)
        .backgroundColor(this.currentTabIndex === index ? $r('app.color.success') : 'transparent')
        .borderRadius(1.5)
        .margin({ top: 2 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 4, bottom: 4 })
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentTabIndex }) {
        TabContent() {
          Home()
        }
        .width('100%').height('100%')
        .tabBar(this.TabBuilder(0, '主页'))
        .height('100%')

        TabContent() {
          CalendarPage()
        }
        .width('100%').height('100%')
        .tabBar(this.TabBuilder(1, '总计'))
        .height('100%')

        TabContent(){
          setting()
        }
        .width('100%').height('100%')
        .tabBar(this.TabBuilder(2, '设置'))
        .height('100%')
      }
      .scrollable(false)
      .animationMode(AnimationMode.NO_ANIMATION)
      .height('100%')
      .width('100%')
      .barHeight(70)
      .barOverlap(true)
      .onChange((index: number) => {
        this.currentTabIndex = index
        // 当切换到总览标签（index=1）时，触发刷新
        if (index === 1) {
          GlobalState.incrementCalendarRefresh()
        }
      })
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('app.color.background_primary'))
  }
}
