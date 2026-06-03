import { router } from '@kit.ArkUI';
import { ShopDao } from "../model/ShopDao";
import { ShopRecord } from "../model/ShopRecord";
import { CoffeeDao } from "../model/CoffeeDao";
import { ShopDrinkRecord } from "../model/ShopDrinkRecord";
import { ShopDrinkDao } from "../model/ShopDrinkDao";
import { editShopDrinkBuilder } from "../model/EditShopDrinkSheet"
import { AddShopSheet } from "../model/AddShopSheet"
import { ShopExportImportManager, ImportOptions } from "../model/ShopExportImportManager"
import { ImportPreview } from "../model/ShopExportImportManager"
import { ShareUtil } from "../utils/ShareUtil"

// 闭包捕获变量 - 用于弹窗
let capturedEditShopId: number = 0
let capturedEditShopName: string = ''
let capturedEditDrinks: ShopDrinkRecord[] = []
let capturedImportPreview: ImportPreview | null = null
let capturedAddShopCallback: ((shopName: string) => void) | null = null

@Entry
@Component
export struct ShopManagePage {
  @State shops: ShopRecord[] = []
  @State shopCounts: Map<string, number> = new Map()

  //状态栏高度
  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;

  // 弹窗显示控制 - 单一弹窗
  @State isSheetShow: boolean = false

  // 弹窗类型状态
  @State sheetType: 'edit' | 'import' | 'addShop' = 'edit'

  // 监听店铺刷新信号
  @Watch('onRefreshShopsChange')
  @StorageLink('needRefreshShops') refreshSignal: number = 0

  private shopDao: ShopDao = new ShopDao();
  private coffeeDao: CoffeeDao = new CoffeeDao();
  private shopDrinkDao: ShopDrinkDao = new ShopDrinkDao();
  private exportImportManager: ShopExportImportManager = new ShopExportImportManager();

  // 分享相关状态
  @State isSharing: boolean = false
  @State importPreview: ImportPreview | null = null
  @State pendingImportData: string = ''

  // 监听收到的分享数据
  @Watch('onPendingShareDataChange')
  @StorageLink('pendingShopShareData') pendingShareData: string = ''

  onPendingShareDataChange() {
    if (this.pendingShareData) {
      console.info('[ShopManagePage] Pending share data detected');
      this.handleSharedData(this.pendingShareData)
      AppStorage.setOrCreate('pendingShopShareData', '')
    }
  }

  async aboutToAppear(): Promise<void> {
    await this.loadShops();
  }

  onRefreshShopsChange() {
    if (this.refreshSignal > 0) {
      this.loadShops();
    }
  }

  onPageShow(): void {
    this.loadShops();
  }

  async loadShops(): Promise<void> {
    const allShops = await this.shopDao.queryAll();
    this.shopCounts = await this.coffeeDao.getShopCounts();

    allShops.sort((a, b) => {
      const countA = this.shopCounts.get(a.shopName) || 0;
      const countB = this.shopCounts.get(b.shopName) || 0;
      if (countA !== countB) {
        return countB - countA;
      }
      return b.createTime - a.createTime;
    });

    this.shops = allShops;
  }

  async deleteShop(id: number): Promise<void> {
    await this.shopDao.delete(id);
    await this.loadShops();
    AppStorage.setOrCreate('needRefreshShops', Date.now());
  }

  // 关闭弹窗
  closeSheet(): void {
    this.isSheetShow = false
  }

  // ==================== 弹窗打开方法 ====================

  // 打开编辑饮品弹窗
  private openEditSheet(shopId: number, shopName: string, drinks: ShopDrinkRecord[]): void {
    capturedEditShopId = shopId
    capturedEditShopName = shopName
    capturedEditDrinks = drinks
    this.sheetType = 'edit'
    this.isSheetShow = true
  }

  // 打开导入弹窗
  private openImportDialog(): void {
    capturedImportPreview = this.importPreview
    this.sheetType = 'import'
    this.isSheetShow = true
  }

  // 打开添加店铺弹窗
  private openAddShopSheet(): void {
    capturedAddShopCallback = (shopName: string): void => {
      this.addNewShop(shopName)
    }
    this.sheetType = 'addShop'
    this.isSheetShow = true
  }

  // 删除按钮构建器
  @Builder
  deleteItemBuilder(shop: ShopRecord) {
    Row({ space: 10 }) {
      Text("编辑")
        .fontSize(16)
        .fontColor(Color.White)
        .width(60)
        .height(36)
        .textAlign(TextAlign.Center)
        .backgroundColor("#8D6B4F")
        .borderRadius(8)
        .onClick(async () => {
          const drinks = await this.shopDrinkDao.queryByShopId(shop.id);
          this.openEditSheet(shop.id, shop.shopName, drinks);
        })

      Text("删除")
        .fontSize(16)
        .fontColor(Color.White)
        .width(60)
        .height(36)
        .textAlign(TextAlign.Center)
        .backgroundColor("#4CAF50")
        .borderRadius(8)
        .onClick(() => {
          this.deleteShop(shop.id);
        })
    }
    .justifyContent(FlexAlign.Center)
    .padding({ right: 16 })
    .height("100%")
  }

  // ==================== 分享相关方法 ====================

  // 分享店铺数据
  async shareShops(): Promise<void> {
    if (this.isSharing) return
    this.isSharing = true

    try {
      const jsonData = await this.exportImportManager.exportToJson()
      await ShareUtil.shareJsonFile(jsonData, 'coffee_shops.json', this.getUIContext())
    } catch (err) {
      console.error('[ShopManagePage] shareShops error: ' + JSON.stringify(err))
    } finally {
      this.isSharing = false
    }
  }

