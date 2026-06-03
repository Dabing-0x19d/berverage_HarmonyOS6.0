import { relationalStore } from '@kit.ArkData';
import { ShopRecord } from './ShopRecord';
import { CoffeeDatabase } from './CoffeeDatabase';
import { ShopDrinkRecord } from './ShopDrinkRecord';
import { ShopDrinkDao } from './ShopDrinkDao';

/**
 * 店铺数据访问对象
 */
export class ShopDao {
  private tableName: string = 'shops';

  constructor() {
  }

  /**
   * 获取表名
   */
  getTableName(): string {
    return this.tableName;
  }

  /**
   * 获取 rdbStore
   */
  private getRdbStore(): relationalStore.RdbStore | null {
    return CoffeeDatabase.getRdbStore();
  }

  /**
   * 新增店铺
   */
  async insert(shop: ShopRecord): Promise<number> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      console.error('ShopDao insert: rdbStore is null');
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      shopName: shop.shopName,
      createTime: shop.createTime
    };

    try {
      const rowId = await rdbStore.insert(this.tableName, valueBucket);
      console.info('[ShopDao] insert success, rowId=' + rowId);
      return rowId;
    } catch (err) {
      console.error('ShopDao insert error: ' + JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 删除店铺
   */
  async delete(id: number): Promise<boolean> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      return false;
    }

    // 先删除该店铺的所有饮品
    const shopDrinkDao = new ShopDrinkDao();
    await shopDrinkDao.deleteByShopId(id);

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', id);

    try {
      const rows = await rdbStore.delete(predicates);
      console.info('[ShopDao] delete id=' + id + ', rows=' + rows);
      return rows > 0;
    } catch (err) {
      console.error('ShopDao delete error: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 查询所有店铺
   */
  async queryAll(): Promise<ShopRecord[]> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      console.warn('ShopDao queryAll: rdbStore is null');
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.orderByDesc('id');

    try {
      const resultSet = await rdbStore.query(predicates);
      const records: ShopRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(this.parseRecord(resultSet));
      }
      resultSet.close();
      console.info('[ShopDao] queryAll returned ' + records.length + ' shops');
      return records;
    } catch (err) {
      console.error('ShopDao queryAll error: ' + JSON.stringify(err));
      return [];
    }
  }

  /**
   * 按店铺名称查询
   */
  async queryByName(shopName: string): Promise<ShopRecord | null> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      return null;
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('shopName', shopName);

    try {
      const resultSet = await rdbStore.query(predicates);
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        const record = this.parseRecord(resultSet);
        resultSet.close();
        return record;
      }
      resultSet.close();
      return null;
    } catch (err) {
      console.error('ShopDao queryByName error: ' + JSON.stringify(err));
      return null;
    }
  }

  /**
   * 检查店铺是否存在
   */
  async exists(shopName: string): Promise<boolean> {
    const record = await this.queryByName(shopName);
    return record !== null;
  }

  /**
   * 初始化默认店铺数据
   */
  async initDefaultShops(): Promise<void> {
    const shopDrinkDao = new ShopDrinkDao();

    // 测试店铺数据：店名、咖啡因(mg)、糖(g)
    const defaultShops = [
      {
        shopName: '瑞幸咖啡',
        drinks: [
          { drinkName: '生椰拿铁', caffeine: 150, cost: 18, sugar: 12 },
          { drinkName: '陨石拿铁', caffeine: 120, cost: 16, sugar: 18 },
          { drinkName: '厚乳拿铁', caffeine: 150, cost: 17, sugar: 10 }
        ]
      },
      {
        shopName: '星巴克',
        drinks: [
          { drinkName: '燕麦拿铁', caffeine: 150, cost: 28, sugar: 8 },
          { drinkName: '馥芮白', caffeine: 180, cost: 32, sugar: 6 },
          { drinkName: '美式咖啡', caffeine: 200, cost: 25, sugar: 0 }
        ]
      },
      {
        shopName: '库迪咖啡',
        drinks: [
          { drinkName: '潘帕斯蓝生酪', caffeine: 140, cost: 13, sugar: 15 },
          { drinkName: '马蹄生椰拿铁', caffeine: 130, cost: 12, sugar: 10 },
          { drinkName: '生椰Dirty', caffeine: 160, cost: 14, sugar: 8 }
        ]
      },
      {
        shopName: '蜜雪冰城',
        drinks: [
          { drinkName: '雪王咖啡', caffeine: 100, cost: 6, sugar: 10 },
          { drinkName: '芝士奶盖咖啡', caffeine: 110, cost: 8, sugar: 12 }
        ]
      },
      {
        shopName: '奈雪的茶',
        drinks: [
          { drinkName: '霸气桂圆玫瑰', caffeine: 0, cost: 22, sugar: 15 },
          { drinkName: '茉莉初雪', caffeine: 80, cost: 18, sugar: 8 }
        ]
      },
      {
        shopName: '沪上阿姨',
        drinks: [
          { drinkName: '手打葡萄柠檬', caffeine: 0, cost: 16, sugar: 18 },
          { drinkName: '厚布丁奶茶', caffeine: 50, cost: 14, sugar: 20 }
        ]
      }
    ];

    for (const shop of defaultShops) {
      const exists = await this.exists(shop.shopName);
      if (!exists) {
        const shopRecord: ShopRecord = {
          id: 0,
          shopName: shop.shopName,
          createTime: Date.now()
        };
        const shopId = await this.insert(shopRecord);
        console.info('[ShopDao] 添加店铺: ' + shop.shopName);

        // 为店铺添加饮品
        if (shopId > 0) {
          for (const drink of shop.drinks) {
            const drinkRecord: ShopDrinkRecord = {
              id: 0,
              shopId: shopId,
              drinkName: drink.drinkName,
              caffeine: drink.caffeine,
              cost: drink.cost,
              sugar: drink.sugar,
              createTime: Date.now()
            };
            await shopDrinkDao.insert(drinkRecord);
          }
          console.info('[ShopDao] ' + shop.shopName + ' 添加了 ' + shop.drinks.length + ' 款饮品');
        }
      }
    }
    console.info('[ShopDao] initDefaultShops completed');
  }

  /**
   * 解析记录
   */
  private parseRecord(resultSet: relationalStore.ResultSet): ShopRecord {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      shopName: resultSet.getString(resultSet.getColumnIndex('shopName')),
      createTime: resultSet.getLong(resultSet.getColumnIndex('createTime'))
    };
  }
}
