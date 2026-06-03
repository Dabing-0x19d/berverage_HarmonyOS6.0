import { router, componentSnapshot } from '@kit.ArkUI';
import { formBindingData, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { TianjiaSheet } from '../model/tianjia'
import { CoffeeDao } from '../model/CoffeeDao'
import { CoffeeRecord } from '../model/CoffeeRecord'
import { CoffeeDatabase } from '../model/CoffeeDatabase'
import { TodayStatsCard, ShopRankCard, RecentRecordsCard, RankShareCard, ShopCountData } from '../components/HomeCard'
import { ShareUtil } from '../utils/ShareUtil'
import { ShopDao } from '../model/ShopDao'
import { ShopRecord } from '../model/ShopRecord'
import { ShopDrinkRecord } from '../model/ShopDrinkRecord'
import { ShopDrinkDao } from '../model/ShopDrinkDao'
import { relationalStore } from '@kit.ArkData'
import { PreferencesUtil } from '../common/utils/PreferencesUtil'

// 卡片刷新相关常量
const FIVE_MINUTE: number = 5 * 60 * 1000;

// 闭包捕获变量 - 用于弹窗
let capturedShops: string[] = []
let capturedShopDrinks: ShopDrinkRecord[] = []
let capturedShopCounts: Map<string, number> = new Map()
let capturedShopData: ShopCountData[] = []

@Entry
@Component
export struct Home {
  // 今日统计数据
  @State todayCups: number = 0
  @State todayCaffeine: number = 0
  @State todaySugar: number = 0
  // 选择的数据
  @State selectedShop: string = ''
  @State selectedShopId: number = 0

  // 弹窗类型状态
  @State sheetType: 'add' | 'shareRank' = 'add'
  @State selectedDrink: string = ''
  @State selectedSugar: number = 0
  // 当前显示的店铺列表（根据排序）
  @State shops: string[] = []
  // 店铺ID映射
  @State shopIdMap: Map<string, number> = new Map()
  // 当前店铺的饮品列表（根据排序）
  @State currentShopDrinks: ShopDrinkRecord[] = []
  // 所有店铺饮品（用于图标）
  private allShopDrinks: ShopDrinkRecord[] = []
  // 最近记录
  @State recentRecords: CoffeeRecord[] = []

  // 日历相关状态
  @State year: number = new Date().getFullYear()
  @State month: number = new Date().getMonth() + 1
  @State completedDays: number[] = []
  private weekDays: string[] = ['日', '一', '二', '三', '四', '五', '六']

  // DAO 实例
  private coffeeDao: CoffeeDao = new CoffeeDao()
  private shopDao: ShopDao = new ShopDao()
  private shopDrinkDao: ShopDrinkDao = new ShopDrinkDao()
  // 监听店铺刷新信号
  @Watch('onRefreshShopsChange')
  @StorageLink('needRefreshShops') refreshSignal: number = 0

  // 分享相关状态
  @State isSharing: boolean = false
  // 弹窗显示控制
  @State isSheetShow: boolean = false
  // 隐藏的截图专用状态（不显示但可截图）
  @State captureReady: boolean = false
  // 弹窗内容版本号（用于强制刷新）
  @State sheetContentVersion: number = 0
  // 添加弹窗的数据（使用@State以便响应式更新）
  @State sheetShops: string[] = []
  @State sheetShopDrinks: ShopDrinkRecord[] = []
  @State sheetSelectedShop: string = ''
  @State sheetSelectedDrink: string = ''
  @State sheetSelectedSugar: number = 0
  // 分享榜单数据（使用@State以便响应式更新）
  @State shareShopData: ShopCountData[] = []

  // 监听收到的分享数据
  @Watch('onPendingShareDataChange')
  @StorageLink('pendingShopShareData') pendingShareData: string = ''

  onPendingShareDataChange() {
    if (this.pendingShareData) {
      console.info('[Home] Pending share data detected');
      router.pushUrl({ url: 'pages/ShopManagePage' })
      AppStorage.setOrCreate('pendingShopShareData', '')
    }
  }

  onRefreshShopsChange() {
    if (this.refreshSignal > 0) {
      this.loadShops();
      this.loadRecords();
    }
  }

  // 页面加载
  async aboutToAppear(): Promise<void> {
    while (!CoffeeDatabase.getRdbStore()) {
      await new Promise<void>((resolve) => setTimeout(resolve, 20));
    }
    await this.loadShops();
    await this.loadAllShopDrinks();
    this.loadRecords();
  }

  // 从数据库加载店铺列表
  async loadShops(): Promise<void> {
    const dbShops: ShopRecord[] = await this.shopDao.queryAll();
    this.shops = dbShops.map(s => s.shopName);
    this.shopIdMap = new Map();
    dbShops.forEach(s => {
      this.shopIdMap.set(s.shopName, s.id);
    });
  }

  // 加载所有店铺饮品
  async loadAllShopDrinks(): Promise<void> {
    this.allShopDrinks = await this.shopDrinkDao.queryAll();
  }

  // 根据喝的最多的品牌排序店铺
  sortShopsByMostConsumed(records: CoffeeRecord[], dbShops: ShopRecord[]) {
    const shopCounts: Map<string, number> = new Map()
    records.forEach(r => {
      const current = shopCounts.get(r.shopName) || 0
      shopCounts.set(r.shopName, current + 1)
    })

    const shopNames = dbShops.map(s => s.shopName)
    this.shops = shopNames.sort((a, b) => {
      const countA = shopCounts.get(a) || 0
      const countB = shopCounts.get(b) || 0
      return countB - countA
    })
  }

  // 选择店铺时加载该店铺的饮品
  async onShopSelected(shopName: string): Promise<void> {
    this.selectedShop = shopName;
    this.selectedShopId = this.shopIdMap.get(shopName) || 0;
    this.selectedDrink = '';

    const shopDrinks = await this.shopDrinkDao.queryByShopId(this.selectedShopId);
    const drinkCounts = await this.getDrinkCounts();
    shopDrinks.sort((a, b) => {
      const countA = drinkCounts.get(a.drinkName) || 0;
      const countB = drinkCounts.get(b.drinkName) || 0;
      return countB - countA;
    });
    this.currentShopDrinks = shopDrinks;

    // 打开添加弹窗
    this.openAddSheetDirectly();
  }

  // 获取饮品消费统计
  async getDrinkCounts(): Promise<Map<string, number>> {
    const counts = new Map<string, number>();
    const records = await this.coffeeDao.queryAll();
    records.forEach(r => {
      const current = counts.get(r.drinkName) || 0;
      counts.set(r.drinkName, current + 1);
    });
    return counts;
  }

  // 从数据库加载记录
  async loadRecords() {
    if (!CoffeeDatabase.getRdbStore()) return
    const records = await this.coffeeDao.queryAll()
    this.recentRecords = [...records]

    // 计算今日统计
    const today = new Date()
    const todayRecords = this.recentRecords.filter(r => {
      const recordDate = new Date(r.createTime)
      return recordDate.toDateString() === today.toDateString()
    })

    this.todayCups = todayRecords.length
    this.todayCaffeine = todayRecords.reduce((sum, r) => sum + r.caffeine, 0)
    this.todaySugar = todayRecords.reduce((sum, r) => sum + r.sugar, 0)

    const dbShops = await this.shopDao.queryAll()
    this.sortShopsByMostConsumed(records, dbShops)
    this.updateCompletedDays(records)

    // 同步周统计数据到数据库，供卡片使用
    await this.syncWeeklyDataToWidget(records)
    // 同步月统计数据到数据库，供卡片使用
    await this.syncMonthlyDataToWidget(records)
  }

  // 同步周统计数据到数据库
  async syncWeeklyDataToWidget(records: CoffeeRecord[]) {
    const now = new Date()
    const currentDayOfWeek = now.getDay()
    const weekStart = new Date(now)
    weekStart.setDate(now.getDate() - currentDayOfWeek)
    weekStart.setHours(0, 0, 0, 0)
    const weekEnd = new Date(weekStart)
    weekEnd.setDate(weekStart.getDate() + 6)
    weekEnd.setHours(23, 59, 59, 999)

    const weeklySpending: number[] = new Array(7).fill(0)
    let totalSpending: number = 0

    records.forEach((record: CoffeeRecord) => {
      const recordDate = new Date(record.createTime)
      if (recordDate >= weekStart && recordDate <= weekEnd) {
        const dayOfWeek = recordDate.getDay()
        const cost = record.cost || 0
        weeklySpending[dayOfWeek] += cost
        totalSpending += cost
      }
    })

    const startMonth = weekStart.getMonth() + 1
    const startDay = weekStart.getDate()
    const endMonth = weekEnd.getMonth() + 1
    const endDay = weekEnd.getDate()

    // 存储到数据库
    const rdbStore = CoffeeDatabase.getRdbStore()
    if (!rdbStore) return

    // 确保表存在
    await rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS widget_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sunday TEXT, monday TEXT, tuesday TEXT, wednesday TEXT,
      thursday TEXT, friday TEXT, saturday TEXT,
      total TEXT, dateRange TEXT
    )`)

    // 删除旧数据，插入新数据
    await rdbStore.executeSql('DELETE FROM widget_data')
    await rdbStore.executeSql(
      `INSERT INTO widget_data (sunday, monday, tuesday, wednesday, thursday, friday, saturday, total, dateRange)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [weeklySpending[0].toString(), weeklySpending[1].toString(), weeklySpending[2].toString(),
       weeklySpending[3].toString(), weeklySpending[4].toString(), weeklySpending[5].toString(),
       weeklySpending[6].toString(), totalSpending.toString(), `${startMonth}.${startDay} - ${endMonth}.${endDay}`]
    )

    // 注意：不再直接调用 updateWeekWidgets，统一由 refreshAllWidgets 处理更新
    // 避免多次调用 updateForm 导致的数据覆盖问题

    console.info('[Home] Widget data saved to database, waiting for refreshAllWidgets to update');
  }

  // 直接更新所有周数据卡片 - 此方法已弃用，统一由 refreshAllWidgets 处理
  /**
   * @deprecated 此方法已弃用，请使用 refreshAllWidgets
   */
  private updateWeekWidgets(weeklySpending: number[], totalSpending: number, dateRange: string): void {
    console.warn('[Home] updateWeekWidgets is deprecated, use refreshAllWidgets instead');
  }

  // 同步历史总排行到数据库
  async syncMonthlyDataToWidget(records: CoffeeRecord[]) {
    console.info('[Home] syncMonthlyDataToWidget: 开始处理, records.length=' + records.length)
    // 统计所有历史记录每个店铺的消费次数
    const shopCounts: Map<string, number> = new Map()

    records.forEach((record: CoffeeRecord) => {
      const current = shopCounts.get(record.shopName) || 0
      shopCounts.set(record.shopName, current + 1)
    })

    // ArkTS 不支持 Object.fromEntries，手动转换
    const shopCountsObj: Record<string, number> = {}
    shopCounts.forEach((value, key) => {
      shopCountsObj[key] = value
    })
    console.info('[Home] syncMonthlyDataToWidget: shopCounts=' + JSON.stringify(shopCountsObj))

    // 获取Top3店铺
    const sortedShops = Array.from(shopCounts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)

    console.info('[Home] syncMonthlyDataToWidget: sortedShops=' + JSON.stringify(sortedShops))

    const shopNames: string[] = []
    const shopCountValues: number[] = []
    for (let i = 0; i < sortedShops.length; i++) {
      shopNames.push(sortedShops[i][0])
      shopCountValues.push(sortedShops[i][1])
    }

    // 填充数据到3个槽位
    const shops: string[] = []
    const counts: number[] = []
    for (let i = 0; i < 3; i++) {
      shops.push(shopNames[i] || '')
      counts.push(shopCountValues[i] || 0)
    }

    console.info('[Home] syncMonthlyDataToWidget: 最终数据 shops=' + JSON.stringify(shops) + ', counts=' + JSON.stringify(counts))

    // 存储到数据库
    const rdbStore = CoffeeDatabase.getRdbStore()
    if (!rdbStore) {
      console.warn('[Home] syncMonthlyDataToWidget: rdbStore is null')
      return
    }

    // 确保历史排行统计数据表存在
    await rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS history_widget_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shop1 TEXT, count1 TEXT, shop2 TEXT, count2 TEXT,
      shop3 TEXT, count3 TEXT
    )`)

    // 删除旧数据，插入新数据
    await rdbStore.executeSql('DELETE FROM history_widget_data')
    await rdbStore.executeSql(
      `INSERT INTO history_widget_data (shop1, count1, shop2, count2, shop3, count3)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [shops[0], counts[0].toString(), shops[1], counts[1].toString(),
       shops[2], counts[2].toString()]
    )

    // 注意：不再直接调用 updateMonthWidgets，统一由 refreshAllWidgets 处理更新
    // 避免多次调用 updateForm 导致的数据覆盖问题

    console.info('[Home] History widget data saved to database, waiting for refreshAllWidgets to update');
  }

  // 直接更新所有历史排行卡片
  private updateMonthWidgets(shops: string[], counts: number[]): void {
    console.info('[Home] updateMonthWidgets: 开始执行, shops=' + JSON.stringify(shops) + ', counts=' + JSON.stringify(counts))
    const util = PreferencesUtil.getInstance();
    const context = this.getUIContext().getHostContext();
    if (!context) {
      console.error('[Home] updateMonthWidgets: Failed to get context');
      return;
    }
    const preferences = util.getPreferences(context);
    if (!preferences) {
      console.error('[Home] updateMonthWidgets: Failed to get preferences');
      return;
    }

    // 调试：打印 preferences 中的所有 key
    try {
      const allKeys = ['weekFormIdList', 'monthFormIdList', 'weekFormIds', 'monthFormIds'];
      allKeys.forEach(key => {
        const val = preferences.getSync(key, 'NOT_FOUND');
        console.info(`[Home] Preferences[${key}] = ${JSON.stringify(val)}`);
      });
    } catch (e) {
      console.error('[Home] Failed to read preferences keys');
    }

    const formIds = util.getMonthFormIds(preferences);
    console.info(`[Home] updateMonthWidgets: formIds = ${JSON.stringify(formIds)}, shops = ${JSON.stringify(shops)}`);
    if (formIds.length === 0) {
      console.info('[Home] No month widgets registered to update');
      return;
    }

    const widgetData: Record<string, string> = {
      'shop1': shops[0] || '',
      'count1': counts[0].toString(),
      'shop2': shops[1] || '',
      'count2': counts[1].toString(),
      'shop3': shops[2] || '',
      'count3': counts[2].toString(),
      '_timestamp': Date.now().toString() // 关键：添加时间戳确保 @Watch 触发
    };

    const formMsg = formBindingData.createFormBindingData(widgetData);
    console.info(`[Home] updateMonthWidgets: Calling updateForm for ${formIds.length} widgets, data: ${JSON.stringify(widgetData)}`);

    formIds.forEach((formId: string) => {
      formProvider.updateForm(formId, formMsg)
        .then(() => {
          console.info(`[Home] updateForm success for month formId: ${formId}`);
        })
        .catch((error: BusinessError) => {
          console.error(`[Home] updateForm failed for formId: ${formId}, error: ${JSON.stringify(error)}`);
          // 如果卡片已删除（错误码 16501001），清理无效的 formId
          if (error.code === 16501001) {
            console.info(`[Home] Removing invalid formId: ${formId} from preferences`);
            util.removeMonthFormId(preferences, formId);
          }
        });
    });

    console.info(`[Home] Updating ${formIds.length} month widgets with shop data`);
  }

  // 日历方法
  getDaysInMonth(year: number, month: number): number {
    return new Date(year, month, 0).getDate()
  }

  getFirstDayOfWeek(year: number, month: number): number {
    return new Date(year, month - 1, 1).getDay()
  }

  buildCalendarData(): (number | null)[] {
    const daysInMonth = this.getDaysInMonth(this.year, this.month)
    const firstDay = this.getFirstDayOfWeek(this.year, this.month)
    const data: (number | null)[] = []
    for (let i = 0; i < firstDay; i++) data.push(null)
    for (let i = 1; i <= daysInMonth; i++) data.push(i)
    return data
  }

  isCompleted(day: number): boolean {
    return this.completedDays.includes(day)
  }

  isToday(day: number): boolean {
    const now = new Date()
    return day === now.getDate() && this.year === now.getFullYear() && this.month === now.getMonth() + 1
  }

  prevMonth() {
    if (this.month > 1) {
      this.month--
    } else {
      this.month = 12
      this.year--
    }
    this.loadRecords()
  }

  nextMonth() {
    if (this.month < 12) {
      this.month++
    } else {
      this.month = 1
      this.year++
    }
    this.loadRecords()
  }

  updateCompletedDays(records: CoffeeRecord[]) {
    const days: number[] = []
    records.forEach(record => {
      const date = new Date(record.createTime)
      if (date.getFullYear() === this.year && date.getMonth() + 1 === this.month) {
        if (!days.includes(date.getDate())) days.push(date.getDate())
      }
    })
    this.completedDays = days
  }

  // 格式化时间
  formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const now = new Date()
    const todayStr = `${now.getMonth() + 1}月${now.getDate()}日`
    const recordDateStr = `${date.getMonth() + 1}月${date.getDate()}日`

    if (todayStr === recordDateStr) {
      return `今天 ${this.formatTimeOnly(date)}`
    }

    const yesterday = new Date(now)
    yesterday.setDate(yesterday.getDate() - 1)
    const yesterdayStr = `${yesterday.getMonth() + 1}月${yesterday.getDate()}日`

    if (recordDateStr === yesterdayStr) {
      return `昨天 ${this.formatTimeOnly(date)}`
    }

    return `${date.getMonth() + 1}-${date.getDate()} ${this.formatTimeOnly(date)}`
  }

  formatTimeOnly(date: Date): string {
    const hour = date.getHours().toString().padStart(2, '0')
    const minute = date.getMinutes().toString().padStart(2, '0')
    return `${hour}:${minute}`
  }

  // 关闭弹窗
  closeSheet() {
    this.isSheetShow = false
    this.selectedShop = ''
    this.selectedShopId = 0
    this.selectedDrink = ''
    this.selectedSugar = 0
    this.currentShopDrinks = []
  }




  // 删除记录
  async deleteRecord(id: number) {
    const success = await this.coffeeDao.delete(id)
    if (success) {
      await this.loadRecords()
      await this.refreshAllWidgets()
    }
  }

  // 刷新所有卡片（遍历formId逐个更新，查询数据库获取实际数据）
  async refreshAllWidgets(): Promise<void> {
    console.info('[Home] refreshAllWidgets: 开始执行')
    try {
      // 获取所有卡片formId
      const weekFormIds = await PreferencesUtil.getWeekFormIds()
      const monthFormIds = await PreferencesUtil.getMonthFormIds()

      console.info(`[Home] refreshAllWidgets: weekFormIds=${JSON.stringify(weekFormIds)}, monthFormIds=${JSON.stringify(monthFormIds)}`)

      if (weekFormIds.length === 0 && monthFormIds.length === 0) {
        console.info('[Home] refreshAllWidgets: 没有卡片需要刷新')
        return
      }

      // 从数据库查询周数据（用于widget1）
      console.info('[Home] refreshAllWidgets: 开始查询周数据')
      const weekData = await this.loadWeekWidgetData()
      // 重要：添加时间戳确保数据变化能被 @Watch 监听到
      weekData['_timestamp'] = Date.now().toString()
      console.info(`[Home] refreshAllWidgets: weekData=${JSON.stringify(weekData)}`)

      // 逐个刷新周统计卡片（widget1）
      const util = PreferencesUtil.getInstance()
      const context = this.getUIContext().getHostContext()
      if (!context) {
        console.error('[Home] refreshAllWidgets: Failed to get context')
        return
      }
      const preferences = util.getPreferences(context)
      if (!preferences) {
        console.error('[Home] refreshAllWidgets: Failed to get preferences')
        return
      }

      for (const formId of weekFormIds) {
        console.info(`[Home] refreshAllWidgets: 刷新week卡片 formId=${formId}`)
        // 构造完整的数据对象
        const fullWeekData: Record<string, string> = {
          'sunday': weekData['sunday'],
          'monday': weekData['monday'],
          'tuesday': weekData['tuesday'],
          'wednesday': weekData['wednesday'],
          'thursday': weekData['thursday'],
          'friday': weekData['friday'],
          'saturday': weekData['saturday'],
          'total': weekData['total'],
          'dateRange': weekData['dateRange'],
          '_timestamp': weekData['_timestamp']
        }
        console.info(`[Home] refreshAllWidgets: week完整数据=${JSON.stringify(fullWeekData)}`)
        // 保存数据到Preferences（供卡片进程读取）
        util.saveWidgetData(preferences, formId, fullWeekData)
        // 直接使用 formBindingData 传递数据
        try {
          const formBinding = formBindingData.createFormBindingData(fullWeekData)
          await formProvider.updateForm(formId, formBinding)
          console.info(`[Home] refreshAllWidgets: week卡片刷新成功 formId=${formId}`)
        } catch (updateError) {
          const e: BusinessError = updateError as BusinessError
          console.error(`[Home] updateForm failed for week ${formId}: ${e.code}, ${e.message}`)
        }
      }

      // 从数据库查询历史排行数据（用于widget2）
      console.info('[Home] refreshAllWidgets: 开始查询历史排行数据')
      const monthData = await this.loadMonthWidgetData()
      // 重要：添加时间戳确保数据变化能被 @Watch 监听到
      const timestamp = Date.now().toString()
      monthData['_timestamp'] = timestamp
      console.info(`[Home] refreshAllWidgets: monthData查询结果 shop1=${monthData['shop1']}, count1=${monthData['count1']}, shop2=${monthData['shop2']}, count2=${monthData['count2']}, shop3=${monthData['shop3']}, count3=${monthData['count3']}`)

      // 逐个刷新店铺榜单卡片（widget2）
      for (const formId of monthFormIds) {
        console.info(`[Home] refreshAllWidgets: 刷新month卡片 formId=${formId}`)
        // 构造完整的数据对象
        const fullMonthData: Record<string, string> = {
          'shop1': monthData['shop1'] || '',
          'count1': monthData['count1'] || '0',
          'shop2': monthData['shop2'] || '',
          'count2': monthData['count2'] || '0',
          'shop3': monthData['shop3'] || '',
          'count3': monthData['count3'] || '0',
          '_timestamp': timestamp
        }
        console.info(`[Home] refreshAllWidgets: month完整数据=${JSON.stringify(fullMonthData)}`)
        // 保存数据到Preferences（供卡片进程读取）
        util.saveWidgetData(preferences, formId, fullMonthData)
        // 直接使用 formBindingData 传递数据
        try {
          const formBinding = formBindingData.createFormBindingData(fullMonthData)
          console.info(`[Home] refreshAllWidgets: 调用updateForm formId=${formId}`)
          await formProvider.updateForm(formId, formBinding)
          console.info(`[Home] refreshAllWidgets: month卡片刷新成功 formId=${formId}`)
        } catch (updateError) {
          const e: BusinessError = updateError as BusinessError
          console.error(`[Home] updateForm failed for month ${formId}: ${e.code}, ${e.message}`)
        }
      }
      console.info('[Home] refreshAllWidgets: 执行完成')
    } catch (error) {
      const e: BusinessError = error as BusinessError
      console.error(`[Home] refreshAllWidgets failed: ${e.code}, ${e.message}`)
    }
  }

  // 从数据库加载周统计数据（参考EntryFormAbility.getWeekDataFromDb）
  async loadWeekWidgetData(): Promise<Record<string, string>> {
    console.info('[Home] loadWeekWidgetData: 开始查询数据库')
    const resultData: Record<string, string> = {
      'sunday': '0', 'monday': '0', 'tuesday': '0', 'wednesday': '0',
      'thursday': '0', 'friday': '0', 'saturday': '0',
      'total': '0', 'dateRange': ''
    }

    try {
      const rdbStore = await relationalStore.getRdbStore(getContext(this), {
        name: 'CoffeeDatabase.db',
        securityLevel: relationalStore.SecurityLevel.S1
      })

      console.info('[Home] loadWeekWidgetData: 开始查询widget_data表')
      const resultSet = await rdbStore.querySql('SELECT * FROM widget_data ORDER BY id DESC LIMIT 1')
      if (resultSet.goToNextRow()) {
        console.info('[Home] loadWeekWidgetData: 查询到数据')
        resultData['sunday'] = resultSet.getString(resultSet.getColumnIndex('sunday'));
        resultData['monday'] = resultSet.getString(resultSet.getColumnIndex('monday'));
        resultData['tuesday'] = resultSet.getString(resultSet.getColumnIndex('tuesday'));
        resultData['wednesday'] = resultSet.getString(resultSet.getColumnIndex('wednesday'));
        resultData['thursday'] = resultSet.getString(resultSet.getColumnIndex('thursday'));
        resultData['friday'] = resultSet.getString(resultSet.getColumnIndex('friday'));
        resultData['saturday'] = resultSet.getString(resultSet.getColumnIndex('saturday'));
        resultData['total'] = resultSet.getString(resultSet.getColumnIndex('total'));
        resultData['dateRange'] = resultSet.getString(resultSet.getColumnIndex('dateRange'));
      } else {
        console.info('[Home] loadWeekWidgetData: 未查询到数据，使用默认值')
      }
      resultSet.close()
    } catch (err) {
      const e: BusinessError = err as BusinessError
      console.error(`[Home] loadWeekWidgetData error: ${e.code}, ${e.message}`)
    }

    console.info('[Home] loadWeekWidgetData: 返回数据', JSON.stringify(resultData))
    return resultData
  }

  // 从数据库加载历史排行数据（参考EntryFormAbility.getMonthDataFromDb）
  async loadMonthWidgetData(): Promise<Record<string, string>> {
    console.info('[Home] loadMonthWidgetData: 开始查询数据库')
    const resultData: Record<string, string> = {
      'shop1': '', 'count1': '0',
      'shop2': '', 'count2': '0',
      'shop3': '', 'count3': '0'
    }

    try {
      const rdbStore = await relationalStore.getRdbStore(getContext(this), {
        name: 'CoffeeDatabase.db',
        securityLevel: relationalStore.SecurityLevel.S1
      })

      console.info('[Home] loadMonthWidgetData: 开始查询history_widget_data表')
      const resultSet = await rdbStore.querySql('SELECT * FROM history_widget_data ORDER BY id DESC LIMIT 1')
      if (resultSet.goToNextRow()) {
        console.info('[Home] loadMonthWidgetData: 查询到数据')
        resultData['shop1'] = resultSet.getString(resultSet.getColumnIndex('shop1'));
        resultData['count1'] = resultSet.getString(resultSet.getColumnIndex('count1'));
        resultData['shop2'] = resultSet.getString(resultSet.getColumnIndex('shop2'));
        resultData['count2'] = resultSet.getString(resultSet.getColumnIndex('count2'));
        resultData['shop3'] = resultSet.getString(resultSet.getColumnIndex('shop3'));
        resultData['count3'] = resultSet.getString(resultSet.getColumnIndex('count3'));
      } else {
        console.info('[Home] loadMonthWidgetData: 未查询到数据，使用默认值')
      }
      resultSet.close()
    } catch (err) {
      const e: BusinessError = err as BusinessError
      console.error(`[Home] loadMonthWidgetData error: ${e.code}, ${e.message}`)
    }

    console.info('[Home] loadMonthWidgetData: 返回数据', JSON.stringify(resultData))
    return resultData
  }

  // 确认添加
  async confirmAdd() {
    console.info('[Home] confirmAdd: 开始执行')
    if (this.sheetSelectedShop && this.sheetSelectedDrink) {
      console.info(`[Home] confirmAdd: shop=${this.sheetSelectedShop}, drink=${this.sheetSelectedDrink}`)
      const drinkInfo = this.sheetShopDrinks.find(d => d.drinkName === this.sheetSelectedDrink)
      const newRecord: CoffeeRecord = {
        id: 0,
        shopName: this.sheetSelectedShop,
        drinkName: this.sheetSelectedDrink,
        caffeine: drinkInfo?.caffeine || 100,
        cost: drinkInfo?.cost || 15,
        sugar: this.sheetSelectedSugar,
        createTime: Date.now()
      }
      console.info('[Home] confirmAdd: 插入记录', JSON.stringify(newRecord))
      await this.coffeeDao.insert(newRecord)
      this.closeSheet()
      console.info('[Home] confirmAdd: 调用loadRecords')
      await this.loadRecords()
      console.info('[Home] confirmAdd: 调用refreshAllWidgets')
      await this.refreshAllWidgets()
      console.info('[Home] confirmAdd: 执行完成')
    } else {
      console.warn('[Home] confirmAdd: shop或drink为空', this.sheetSelectedShop, this.sheetSelectedDrink)
    }
  }

  // 分享榜单图片
  async shareRankImage(): Promise<void> {
    if (this.isSharing) return
    this.isSharing = true

    try {
      // 重新加载并排序店铺数据
      await this.loadShopCounts()

      // 构建分享数据
      const shopCounts = await this.coffeeDao.getShopCounts()
      const dataList: ShopCountData[] = []
      this.shops.forEach(name => {
        dataList.push({ name: name, count: shopCounts.get(name) || 0 })
      })
      this.shareShopData = dataList

      // 设置截图状态，渲染隐藏的RankShareCard
      this.captureReady = true

      // 等待渲染后截图（不显示弹窗）
      await new Promise<void>((resolve) => setTimeout(resolve, 300))
      const pixelMap = await componentSnapshot.get('rankShareCard')
      if (pixelMap) {
        this.captureReady = false
        await ShareUtil.sharePixelMapAsImage(pixelMap, this.getUIContext())
      } else {
        this.captureReady = false
      }
    } catch (err) {
      this.captureReady = false
      console.error('[Home] shareRankImage error: ' + JSON.stringify(err))
    } finally {
      this.isSharing = false
    }
  }

  // 分享日历图片
  async shareCalendarImage(): Promise<void> {
    if (this.isSharing) return
    this.isSharing = true

    try {
      await new Promise<void>((resolve) => setTimeout(resolve, 500))
      const pixelMap = await componentSnapshot.get('calendarShareCard')
      if (pixelMap) {
        // 直接分享原始图片
        await ShareUtil.sharePixelMapAsImage(pixelMap, this.getUIContext())
      }
    } catch (err) {
      console.error('[Home] shareCalendarImage error: ' + JSON.stringify(err))
    } finally {
      this.isSharing = false
    }
  }

  // 获取店铺消费统计
  async loadShopCounts(): Promise<void> {
    const counts = new Map<string, number>();
    const records = await this.coffeeDao.queryAll();
    records.forEach(r => {
      const current = counts.get(r.shopName) || 0;
      counts.set(r.shopName, current + 1);
    });
    // 排序
    this.shops = this.shops.sort((a, b) => {
      const countA = counts.get(a) || 0
      const countB = counts.get(b) || 0
      return countB - countA
    })
  }

  // 直接打开添加弹窗（店铺选择后调用）
  private openAddSheetDirectly(): void {
    this.sheetShops = [...this.shops]
    this.sheetShopDrinks = [...this.currentShopDrinks]
    this.sheetSelectedShop = this.selectedShop
    this.sheetSelectedDrink = ''
    this.sheetSelectedSugar = 0
    this.sheetType = 'add'
    // 先关闭再打开，确保弹窗能重新触发
    this.isSheetShow = false
    setTimeout(() => {
      this.isSheetShow = true
    }, 50)
  }

  // 打开添加弹窗（点击+按钮）
  private openAddSheet(): void {
    this.sheetShops = [...this.shops]
    this.sheetShopDrinks = []
    this.sheetSelectedShop = ''
    this.sheetSelectedDrink = ''
    this.sheetSelectedSugar = 0
    this.sheetType = 'add'
    // 先关闭再打开，确保弹窗能重新触发
    this.isSheetShow = false
    setTimeout(() => {
      this.isSheetShow = true
    }, 50)
  }

  // 弹窗中选择店铺时加载该店铺的饮品
  private async onSheetShopChanged(shopName: string): Promise<void> {
    if (!shopName) {
      this.sheetShopDrinks = []
      return
    }
    const shopId = this.shopIdMap.get(shopName) || 0
    if (shopId > 0) {
      this.sheetShopDrinks = await this.shopDrinkDao.queryByShopId(shopId)
    } else {
      this.sheetShopDrinks = []
    }
  }

  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;

  build() {
    Column() {
      Row() {
        Text("欢迎")
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 20 })
      }
      .width("100%")
      .height(50)
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 15 }) {
          TodayStatsCard({
            todayCups: this.todayCups,
            todayCaffeine: this.todayCaffeine,
            todaySugar: this.todaySugar
          })

          ShopRankCard({
            shops: this.shops,
            onShopClick: (shop: string): void => {
              this.onShopSelected(shop)
            },
            onShareClick: (): void => {
              this.shareRankImage()
            }
          })

          // 日历卡片
          Column() {
            Row() {
              Text('<')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .width(40).height(40).textAlign(TextAlign.Center)
                .onClick(() => this.prevMonth())

              Text(`${this.year}年${this.month}月`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

              Text('>')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .width(40).height(40).textAlign(TextAlign.Center)
                .onClick(() => this.nextMonth())

              Row() {
                SymbolGlyph($r('sys.symbol.share'))
                  .fontSize(16)
                  .fontColor([$r('app.color.symbol_primary')])
              }
              .padding(8)
              .margin({ left: 4 })
              .onClick(() => {
                this.shareCalendarImage()
              })
            }
            .width('100%')
            .padding({ left: 4, right: 4, top: 16, bottom: 12 })

            Row() {
              ForEach(this.weekDays, (day: string) => {
                Text(day)
                  .width('14.28%')
                  .textAlign(TextAlign.Center)
                  .fontSize(13)
                  .fontColor($r('app.color.text_primary'))
                  .fontWeight(FontWeight.Medium)
                  .padding({ top: 8, bottom: 8 })
              })
            }
            .width('100%')
            .borderRadius(8)

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.buildCalendarData(), (day: number | null) => {
                Column() {
                  Text(day !== null ? day.toString() : '')
                    .fontSize(15)
                    .fontColor(day !== null ? $r('app.color.text_primary') : Color.Transparent)
                    .height(24)
                    .padding({ top: 6, bottom: 6 })
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .backgroundColor(day !== null && this.isToday(day) ? '#A5D6A7' : Color.Transparent)
                    .borderRadius(8)
                  if (day !== null && this.isCompleted(day)) {
                    Row()
                      .width(6).height(6)
                      .backgroundColor('#4CAF50')
                      .borderRadius(3)
                      .margin({ top: 2 })
                  }
                }
                .width('14.28%')
                .height(56)
                .justifyContent(FlexAlign.Center)
              })
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          }
          .width('94%')
          .backgroundColor($r('app.color.background_card'))
          .borderRadius(16)
          .shadow({ radius: 20, color: $r('app.color.shadow_color'), offsetY: 8 })
          .padding(12)
          .margin({ left: '3%', right: '3%', top: 15 })
          .id('calendarShareCard')

          RecentRecordsCard({
            recentRecords: this.recentRecords,
            onDelete: async (id: number): Promise<void> => {
              await this.deleteRecord(id)
            },
            onFormatTime: (timestamp: number): string => this.formatTime(timestamp)
          })
        }
        .width('100%')
        .backgroundColor($r('app.color.background_primary'))
        .padding({ bottom: 80 })
      }
      .scrollBarColor(Color.Transparent)
      .edgeEffect(EdgeEffect.None)
      .layoutWeight(1)

      // 添加按钮（添加咖啡消费记录）
      Column() {
        Text("+")
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(56)
      .height(56)
      .backgroundColor($r('app.color.chart_concentration_normal'))
      .borderRadius(28)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .position({ left: 20, bottom: 80 })
      .zIndex(100)
      .onClick(() => {
        this.openAddSheet()
      })

      // 截图容器 - 使用条件渲染和位置偏移
      if (this.captureReady) {
        RankShareCard({
          shopData: this.shareShopData,
          onClose: (): void => {
            this.captureReady = false
          }
        })
          .id('rankShareCard')
          .position({ left: -2000, top: -1000 })
      }
    }
    .width('100%')
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),
      bottom: this.getUIContext().px2vp(this.bottomRectHeight)
    })
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
    .bindSheet(this.isSheetShow, this.sheetBuilder, {
      height: this.sheetType === 'add' ? '60%' : '50%',
      showClose: false,
      preferType: SheetType.BOTTOM
    })
  }

  // 弹窗构建器 - 组件内的@Builder方法
  @Builder
  sheetBuilder() {
    if (this.sheetType === 'add') {
      TianjiaSheet({
        shops: $sheetShops,
        shopDrinks: $sheetShopDrinks,
        selectedShop: $sheetSelectedShop,
        selectedDrink: $sheetSelectedDrink,
        selectedSugar: $sheetSelectedSugar,
        onClose: (): void => {
          this.closeSheet()
        },
        onConfirm: async (): Promise<void> => {
          await this.confirmAdd()
        },
        onShopChanged: (shop: string): void => {
          this.onSheetShopChanged(shop)
        }
      })
    } else if (this.sheetType === 'shareRank') {
      RankShareCard({
        shopData: this.shareShopData,
        onClose: (): void => {
          this.closeSheet()
        }
      })
    }
  }
}