  // 处理收到的分享数据
  async handleSharedData(jsonData: string): Promise<void> {
    const preview = await this.exportImportManager.getSharePreview(jsonData)
    if (preview) {
      this.importPreview = preview
      this.pendingImportData = jsonData
      this.openImportDialog()
    } else {
      console.error('[ShopManagePage] Invalid share data format')
    }
  }

  // 确认导入
  async confirmImport(): Promise<void> {
    if (!this.pendingImportData) return

    const options: ImportOptions = {
      skipExisting: false,
      mergeDrinks: true
    };
    const count = await this.exportImportManager.importFromJson(this.pendingImportData, options)

    if (count > 0) {
      await this.loadShops()
    }

    this.closeSheet()
  }

  // ==================== 添加店铺相关方法 ====================

  // 添加新店铺
  async addNewShop(shopName: string): Promise<void> {
    const newShop: ShopRecord = {
      id: 0,
      shopName: shopName,
      createTime: Date.now()
    }
    await this.shopDao.insert(newShop)
    this.closeSheet()
    await this.loadShops()
  }

  // ==================== 弹窗构建器 ====================

  @Builder
  sheetBuilder() {
    if (this.sheetType === 'edit') {
      // 编辑饮品弹窗
      editShopDrinkBuilder({
        shopId: capturedEditShopId,
        shopName: capturedEditShopName,
        drinks: capturedEditDrinks,
        onClose: (): void => {
          this.closeSheet()
        },
        onSaved: (): void => {
          this.closeSheet()
          AppStorage.setOrCreate('needRefreshShops', Date.now());
        }
      })
    } else if (this.sheetType === 'import') {
      // 导入弹窗
      Column({ space: 16 }) {
        Text('导入店铺数据')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))

        if (capturedImportPreview) {
          Column({ space: 8 }) {
            Text(`店铺数量: ${capturedImportPreview.shopCount}`)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
            Text(`饮品数量: ${capturedImportPreview.drinkCount}`)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
            Text(`导出时间: ${capturedImportPreview.exportedAt}`)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))

            Text('店铺列表:')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8 })

            Scroll() {
              Text(capturedImportPreview.shopNames.join(', '))
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
            }
            .height(60)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        } else {
          Text('正在解析分享数据...')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }

        Row({ space: 20 }) {
          Button('取消')
            .width(100)
            .height(40)
            .backgroundColor('#E0E0E0')
            .fontColor('#666666')
            .borderRadius(20)
            .onClick(() => {
              this.closeSheet()
            })

          Button('导入')
            .width(100)
            .height(40)
            .backgroundColor('#8D6B4F')
            .fontColor(Color.White)
            .borderRadius(20)
            .onClick(async () => {
              await this.confirmImport()
            })
        }
        .margin({ top: 20 })
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Color.White)
    } else if (this.sheetType === 'addShop') {
      // 添加店铺弹窗
      AddShopSheet({
        onAdd: (shopName: string): void => {
          if (capturedAddShopCallback) {
            capturedAddShopCallback(shopName)
          }
        },
        onClose: (): void => {
          this.closeSheet()
        }
      })
    }
  }

  // 获取弹窗高度
  getSheetHeight(): string {
    if (this.sheetType === 'edit') {
      return '80%'
    }
    return '50%'
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('<')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })

        Text("店铺管理")
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 5 })

        Blank()

        // 添加店铺按钮（打开弹窗）
        Row() {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(16)
            .fontColor([$r('app.color.symbol_primary')])
        }
        .width(32)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.openAddShopSheet()
        })

        // 分享按钮
        Row() {
          SymbolGlyph($r('sys.symbol.share'))
            .fontSize(16)
            .fontColor([$r('app.color.symbol_primary')])
        }
        .width(32)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .margin({ left: 8 })
        .onClick(() => this.shareShops())
      }
      .width("100%")
      .height(50)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 10, right: 10 })

      // Scroll外面的Column，从顶部开始排列
      Column({ space: 0 }) {
        Scroll() {
          Column() {
            List({ space: 0 }) {
              ForEach(this.shops, (shop: ShopRecord, index: number) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text(shop.shopName)
                        .fontSize(16)
                    }
                    .width("100%")
                    .height(50)
                    .justifyContent(FlexAlign.Start)
                    .padding({ left: 16, right: 16 })

                    // 分隔线
                    if (index < this.shops.length - 1) {
                      Row()
                        .width("100%")
                        .height(0.5)
                        .backgroundColor($r('app.color.divider_color'))
                    }
                  }
                }
                .swipeAction({
                  edgeEffect: SwipeEdgeEffect.Spring,
                  end: {
                    builder: () => {
                      this.deleteItemBuilder(shop)
                    },
                    actionAreaDistance: 10
                  }
                })
              }, (shop: ShopRecord) => shop.id.toString())
            }
            .edgeEffect(EdgeEffect.None)
            .scrollBarColor(Color.Transparent)
          }
          .width("94%")
          .backgroundColor($r('app.color.background_card'))
          .borderRadius(15)
          .shadow({
            radius: 20,
            color: $r('app.color.shadow_color'),
            offsetY: 8
          })
          .margin({ left: "3%", right: "3%", top: 0 ,bottom:8})
        }
        .scrollBarColor(Color.Transparent)
      }
      .layoutWeight(1)
      .height("100%")
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 10 })
    }
    .width("100%")
    .height("100%")
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),
    })
    .backgroundColor($r('app.color.background_primary'))
    // 单一弹窗，根据类型显示不同内容
    .bindSheet(this.isSheetShow, this.sheetBuilder, {
      height: this.getSheetHeight(),
      showClose: false,
      preferType: SheetType.BOTTOM
    })
  }
}
