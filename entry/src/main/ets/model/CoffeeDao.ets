import { relationalStore } from '@kit.ArkData';
import { CoffeeRecord } from './CoffeeRecord';
import { CoffeeDatabase } from './CoffeeDatabase';

/**
 * 咖啡记录数据访问对象
 *
 * 云同步已集成：只需在 StoreConfig 中设置 cloudSync: true，
 * 系统会自动完成数据同步，无需手动调用同步接口。
 */
export class CoffeeDao {
  private tableName: string = '';

  constructor() {
    this.tableName = CoffeeDatabase.getTableName();
  }

  // 获取 rdbStore，每次操作时重新获取
  private getRdbStore(): relationalStore.RdbStore | null {
    return CoffeeDatabase.getRdbStore();
  }

  /**
   * 新增记录
   */
  async insert(record: CoffeeRecord): Promise<number> {
    const rdbStore = this.getRdbStore()
    if (!rdbStore) {
      console.error('CoffeeDao insert: rdbStore is null')
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      shopName: record.shopName,
      drinkName: record.drinkName,
      caffeine: record.caffeine,
      cost: record.cost,
      sugar: record.sugar,
      createTime: record.createTime
    };

    try {
      const rowId = await rdbStore.insert(this.tableName, valueBucket);
      // 数据会自动同步到云端（通过 relationalStore 的 cloudSync 配置）
      console.info(`CoffeeDao: 新增记录，行ID=${rowId}，数据将自动同步到云端`);
      return rowId;
    } catch (err) {
      console.error('CoffeeDao insert error: ' + JSON.stringify(err));
      return -1;
    }
  }

  /**
   * 删除记录
   */
  async delete(id: number): Promise<boolean> {
    const rdbStore = this.getRdbStore()
    if (!rdbStore) {
      return false;
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', id);

    try {
      const rows = await rdbStore.delete(predicates);
      // 删除操作会自动同步到云端
      if (rows > 0) {
        console.info(`CoffeeDao: 删除记录ID=${id}，删除操作将自动同步到云端`);
      }
      return rows > 0;
    } catch (err) {
      console.error('CoffeeDao delete error: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 更新记录
   */
  async update(record: CoffeeRecord): Promise<boolean> {
    const rdbStore = this.getRdbStore()
    if (!rdbStore) {
      return false;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      shopName: record.shopName,
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
      // 更新操作会自动同步到云端
      if (rows > 0) {
        console.info(`CoffeeDao: 更新记录ID=${record.id}，更新将自动同步到云端`);
      }
      return rows > 0;
    } catch (err) {
      console.error('CoffeeDao update error: ' + JSON.stringify(err));
      return false;
    }
  }

  /**
   * 查询单条记录
   */
  async queryById(id: number): Promise<CoffeeRecord | null> {
    const rdbStore = this.getRdbStore()
    if (!rdbStore) {
      return null;
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('id', id);

    try {
      const resultSet = await rdbStore.query(predicates);
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        return this.parseRecord(resultSet);
      }
      return null;
    } catch (err) {
      console.error('CoffeeDao queryById error: ' + JSON.stringify(err));
      return null;
    }
  }

  /**
   * 查询所有记录
   */
  async queryAll(): Promise<CoffeeRecord[]> {
    const rdbStore = this.getRdbStore()
    if (!rdbStore) {
      console.warn('CoffeeDao queryAll: rdbStore is null')
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    // 按时间倒序
    predicates.orderByDesc('createTime');

    try {
      const resultSet = await rdbStore.query(predicates);
      const records: CoffeeRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(this.parseRecord(resultSet));
      }
      return records;
    } catch (err) {
      console.error('CoffeeDao queryAll error: ' + JSON.stringify(err));
      return [];
    }
  }

  /**
   * 按时间范围查询
   */
  async queryByTimeRange(startTime: number, endTime: number): Promise<CoffeeRecord[]> {
    const rdbStore = this.getRdbStore()
    if (!rdbStore) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.between('createTime', startTime, endTime);
    predicates.orderByDesc('createTime');

    try {
      const resultSet = await rdbStore.query(predicates);
      const records: CoffeeRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push(this.parseRecord(resultSet));
      }
      return records;
    } catch (err) {
      console.error('CoffeeDao queryByTimeRange error: ' + JSON.stringify(err));
      return [];
    }
  }

  /**
   * 解析记录
   */
  private parseRecord(resultSet: relationalStore.ResultSet): CoffeeRecord {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      shopName: resultSet.getString(resultSet.getColumnIndex('shopName')),
      drinkName: resultSet.getString(resultSet.getColumnIndex('drinkName')),
      caffeine: resultSet.getLong(resultSet.getColumnIndex('caffeine')),
      cost: resultSet.getDouble(resultSet.getColumnIndex('cost')),
      sugar: resultSet.getLong(resultSet.getColumnIndex('sugar')),
      createTime: resultSet.getLong(resultSet.getColumnIndex('createTime'))
    };
  }

  /**
   * 按店铺名称查询记录数量（用于排序）
   */
  async countByShop(shopName: string): Promise<number> {
    const rdbStore = this.getRdbStore()
    if (!rdbStore) {
      return 0;
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('shopName', shopName);

    try {
      const resultSet = await rdbStore.query(predicates);
      const count = resultSet.rowCount;
      resultSet.close();
      return count;
    } catch (err) {
      console.error('CoffeeDao countByShop error: ' + JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 获取所有店铺消费次数统计
   * @returns 店铺名称和消费次数的映射
   */
  async getShopCounts(): Promise<Map<string, number>> {
    const records = await this.queryAll();
    const counts = new Map<string, number>();
    for (const record of records) {
      const current = counts.get(record.shopName) || 0;
      counts.set(record.shopName, current + 1);
    }
    return counts;
  }
}
