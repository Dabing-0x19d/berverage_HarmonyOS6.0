/**
 * 咖啡记录数据模型
 */
export interface CoffeeRecord {
  id: number           // 主键
  shopName: string     // 咖啡店名称
  drinkName: string    // 饮品名称
  caffeine: number     // 咖啡因含量(mg)
  cost: number         // 花费(元)
  sugar: number        // 糖含量(g)
  createTime: number   // 创建时间(时间戳)
}
