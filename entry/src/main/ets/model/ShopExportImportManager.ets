/**
 * 店铺数据导出/导入管理器
 * 用于分享店铺和饮品数据
 */
import { CoffeeDatabase } from './CoffeeDatabase';
import { ShopRecord } from './ShopRecord';
import { ShopDrinkRecord } from './ShopDrinkRecord';
import { ShopDao } from './ShopDao';
import { ShopDrinkDao } from './ShopDrinkDao';

/**
 * 店铺分享数据格式
 */
export interface ShopShareData {
  version: number;           // 数据版本号
  exportedAt: number;        // 导出时间
  shops: ShopShareItem[];    // 店铺列表
}

export interface ShopShareItem {
  shopName: string;          // 店铺名称
  createTime: number;        // 创建时间
  drinks: DrinkShareItem[];  // 饮品列表
}

export interface DrinkShareItem {
  drinkName: string;         // 饮品名称
  caffeine: number;          // 咖啡因含量
  cost: number;              // 价格
  sugar: number;             // 糖度
  createTime: number;        // 创建时间
}

/**
 * 导入预览信息
 */
export interface ImportPreview {
  shopCount: number;
  drinkCount: number;
  shopNames: string[];
  exportedAt: string;
}

/**
 * 导入选项
 */
export interface ImportOptions {
  skipExisting: boolean;
  mergeDrinks: boolean;
}

export class ShopExportImportManager {
  private shopDao: ShopDao = new ShopDao();
  private shopDrinkDao: ShopDrinkDao = new ShopDrinkDao();

  /**
   * 导出所有店铺和饮品数据为JSON字符串
   */
  async exportToJson(): Promise<string> {
    const shops = await this.shopDao.queryAll();
    const shareData: ShopShareData = {
      version: 1,
      exportedAt: Date.now(),
      shops: []
    };

    for (let i = 0; i < shops.length; i++) {
      const shop = shops[i];
      const drinks = await this.shopDrinkDao.queryByShopId(shop.id);
      const drinkItems: DrinkShareItem[] = [];
      for (let j = 0; j < drinks.length; j++) {
        const drink = drinks[j];
        drinkItems.push({
          drinkName: drink.drinkName,
          caffeine: drink.caffeine,
          cost: drink.cost,
          sugar: drink.sugar,
          createTime: drink.createTime
        });
      }
      shareData.shops.push({
        shopName: shop.shopName,
        createTime: shop.createTime,
        drinks: drinkItems
      });
    }

    return JSON.stringify(shareData);
  }

  /**
   * 导出指定店铺和饮品数据为JSON字符串
   */
  async exportShopsToJson(shopIds: number[]): Promise<string> {
    const shareData: ShopShareData = {
      version: 1,
      exportedAt: Date.now(),
      shops: []
    };

    for (let i = 0; i < shopIds.length; i++) {
      const shopId = shopIds[i];
      const shop = await this.queryShopById(shopId);
      if (shop) {
        const drinks = await this.shopDrinkDao.queryByShopId(shopId);
        const drinkItems: DrinkShareItem[] = [];
        for (let j = 0; j < drinks.length; j++) {
          const drink = drinks[j];
          drinkItems.push({
            drinkName: drink.drinkName,
            caffeine: drink.caffeine,
            cost: drink.cost,
            sugar: drink.sugar,
            createTime: drink.createTime
          });
        }
        shareData.shops.push({
          shopName: shop.shopName,
          createTime: shop.createTime,
          drinks: drinkItems
        });
      }
    }

    return JSON.stringify(shareData);
  }

  /**
   * 根据ID查询店铺
   */
  private async queryShopById(id: number): Promise<ShopRecord | null> {
    const shops = await this.shopDao.queryAll();
    for (let i = 0; i < shops.length; i++) {
      if (shops[i].id === id) {
        return shops[i];
      }
    }
    return null;
  }

