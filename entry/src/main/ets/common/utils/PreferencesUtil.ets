import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'PreferencesUtil';
const DOMAIN_NUMBER: number = 0x0000;
const MY_STORE: string = 'widgetStore';
const WIDGET_DATA_PREFIX: string = 'widget_data_';

// 全局context，用于静态方法
let globalContext: Context | null = null;

// 初始化全局context（需要在应用启动时调用）
export function initPreferencesContext(context: Context): void {
  globalContext = context;
}

export class PreferencesUtil {
  private static preferencesUtil: PreferencesUtil;

  public static getInstance(): PreferencesUtil {
    if (!PreferencesUtil.preferencesUtil) {
      PreferencesUtil.preferencesUtil = new PreferencesUtil();
    }
    return PreferencesUtil.preferencesUtil;
  }

  getPreferences(context: Context): preferences.Preferences | undefined {
    try {
      // 清除缓存，确保获取最新数据
      preferences.removePreferencesFromCacheSync(context, MY_STORE);
      return preferences.getPreferencesSync(context, { name: MY_STORE });
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `getPreferences failed, error code=${err.code}, message=${err.message}`);
      return undefined;
    }
  }

  preferencesFlush(preferences: preferences.Preferences) {
    preferences.flush((err) => {
      if (err) {
        hilog.error(0x0000, TAG, `Failed to flush. Code:${err.code}, message:${err.message}`);
      }
    })
  }

  preferencesPut(preferences: preferences.Preferences, key: string, value: preferences.ValueType): void {
    try {
      preferences.putSync(key, value);
      this.preferencesFlush(preferences);
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `preferencesPut failed, error code=${err.code}, message=${err.message}`);
    }
  }

  // 获取周数据卡片的所有 formId
  getWeekFormIds(preferences: preferences.Preferences): Array<string> {
    if (preferences === null) {
      hilog.error(0x0000, TAG, `preferences is null`);
      return [];
    }
    try {
      const result = preferences.getSync('weekFormIdList', []);
      return (result as Array<string>) || [];
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `getSync failed, error code=${err.code}, message=${err.message}`);
      return [];
    }
  }

  // 添加周数据卡片的 formId
  addWeekFormId(preferences: preferences.Preferences, formId: string): void {
    try {
      let formIds = this.getWeekFormIds(preferences);
      if (formIds.indexOf(formId) === -1) {
        formIds.push(formId);
        this.preferencesPut(preferences, 'weekFormIdList', formIds);
        hilog.info(0x0000, TAG, `addWeekFormId success: ${formId}, total: ${formIds.length}`);
      }
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `addWeekFormId failed, error code=${err.code}, message=${err.message}`);
    }
  }

  // 删除周数据卡片的 formId
  removeWeekFormId(preferences: preferences.Preferences, formId: string): void {
    try {
      let formIds = this.getWeekFormIds(preferences);
      const index = formIds.indexOf(formId);
      if (index !== -1) {
        formIds.splice(index, 1);
        this.preferencesPut(preferences, 'weekFormIdList', formIds);
        hilog.info(0x0000, TAG, `removeWeekFormId success: ${formId}, remaining: ${formIds.length}`);
      }
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `removeWeekFormId failed, error code=${err.code}, message=${err.message}`);
    }
  }

  // 获取月数据卡片的所有 formId
  getMonthFormIds(preferences: preferences.Preferences): Array<string> {
    if (preferences === null) {
      hilog.error(0x0000, TAG, `preferences is null`);
      return [];
    }
    try {
      const result = preferences.getSync('monthFormIdList', []);
      return (result as Array<string>) || [];
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `getSync failed, error code=${err.code}, message=${err.message}`);
      return [];
    }
  }

  // 添加月数据卡片的 formId
  addMonthFormId(preferences: preferences.Preferences, formId: string): void {
    try {
      let formIds = this.getMonthFormIds(preferences);
      if (formIds.indexOf(formId) === -1) {
        formIds.push(formId);
        this.preferencesPut(preferences, 'monthFormIdList', formIds);
        hilog.info(0x0000, TAG, `addMonthFormId success: ${formId}, total: ${formIds.length}`);
      }
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `addMonthFormId failed, error code=${err.code}, message=${err.message}`);
    }
  }

  // 删除月数据卡片的 formId
  removeMonthFormId(preferences: preferences.Preferences, formId: string): void {
    try {
      let formIds = this.getMonthFormIds(preferences);
      const index = formIds.indexOf(formId);
      if (index !== -1) {
        formIds.splice(index, 1);
        this.preferencesPut(preferences, 'monthFormIdList', formIds);
        hilog.info(0x0000, TAG, `removeMonthFormId success: ${formId}, remaining: ${formIds.length}`);
      }
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `removeMonthFormId failed, error code=${err.code}, message=${err.message}`);
    }
  }

  // 保存卡片数据到Preferences（供卡片进程读取）
  saveWidgetData(preferences: preferences.Preferences, formId: string, data: Record<string, string>): void {
    try {
      const key = WIDGET_DATA_PREFIX + formId;
      const jsonData = JSON.stringify(data);
      this.preferencesPut(preferences, key, jsonData);
      hilog.info(0x0000, TAG, `[PreferencesUtil] saveWidgetData for formId: ${formId}`);
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `saveWidgetData failed, error code=${err.code}, message=${err.message}`);
    }
  }

  // 静态方法：异步获取周数据卡片的所有formId
  static async getWeekFormIds(): Promise<string[]> {
    hilog.info(0x0000, TAG, `[PreferencesUtil] getWeekFormIds: 开始获取`);
    if (!globalContext) {
      hilog.error(0x0000, TAG, `[PreferencesUtil] getWeekFormIds: globalContext is null`);
      return [];
    }
    try {
      // 重要：先清除缓存，确保获取最新数据
      hilog.info(0x0000, TAG, `[PreferencesUtil] getWeekFormIds: 清除缓存`);
      preferences.removePreferencesFromCacheSync(globalContext, MY_STORE);
      const prefs = await preferences.getPreferences(globalContext, MY_STORE);
      hilog.info(0x0000, TAG, `[PreferencesUtil] getWeekFormIds: 获取到prefs`);
      const result = prefs.getSync('weekFormIdList', []);
      hilog.info(0x0000, TAG, `[PreferencesUtil] getWeekFormIds: result=${JSON.stringify(result)}`);
      return (result as string[]) || [];
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `[PreferencesUtil] getWeekFormIds failed: ${err.code}, ${err.message}`);
      return [];
    }
  }

  // 静态方法：异步获取月数据卡片的所有formId
  static async getMonthFormIds(): Promise<string[]> {
    hilog.info(0x0000, TAG, `[PreferencesUtil] getMonthFormIds: 开始获取`);
    if (!globalContext) {
      hilog.error(0x0000, TAG, `[PreferencesUtil] getMonthFormIds: globalContext is null`);
      return [];
    }
    try {
      // 重要：先清除缓存，确保获取最新数据
      hilog.info(0x0000, TAG, `[PreferencesUtil] getMonthFormIds: 清除缓存`);
      preferences.removePreferencesFromCacheSync(globalContext, MY_STORE);
      const prefs = await preferences.getPreferences(globalContext, MY_STORE);
      hilog.info(0x0000, TAG, `[PreferencesUtil] getMonthFormIds: 获取到prefs`);
      const result = prefs.getSync('monthFormIdList', []);
      hilog.info(0x0000, TAG, `[PreferencesUtil] getMonthFormIds: result=${JSON.stringify(result)}`);
      return (result as string[]) || [];
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, TAG, `[PreferencesUtil] getMonthFormIds failed: ${err.code}, ${err.message}`);
      return [];
    }
  }
}
