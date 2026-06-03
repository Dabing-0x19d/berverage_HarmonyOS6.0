import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { formBindingData, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0x0000;
const PREFERENCES_NAME: string = 'widgetStore';
const WIDGET_DATA_PREFIX: string = 'widget_data_';
const DB_NAME: string = 'CoffeeDatabase.db';

// 异步获取周数据
async function getWeekDataFromDb(context: Context): Promise<Record<string, string>> {
  const resultData: Record<string, string> = {
    'sunday': '0', 'monday': '0', 'tuesday': '0', 'wednesday': '0',
    'thursday': '0', 'friday': '0', 'saturday': '0',
    'total': '0', 'dateRange': ''
  };

  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    });

    const resultSet = await rdbStore.querySql('SELECT * FROM widget_data ORDER BY id DESC LIMIT 1');
    if (resultSet.goToNextRow()) {
      resultData['sunday'] = resultSet.getString(resultSet.getColumnIndex('sunday'));
      resultData['monday'] = resultSet.getString(resultSet.getColumnIndex('monday'));
      resultData['tuesday'] = resultSet.getString(resultSet.getColumnIndex('tuesday'));
      resultData['wednesday'] = resultSet.getString(resultSet.getColumnIndex('wednesday'));
      resultData['thursday'] = resultSet.getString(resultSet.getColumnIndex('thursday'));
      resultData['friday'] = resultSet.getString(resultSet.getColumnIndex('friday'));
      resultData['saturday'] = resultSet.getString(resultSet.getColumnIndex('saturday'));
      resultData['total'] = resultSet.getString(resultSet.getColumnIndex('total'));
      resultData['dateRange'] = resultSet.getString(resultSet.getColumnIndex('dateRange'));
    }
    resultSet.close();
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN_NUMBER, TAG, `getWeekDataFromDb error: ${e.code}, ${e.message}`);
  }

  return resultData;
}

// 异步获取历史店铺前三名数据（与周数据方法结构完全一致）
async function getMonthDataFromDb(context: Context): Promise<Record<string, string>> {
  const resultData: Record<string, string> = {
    'shop1': '', 'count1': '0',
    'shop2': '', 'count2': '0',
    'shop3': '', 'count3': '0'
  };

  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    });

    const resultSet = await rdbStore.querySql('SELECT * FROM history_widget_data ORDER BY id DESC LIMIT 1');
    if (resultSet.goToNextRow()) {
      resultData['shop1'] = resultSet.getString(resultSet.getColumnIndex('shop1'));
      resultData['count1'] = resultSet.getString(resultSet.getColumnIndex('count1'));
      resultData['shop2'] = resultSet.getString(resultSet.getColumnIndex('shop2'));
      resultData['count2'] = resultSet.getString(resultSet.getColumnIndex('count2'));
      resultData['shop3'] = resultSet.getString(resultSet.getColumnIndex('shop3'));
      resultData['count3'] = resultSet.getString(resultSet.getColumnIndex('count3'));
    }
    resultSet.close();
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN_NUMBER, TAG, `getMonthDataFromDb error: ${e.code}, ${e.message}`);
  }

  return resultData;
}

// 异步获取所有卡片数据
async function getAllWidgetData(context: Context): Promise<Record<string, string>> {
  const weekData = await getWeekDataFromDb(context);
  const monthData = await getMonthDataFromDb(context);

  const result: Record<string, string> = {};
  Object.keys(weekData).forEach((key: string) => {
    (result as Record<string, string>)[key] = weekData[key];
  });
  Object.keys(monthData).forEach((key: string) => {
    (result as Record<string, string>)[key] = monthData[key];
  });
  return result;
}

// 从Preferences读取卡片数据
async function getWidgetDataFromPrefs(context: Context, formId: string): Promise<Record<string, string> | null> {
  try {
    const prefs = await preferences.getPreferences(context, PREFERENCES_NAME);
    const key = WIDGET_DATA_PREFIX + formId;
    const jsonData = prefs.getSync(key, '') as string;
    if (jsonData) {
      hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] 从Preferences读取数据 formId=${formId}`);
      return JSON.parse(jsonData) as Record<string, string>;
    }
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN_NUMBER, TAG, `getWidgetDataFromPrefs error: ${e.code}, ${e.message}`);
  }
  return null;
}

// 保存卡片数据到Preferences
async function saveWidgetDataToPrefs(context: Context, formId: string, data: Record<string, string>): Promise<void> {
  try {
    const prefs = await preferences.getPreferences(context, PREFERENCES_NAME);
    const key = WIDGET_DATA_PREFIX + formId;
    const jsonData = JSON.stringify(data);
    prefs.putSync(key, jsonData);
    prefs.flush();
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] 保存数据到Preferences formId=${formId}`);
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN_NUMBER, TAG, `saveWidgetDataToPrefs error: ${e.code}, ${e.message}`);
  }
}

// 保存formId到Preferences
function saveFormIdToPrefs(prefs: preferences.Preferences, key: string, formId: string): void {
  try {
    let formIds: string[] = prefs.getSync(key, []) as string[];
    if (!Array.isArray(formIds)) {
      formIds = [];
    }
    if (formIds.indexOf(formId) === -1) {
      formIds.push(formId);
      prefs.putSync(key, formIds);
      prefs.flush();
    }
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN_NUMBER, TAG, `saveFormIdToPrefs error: ${e.code}, ${e.message}`);
  }
}

