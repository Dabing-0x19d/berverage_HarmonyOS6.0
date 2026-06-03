import { relationalStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { ShopDao } from './ShopDao';

const DB_NAME: string = 'CoffeeDatabase.db';
const TABLE_NAME: string = 'coffee_records';
const SHOPS_TABLE_NAME: string = 'shops';
const SHOP_DRINKS_TABLE_NAME: string = 'shop_drinks';
const PREFERENCES_NAME: string = 'coffee_app_prefs';
const KEY_DEFAULT_SHOPS_INIT: string = 'default_shops_initialized';

/**
 * 咖啡数据库初始化
 */
export class CoffeeDatabase {
  private static rdbStore: relationalStore.RdbStore | null = null;
  private static initPromise: Promise<void> | null = null;

  /**
   * 初始化数据库
   */
  static async init(context: Context): Promise<void> {
    if (this.initPromise) {
      return this.initPromise;
    }

    if (this.rdbStore) {
      return Promise.resolve();
    }

    this.initPromise = (async () => {
      const config: relationalStore.StoreConfig = {
        name: DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };

      try {
        this.rdbStore = await relationalStore.getRdbStore(context, config);
        await this.migrateIfNeeded(context);
        console.info('CoffeeDatabase init success');
      } catch (err) {
        console.error('CoffeeDatabase init error: ' + JSON.stringify(err));
        this.initPromise = null;
        throw err;
      }
    })();

    return this.initPromise;
  }

  /**
   * 数据库迁移
   */
  private static async migrateIfNeeded(context: Context): Promise<void> {
    if (!this.rdbStore) {
      return;
    }

    try {
      // 创建咖啡记录表
      await this.createTable();
      console.info('CoffeeDatabase: coffee_records table created');

      // 检查表是否已有 sugar 列
      const columns = await this.getTableColumns(this.rdbStore, TABLE_NAME);
      if (!columns.includes('sugar')) {
        await this.rdbStore.executeSql(`ALTER TABLE ${TABLE_NAME} ADD COLUMN sugar INTEGER NOT NULL DEFAULT 0`);
        console.info('CoffeeDatabase: sugar column added');
      }

      // 创建店铺表
      await this.createShopsTable();
      console.info('CoffeeDatabase: shops table created');

      // 创建店铺饮品表
      await this.createShopDrinksTable();
      console.info('CoffeeDatabase: shop_drinks table created');

      // 初始化默认店铺数据
      const alreadyInitialized = await this.isDefaultShopsInitialized(context);
      if (!alreadyInitialized) {
        const shopDao = new ShopDao();
        await shopDao.initDefaultShops();
        await this.setDefaultShopsInitialized(context);
        console.info('CoffeeDatabase: default shops initialized');
      }
    } catch (err) {
      console.error('CoffeeDatabase migration error: ' + JSON.stringify(err));
    }
  }

  private static async createShopsTable(): Promise<void> {
    if (!this.rdbStore) return;
    const sql = `CREATE TABLE IF NOT EXISTS ${SHOPS_TABLE_NAME} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shopName TEXT NOT NULL,
      createTime INTEGER NOT NULL
    )`;
    try {
      await this.rdbStore.executeSql(sql);
    } catch (err) {
      console.error('createShopsTable error: ' + JSON.stringify(err));
    }
  }

  private static async createTable(): Promise<void> {
    if (!this.rdbStore) return;
    const sql = `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shopName TEXT NOT NULL,
      drinkName TEXT NOT NULL,
      caffeine INTEGER NOT NULL,
      cost REAL NOT NULL,
      sugar INTEGER NOT NULL DEFAULT 0,
      createTime INTEGER NOT NULL
    )`;
    try {
      await this.rdbStore.executeSql(sql);
    } catch (err) {
      console.error('createTable error: ' + JSON.stringify(err));
    }
  }

  private static async createShopDrinksTable(): Promise<void> {
    if (!this.rdbStore) return;
    const sql = `CREATE TABLE IF NOT EXISTS ${SHOP_DRINKS_TABLE_NAME} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shopId INTEGER NOT NULL,
      drinkName TEXT NOT NULL,
      caffeine INTEGER NOT NULL,
      cost REAL NOT NULL,
      sugar INTEGER NOT NULL DEFAULT 0,
      createTime INTEGER NOT NULL
    )`;
    try {
      await this.rdbStore.executeSql(sql);
    } catch (err) {
      console.error('createShopDrinksTable error: ' + JSON.stringify(err));
    }
  }

  static getRdbStore(): relationalStore.RdbStore | null {
    return this.rdbStore;
  }

  static getTableName(): string {
    return TABLE_NAME;
  }

  static getShopsTableName(): string {
    return SHOPS_TABLE_NAME;
  }

  static getShopDrinksTableName(): string {
    return SHOP_DRINKS_TABLE_NAME;
  }

  private static async getTableColumns(rdbStore: relationalStore.RdbStore, tableName: string): Promise<string[]> {
    const columns: string[] = [];
    const resultSet = await rdbStore.querySql(`PRAGMA table_info(${tableName})`);
    while (resultSet.goToNextRow()) {
      columns.push(resultSet.getString(resultSet.getColumnIndex('name')));
    }
    resultSet.close();
    return columns;
  }

  private static async isDefaultShopsInitialized(context: Context): Promise<boolean> {
    try {
      const prefs = await preferences.getPreferences(context, PREFERENCES_NAME);
      return prefs.getSync(KEY_DEFAULT_SHOPS_INIT, false) as boolean;
    } catch {
      return false;
    }
  }

  private static async setDefaultShopsInitialized(context: Context): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, PREFERENCES_NAME);
      prefs.put(KEY_DEFAULT_SHOPS_INIT, true);
      await prefs.flush();
    } catch (err) {
      console.error('setDefaultShopsInitialized error: ' + JSON.stringify(err));
    }
  }
}
