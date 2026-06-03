import { display } from '@kit.ArkUI';

/**
 * 窗口工具类 - 提供屏幕尺寸和断点相关的工具方法
 */
export class WindowUtil {
  // 断点常量（单位：vp）
  static readonly BREAKPOINT_SMALL = 320;   // 手机边界
  static readonly BREAKPOINT_MEDIUM = 600;  // 大手机/小平板边界
  static readonly BREAKPOINT_LARGE = 840;   // 平板边界
  static readonly BREAKPOINT_EXTRA_LARGE = 1440; // 大屏设备边界

  // 弹窗高度百分比
  static readonly SHEET_RATIO_PHONE = 0.50;  // 手机：50%
  static readonly SHEET_RATIO_TABLET_PORTRAIT = 0.50;  // 平板竖屏：50%
  static readonly SHEET_RATIO_TABLET_LANDSCAPE = 0.70; // 平板横屏：70%

  /**
   * 获取窗口宽度断点值
   * @returns 断点值：0=xs, 1=sm, 2=md, 3=lg, 4=xl
   */
  static getWidthBreakpoint(): number {
    const width = display.getDefaultDisplaySync().width;
    if (width < WindowUtil.BREAKPOINT_SMALL) return 0;      // xs
    if (width < WindowUtil.BREAKPOINT_MEDIUM) return 1;     // sm
    if (width < WindowUtil.BREAKPOINT_LARGE) return 2;      // md
    if (width < WindowUtil.BREAKPOINT_EXTRA_LARGE) return 3;// lg
    return 4;                                               // xl
  }

  /**
   * 是否为手机设备（宽度 < 600vp）
   */
  static isPhone(): boolean {
    return WindowUtil.getWidthBreakpoint() < 2; // md 以下为手机
  }

  /**
   * 是否为平板设备（宽度 >= 600vp）
   */
  static isTablet(): boolean {
    return WindowUtil.getWidthBreakpoint() >= 2; // md 及以上为平板
  }

  /**
   * 是否为横屏模式
   */
  static isLandscape(): boolean {
    const displayInfo = display.getDefaultDisplaySync();
    return displayInfo.width > displayInfo.height;
  }

  /**
   * 计算底部弹窗的合适高度（固定50%屏幕高度）
   * @returns 弹窗高度（像素）
   */
  static getSheetHeight(): number {
    const displayInfo = display.getDefaultDisplaySync();
    const height = Math.round(displayInfo.height * 0.50);
    console.info('[WindowUtil] getSheetHeight called, height=' + height + ', screenHeight=' + displayInfo.height);
    return height;
  }

  /**
   * 获取屏幕宽度
   */
  static getScreenWidth(): number {
    return display.getDefaultDisplaySync().width;
  }

  /**
   * 获取屏幕高度
   */
  static getScreenHeight(): number {
    return display.getDefaultDisplaySync().height;
  }
}
