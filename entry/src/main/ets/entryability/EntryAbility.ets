import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { systemShare } from '@kit.ShareKit';
import { ShopExportImportManager } from '../model/ShopExportImportManager';
import { initPreferencesContext } from '../common/utils/PreferencesUtil';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private exportImportManager: ShopExportImportManager = new ShopExportImportManager();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 初始化PreferencesContext供静态方法使用
    initPreferencesContext(this.context)

    // 检查是否被分享功能拉起
    this.handleShareIfNeeded(want, launchParam.launchReasonMessage);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', 'Ability onNewWant');
    // 处理分享数据
    this.handleShareIfNeeded(want, launchParam.launchReasonMessage);
  }

  // 处理分享数据
  private async handleShareIfNeeded(want: Want, launchReasonMessage?: string): Promise<void> {
    if (launchReasonMessage === 'ReasonMessage_SystemShare') {
      hilog.info(DOMAIN, 'testTag', 'App launched by system share');
      try {
        const sharedData = await systemShare.getSharedData(want);
        const records = sharedData.getRecords();

        for (let i = 0; i < records.length; i++) {
          const record = records[i];
          const content = record.content as string | undefined;
          if (content) {
            // 尝试解析店铺分享数据
            const preview = await this.exportImportManager.getSharePreview(content);
            if (preview) {
              // 保存分享数据到AppStorage，供页面读取
              AppStorage.setOrCreate('pendingShopShareData', content);
              hilog.info(DOMAIN, 'testTag', 'Shop share data received');
              break;
            }
          }
        }
      } catch (err) {
        hilog.error(DOMAIN, 'testTag', 'Failed to get shared data: %{public}s', JSON.stringify(err));
      }
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    // 云同步由系统自动管理，无需手动清理
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      // 获取应用主窗口
      let windowClass: window.Window = windowStage.getMainWindowSync();

      // 1. 设置窗口全屏布局
      let isLayoutFullScreen = true;
      windowClass.setWindowLayoutFullScreen(isLayoutFullScreen).then(() => {
        hilog.info(DOMAIN, 'testTag', 'Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, 'testTag', `Failed to set the window layout to full-screen mode. Code is ${err.code}, message is ${err.message}`);
      });

      // 2. 获取布局避让区域（状态栏和导航栏）
      let type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR;
      let avoidArea = windowClass.getWindowAvoidArea(type);
      let bottomRectHeight = avoidArea.bottomRect.height;
      AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight);

      type = window.AvoidAreaType.TYPE_SYSTEM;
      avoidArea = windowClass.getWindowAvoidArea(type);
      let topRectHeight = avoidArea.topRect.height;
      AppStorage.setOrCreate('topRectHeight', topRectHeight);

      // 3. 注册监听函数，动态获取避让区域数据
      windowClass.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          let newTopRectHeight = data.area.topRect.height;
          AppStorage.setOrCreate('topRectHeight', newTopRectHeight);
          hilog.info(DOMAIN, 'testTag', `Status bar height changed: ${newTopRectHeight}`);
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          let newBottomRectHeight = data.area.bottomRect.height;
          AppStorage.setOrCreate('bottomRectHeight', newBottomRectHeight);
          hilog.info(DOMAIN, 'testTag', `Navigation bar height changed: ${newBottomRectHeight}`);
        }
      });
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    // 应用进入前台时，刷新所有卡片
    // 这里无法直接访问 Home 页面，需要通过事件或其他方式触发
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
