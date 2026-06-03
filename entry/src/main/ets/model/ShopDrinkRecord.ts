/**
 * 店铺饮品记录数据模型
 */
export interface ShopDrinkRecord {
  id: number        // 主键
  shopId: number    // 店铺ID
  drinkName: string // 饮品名称
  caffeine: number  // 咖啡因含量
  cost: number      // 价格
  sugar: number     // 糖度
  createTime: number // 创建时间
}
