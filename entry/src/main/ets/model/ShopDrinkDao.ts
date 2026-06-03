/**
 * 店铺饮品数据访问对象
 */
import { relationalStore } from '@kit.ArkData';
import { CoffeeDatabase } from './CoffeeDatabase';
import { ShopDrinkRecord } from './ShopDrinkRecord';

export class ShopDrinkDao {
  private tableName: string = '';

  constructor() {
    this.tableName = 'shop_drinks';
  }

  private getRdbStore(): relationalStore.RdbStore | null {
    return CoffeeDatabase.getRdbStore();
  }

  /**
   * 创建店铺饮品表
   */
  async createTable(): Promise<void> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      return;
    }

    const sql = `
      CREATE TABLE IF NOT EXISTS ${this.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopId INTEGER NOT NULL,
        drinkName TEXT NOT NULL,
        caffeine INTEGER NOT NULL,
        cost REAL NOT NULL,
        sugar INTEGER NOT NULL DEFAULT 0,
        createTime INTEGER NOT NULL,
        FOREIGN KEY(shopId) REFERENCES shops(id) ON DELETE CASCADE
      )
    `;

    try {
      await rdbStore.executeSql(sql);
      console.info('ShopDrinkDao: table created');
    } catch (err) {
      console.error('ShopDrinkDao createTable error: ' + JSON.stringify(err));
    }
  }

  /**
   * 获取表名
   */
  static getTableName(): string {
    return 'shop_drinks';
  }

  /**
   * 新增饮品
   */
  async insert(record: ShopDrinkRecord): Promise<number> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      shopId: record.shopId,
      drinkName: record.drinkName,
      caffeine: record.caffeine,
      cost: record.cost,
      sugar: record.sugar,
      createTime: record.createTime
    };

    try {
      const rowId = await rdbStore.insert(this.tableName, valueBucket);
      return rowId;
    } catch (err) {
      console.error('ShopDrinkDao insert error: ' + JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 删除饮品
   */
  async delete(id: number): Promise<boolean> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      return false;
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', id);

    try {
      const rows = await rdbStore.delete(predicates);
      return rows > 0;
    } catch (err) {
      console.error('ShopDrinkDao delete error: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 按店铺ID删除所有饮品
   */
  async deleteByShopId(shopId: number): Promise<boolean> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      return false;
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('shopId', shopId);

    try {
      const rows = await rdbStore.delete(predicates);
      console.info('[ShopDrinkDao] deleteByShopId shopId=' + shopId + ', rows=' + rows);
      return rows >= 0;
    } catch (err) {
      console.error('ShopDrinkDao deleteByShopId error: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 更新饮品
   */
  async update(record: ShopDrinkRecord): Promise<boolean> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      return false;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      shopId: record.shopId,
      drinkName: record.drinkName,
      caffeine: record.caffeine,
      cost: record.cost,
      sugar: record.sugar,
      createTime: record.createTime
    };

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', record.id);

    try {
      const rows = await rdbStore.update(valueBucket, predicates);
      return rows > 0;
    } catch (err) {
      console.error('ShopDrinkDao update error: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 查询店铺的所有饮品
   */
  async queryByShopId(shopId: number): Promise<ShopDrinkRecord[]> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('shopId', shopId);

    try {
      const resultSet = await rdbStore.query(predicates);
      const records: ShopDrinkRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(this.parseRecord(resultSet));
      }
      return records;
    } catch (err) {
      console.error('ShopDrinkDao queryByShopId error: ' + JSON.stringify(err));
      return [];
    }
  }

  /**
   * 查询所有店铺饮品
   */
  async queryAll(): Promise<ShopDrinkRecord[]> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);

    try {
      const resultSet = await rdbStore.query(predicates);
      const records: ShopDrinkRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(this.parseRecord(resultSet));
      }
      return records;
    } catch (err) {
      console.error('ShopDrinkDao queryAll error: ' + JSON.stringify(err));
      return [];
    }
  }

  /**
   * 根据饮品名称统计消费次数
   */
  async countByDrink(drinkName: string): Promise<number> {
    const rdbStore = this.getRdbStore();
    if (!rdbStore) {
      return 0;
    }

    const tableName = CoffeeDatabase.getTableName();
    const predicates = new relationalStore.RdbPredicates(tableName);
    predicates.equalTo('drinkName', drinkName);

    try {
      const resultSet = await rdbStore.query(predicates);
      const count = resultSet.rowCount;
      resultSet.close();
      return count;
    } catch (err) {
      console.error('ShopDrinkDao countByDrink error: ' + JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 解析记录
   */
  private parseRecord(resultSet: relationalStore.ResultSet): ShopDrinkRecord {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      shopId: resultSet.getLong(resultSet.getColumnIndex('shopId')),
      drinkName: resultSet.getString(resultSet.getColumnIndex('drinkName')),
      caffeine: resultSet.getLong(resultSet.getColumnIndex('caffeine')),
      cost: resultSet.getDouble(resultSet.getColumnIndex('cost')),
      sugar: resultSet.getLong(resultSet.getColumnIndex('sugar')),
      createTime: resultSet.getLong(resultSet.getColumnIndex('createTime'))
    };
  }
}
