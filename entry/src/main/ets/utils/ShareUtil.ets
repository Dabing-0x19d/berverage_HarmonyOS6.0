/**
 * 分享工具类
 * 提供图片分享和文件分享功能
 */
import { common, Want } from '@kit.AbilityKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';
import { componentSnapshot } from '@kit.ArkUI';
import { fileIo as fs } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { util } from '@kit.ArkTS';

export class ShareUtil {
  /**
   * 分享PixelMap为图片（带纯色背景）
   * @param pixelMap 图片像素映射
   * @param uiContext UI上下文
   * @param backgroundColor 背景颜色，默认为白色
   */
  static async sharePixelMapAsImageWithBg(pixelMap: PixelMap, uiContext: UIContext, backgroundColor: string = '#FFFFFF'): Promise<void> {
    try {
      console.info('ShareUtil: Starting sharePixelMapAsImageWithBg');
      const context = uiContext.getHostContext() as common.UIAbilityContext;

      // 获取原图尺寸
      const imageInfo: image.ImageInfo = await pixelMap.getImageInfo();
      const width = imageInfo.size.width;
      const height = imageInfo.size.height;

      // 创建带背景的 PixelMap
      const bgPixelMap = await ShareUtil.createPixelMapWithBg(width, height, backgroundColor);

      const cacheDir = context.cacheDir;
      const fileName = `share_${Date.now()}.png`;
      const filePath = `${cacheDir}/${fileName}`;

      // 使用image packing保存图片
      const packingOptions: image.PackingOption = {
        format: 'image/png',
        quality: 100
      };

      const imagePackerApi = image.createImagePacker();
      const packResult = await imagePackerApi.packing(bgPixelMap, packingOptions);

      // 保存到文件
      const file = fs.openSync(filePath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, packResult);
      fs.closeSync(file.fd);

      imagePackerApi.release();

      // 释放临时 PixelMap
      bgPixelMap.release();

      // 获取UTD类型
      const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.png', utd.UniformDataType.IMAGE);

      // 构造分享数据
      const shareData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath),
        title: '咖啡消费记录分享'
      });

      // 构建分享控制器
      const controller = new systemShare.ShareController(shareData);

      // 显示分享面板
      await controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.SINGLE
      });

      console.info('ShareUtil: Share image with bg success');
    } catch (err) {
      console.error('ShareUtil sharePixelMapAsImageWithBg error: ' + JSON.stringify(err));
    }
  }

  /**
   * 创建带纯色背景的 PixelMap
   */
  private static createPixelMapWithBg(width: number, height: number, bgColor: string): PixelMap {
    // 填充背景色
    const color = bgColor.startsWith('#') ? bgColor.substring(1) : 'FFFFFF';
    const r = parseInt(color.substring(0, 2), 16);
    const g = parseInt(color.substring(2, 4), 16);
    const b = parseInt(color.substring(4, 6), 16);

    const bgPixelMap = image.createPixelMapSync({
      size: { width, height },
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      alphaType: image.AlphaType.OPAQUE
    });

    const buffer = new ArrayBuffer(width * height * 4);
    const data = new Uint32Array(buffer);

    for (let i = 0; i < width * height; i++) {
      data[i] = (255 << 24) | (b << 16) | (g << 8) | r;
    }

    bgPixelMap.writeBufferToPixels(buffer);

    return bgPixelMap;
  }

  /**
   * 分享PixelMap为图片
   * @param pixelMap 图片像素映射
   * @param uiContext UI上下文
   */
  static async sharePixelMapAsImage(pixelMap: PixelMap, uiContext: UIContext): Promise<void> {
    try {
      console.info('ShareUtil: Starting sharePixelMapAsImage');
      const context = uiContext.getHostContext() as common.UIAbilityContext;
      console.info('ShareUtil: Got UI ability context');

      const cacheDir = context.cacheDir;
      const fileName = `share_${Date.now()}.png`;
      const filePath = `${cacheDir}/${fileName}`;
      console.info('ShareUtil: File path: ' + filePath);

      // 使用image packing保存图片
      const packingOptions: image.PackingOption = {
        format: 'image/png',
        quality: 100
      };

      const imagePackerApi = image.createImagePacker();
      console.info('ShareUtil: Packing image...');
      const packResult = await imagePackerApi.packing(pixelMap, packingOptions);
      console.info('ShareUtil: Image packed, size: ' + packResult.byteLength);

      // 保存到文件
      const file = fs.openSync(filePath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, packResult);
      fs.closeSync(file.fd);
      console.info('ShareUtil: File saved');

      imagePackerApi.release();

      // 获取UTD类型
      const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.png', utd.UniformDataType.IMAGE);
      console.info('ShareUtil: Got UTD type');

      // 构造分享数据
      const shareData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath),
        title: '咖啡消费记录分享'
      });
      console.info('ShareUtil: Share data created');

      // 构建分享控制器
      const controller = new systemShare.ShareController(shareData);
      console.info('ShareUtil: Controller created, showing share panel...');

      // 显示分享面板
      await controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.SINGLE
      });

      console.info('ShareUtil: Share image success');
    } catch (err) {
      console.error('ShareUtil sharePixelMapAsImage error: ' + JSON.stringify(err));
    }
  }

  /**
   * 分享纯文本
   * @param content 文本内容
   * @param uiContext UI上下文
   */
  static async shareText(content: string, uiContext: UIContext): Promise<void> {
    try {
      const context = uiContext.getHostContext() as common.UIAbilityContext;

      // 构造分享数据
      const shareData = new systemShare.SharedData({
        utd: utd.UniformDataType.TEXT,
        content: content,
        title: '咖啡消费记录'
      });

      // 构建分享控制器
      const controller = new systemShare.ShareController(shareData);

      // 显示分享面板
      await controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.SINGLE
      });

      console.info('ShareUtil: Share text success');
    } catch (err) {
      console.error('ShareUtil shareText error: ' + JSON.stringify(err));
    }
  }

  /**
   * 分享JSON文件（用于店铺数据分享）
   * @param jsonData JSON数据字符串
   * @param fileName 文件名
   * @param uiContext UI上下文
   */
  static async shareJsonFile(jsonData: string, fileName: string, uiContext: UIContext): Promise<void> {
    try {
      console.info('ShareUtil: Starting shareJsonFile');
      const context = uiContext.getHostContext() as common.UIAbilityContext;
      console.info('ShareUtil: Got UI ability context');

      const filesDir = context.filesDir;
      const filePath = `${filesDir}/${fileName}`;
      console.info('ShareUtil: File path: ' + filePath);

      // 保存JSON文件
      const file = fs.openSync(filePath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      const textEncoder = new util.TextEncoder();
      fs.writeSync(file.fd, textEncoder.encodeInto(jsonData));
      fs.closeSync(file.fd);
      console.info('ShareUtil: JSON file saved');

      // 获取UTD类型 - 使用PLAIN_TEXT作为通用文本类型
      const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.json', utd.UniformDataType.PLAIN_TEXT);
      console.info('ShareUtil: Got UTD type');

      // 构造分享数据
      const shareData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath),
        title: '店铺数据分享'
      });
      console.info('ShareUtil: Share data created');

      // 构建分享控制器
      const controller = new systemShare.ShareController(shareData);
      console.info('ShareUtil: Controller created, showing share panel...');

      // 显示分享面板
      await controller.show(context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.SINGLE
      });

      console.info('ShareUtil: Share JSON file success');
    } catch (err) {
      console.error('ShareUtil shareJsonFile error: ' + JSON.stringify(err));
    }
  }

  /**
   * 从Want中获取分享的JSON数据
   * @param want 分享传入的want
   * @returns Promise<string> JSON字符串
   */
  static async getSharedJsonFromWant(want: Want): Promise<string | null> {
    try {
      const sharedData = await systemShare.getSharedData(want);
      const records = sharedData.getRecords();

      for (let i = 0; i < records.length; i++) {
        const record = records[i];
        // 尝试读取文本内容
        if (record.content) {
          return record.content as string;
        }
        // 如果有uri，尝试读取文件
        if (record.uri) {
          const fileContent = ShareUtil.readFileFromUri(record.uri as string);
          if (fileContent) {
            return fileContent;
          }
        }
      }
      return null;
    } catch (err) {
      console.error('ShareUtil getSharedJsonFromWant error: ' + JSON.stringify(err));
      return null;
    }
  }

  /**
   * 从URI读取文件内容
   */
  private static readFileFromUri(uri: string): string | null {
    try {
      // 将file:// URI转换为路径
      const path = uri.replace('file://', '');
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(1024 * 1024); // 1MB缓冲
      const readLen = fs.readSync(file.fd, buffer);
      fs.closeSync(file.fd);
      const decoder = new util.TextDecoder();
      return decoder.decodeToString(new Uint8Array(buffer, 0, readLen));
    } catch (err) {
      console.error('ShareUtil readFileFromUri error: ' + JSON.stringify(err));
      return null;
    }
  }
}