// 从Want中获取卡片类型名称
function getWidgetType(want: Want): string {
  const name = want.parameters?.['ohos.extra.param.key.form_name'] as string;
  if (name === 'widget' || name === 'form') {
    const identity = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    if (identity && identity.includes('month')) {
      return 'widget2';
    }
    return 'weekStatsWidget';
  }
  return name || 'weekStatsWidget';
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onAddForm');

    const formName = getWidgetType(want);
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] formName: ${formName}, formId: ${formId}`);

    // 异步保存 formId 到 Preferences
    preferences.getPreferences(this.context, PREFERENCES_NAME).then((prefs: preferences.Preferences) => {
      if (formName === 'weekStatsWidget' || formName === 'widget1') {
        saveFormIdToPrefs(prefs, 'weekFormIdList', formId);
      } else if (formName === 'widget2') {
        saveFormIdToPrefs(prefs, 'monthFormIdList', formId);
      }
    }).catch((e: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `getPreferences error: ${e.code}, ${e.message}`);
    });

    const timestamp = Date.now().toString();

    // 直接从数据库加载数据并更新卡片
    getAllWidgetData(this.context).then((dbData) => {
      dbData['_timestamp'] = timestamp;
      hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onAddForm 从数据库加载数据: ${JSON.stringify(dbData)}`);
      // 保存到Preferences供定时刷新使用
      saveWidgetDataToPrefs(this.context, formId, dbData);
      // 更新卡片
      formProvider.updateForm(formId, formBindingData.createFormBindingData(dbData))
        .then(() => {
          hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onAddForm updateForm success');
        })
        .catch((error: BusinessError) => {
          hilog.error(DOMAIN_NUMBER, TAG, `onAddForm updateForm error: ${error.code}, ${error.message}`);
        });
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `onAddForm error: ${err.code}, ${err.message}`);
    });

    // 返回默认数据（如果数据库查询失败，至少有默认数据）
    const allData: Record<string, string> = {
      'sunday': '0', 'monday': '0', 'tuesday': '0', 'wednesday': '0',
      'thursday': '0', 'friday': '0', 'saturday': '0',
      'total': '0', 'dateRange': '',
      'shop1': '', 'count1': '0',
      'shop2': '', 'count2': '0',
      'shop3': '', 'count3': '0',
      '_timestamp': timestamp
    };

    return formBindingData.createFormBindingData(allData);
  }

  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onUpdateForm formId: ${formId}`);
    // 定时刷新时，尝试从Preferences读取主应用写入的最新数据
    // 如果Preferences中没有数据，则从数据库查询
    getWidgetDataFromPrefs(this.context, formId).then((prefsData) => {
      if (prefsData) {
        prefsData['_timestamp'] = Date.now().toString();
        hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onUpdateForm 使用Preferences数据`);
        formProvider.updateForm(formId, formBindingData.createFormBindingData(prefsData))
          .then(() => {
            hilog.info(DOMAIN_NUMBER, TAG, 'updateForm from prefs success');
          })
          .catch((error: BusinessError) => {
            hilog.error(DOMAIN_NUMBER, TAG, `updateForm error: ${error.code}, ${error.message}`);
          });
      } else {
        hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onUpdateForm Preferences无数据，从数据库查询`);
        getAllWidgetData(this.context).then((allData) => {
          allData['_timestamp'] = Date.now().toString();
          hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onUpdateForm 数据库数据: ${JSON.stringify(allData)}`);
          // 同时保存到Preferences供后续使用
          saveWidgetDataToPrefs(this.context, formId, allData);
          formProvider.updateForm(formId, formBindingData.createFormBindingData(allData))
            .then(() => {
              hilog.info(DOMAIN_NUMBER, TAG, 'updateForm from db success');
            })
            .catch((error: BusinessError) => {
              hilog.error(DOMAIN_NUMBER, TAG, `updateForm error: ${error.code}, ${error.message}`);
            });
        });
      }
    });
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onFormEvent formId: ${formId}, message: ${message}`);
    if (message === 'refresh') {
      getAllWidgetData(this.context).then((allData) => {
        allData['_timestamp'] = Date.now().toString();
        hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onFormEvent 从数据库加载数据`);
        formProvider.updateForm(formId, formBindingData.createFormBindingData(allData))
          .catch((error: BusinessError) => {
            hilog.error(DOMAIN_NUMBER, TAG, `updateForm error: ${error.code}, ${error.message}`);
          });
      });
    }
  }

  onCastToNormalForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onCastToNormalForm');
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onRemoveForm formId: ${formId}`);
    // 移除时清理 Preferences 中的 formId
    preferences.getPreferences(this.context, PREFERENCES_NAME).then((prefs: preferences.Preferences) => {
      const keys = ['weekFormIdList', 'monthFormIdList'];
      for (const key of keys) {
        try {
          let formIds: string[] = prefs.getSync(key, []) as string[];
          if (Array.isArray(formIds)) {
            const index = formIds.indexOf(formId);
            if (index !== -1) {
              formIds.splice(index, 1);
              prefs.putSync(key, formIds);
              prefs.flush();
            }
          }
        } catch (e) {}
      }
    }).catch((e: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `onRemoveForm error: ${e.code}, ${e.message}`);
    });
  }
}