  /**
   * 导入店铺和饮品数据
   * @param jsonData JSON字符串
   * @param options 导入选项
   * @returns 导入的店铺数量
   */
  async importFromJson(jsonData: string, options?: ImportOptions): Promise<number> {
    const opts: ImportOptions = {
      skipExisting: options?.skipExisting ?? false,
      mergeDrinks: options?.mergeDrinks ?? true
    };

    let shareData: ShopShareData | null = null;
    try {
      shareData = JSON.parse(jsonData) as ShopShareData;
    } catch {
      console.error('[ShopExportImport] Invalid JSON format');
      return 0;
    }

    // 验证数据格式
    if (!this.validateShareData(shareData)) {
      console.error('[ShopExportImport] Invalid share data format');
      return 0;
    }

    let importedCount = 0;

    for (let i = 0; i < shareData.shops.length; i++) {
      const shopItem = shareData.shops[i];
      // 检查店铺是否已存在
      const existingShop = await this.shopDao.queryByName(shopItem.shopName);

      if (existingShop && opts.skipExisting) {
        console.info(`[ShopExportImport] Skip existing shop: ${shopItem.shopName}`);
        continue;
      }

      if (existingShop && opts.mergeDrinks) {
        // 合并饮品到已存在的店铺
        for (let j = 0; j < shopItem.drinks.length; j++) {
          const drink = shopItem.drinks[j];
          await this.addDrinkToShop(existingShop.id, drink);
        }
        console.info(`[ShopExportImport] Merged drinks for existing shop: ${shopItem.shopName}`);
      } else if (existingShop) {
        // 跳过已存在的店铺（不合并）
        console.info(`[ShopExportImport] Skip existing shop (no merge): ${shopItem.shopName}`);
        continue;
      } else {
        // 创建新店铺
        const newShop: ShopRecord = {
          id: 0,
          shopName: shopItem.shopName,
          createTime: shopItem.createTime || Date.now()
        };

        const shopId = await this.shopDao.insert(newShop);
        if (shopId > 0) {
          // 添加饮品
          for (let j = 0; j < shopItem.drinks.length; j++) {
            const drink = shopItem.drinks[j];
            await this.addDrinkToShop(shopId, drink);
          }
          importedCount++;
          console.info(`[ShopExportImport] Imported new shop: ${shopItem.shopName}`);
        }
      }
    }

    // 刷新首页店铺列表
    AppStorage.setOrCreate('needRefreshShops', Date.now());

    return importedCount;
  }

  /**
   * 验证分享数据格式
   */
  private validateShareData(data: ShopShareData): boolean {
    if (!data || typeof data !== 'object') return false;
    if (!Array.isArray(data.shops)) return false;
    if (data.version !== 1) return false;

    for (let i = 0; i < data.shops.length; i++) {
      const shop = data.shops[i];
      if (!shop.shopName || typeof shop.shopName !== 'string') return false;
      if (!Array.isArray(shop.drinks)) return false;
    }

    return true;
  }

  /**
   * 添加饮品到店铺
   */
  private async addDrinkToShop(shopId: number, drink: DrinkShareItem): Promise<void> {
    const drinkRecord: ShopDrinkRecord = {
      id: 0,
      shopId: shopId,
      drinkName: drink.drinkName,
      caffeine: drink.caffeine,
      cost: drink.cost,
      sugar: drink.sugar,
      createTime: drink.createTime || Date.now()
    };

    await this.shopDrinkDao.insert(drinkRecord);
  }

  /**
   * 获取分享文件预览信息
   */
  async getSharePreview(jsonData: string): Promise<ImportPreview | null> {
    let shareData: ShopShareData | null = null;
    try {
      shareData = JSON.parse(jsonData) as ShopShareData;
    } catch {
      console.error('[ShopExportImport] getSharePreview: Invalid JSON');
      return null;
    }

    if (!this.validateShareData(shareData)) {
      return null;
    }

    const shopNames: string[] = [];
    let drinkCount = 0;

    for (let i = 0; i < shareData.shops.length; i++) {
      shopNames.push(shareData.shops[i].shopName);
      drinkCount += shareData.shops[i].drinks.length;
    }

    const exportedAt = new Date(shareData.exportedAt).toLocaleString();

    return {
      shopCount: shareData.shops.length,
      drinkCount: drinkCount,
      shopNames: shopNames,
      exportedAt: exportedAt
    };
  }
}
