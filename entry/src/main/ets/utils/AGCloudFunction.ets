import { BusinessError } from '@kit.BasicServicesKit';
import { cloudFunction } from '@kit.CloudFoundationKit';

// 云函数基础配置
const CLOUD_FUNCTION_NAME: string = 'login-huawei-id';
const CLOUD_FUNCTION_VERSION: string = '$latest';

// 云函数响应类
class CloudFunctionResponse<T> {
  retCode: number = 0;
  retMsg: string = '';
  data?: T;
}

// 登录响应数据类
class LoginData {
  unionId: string = '';
  openId: string = '';
  nickName: string = '';
  avatarUrl: string = '';
  phoneNumber: string = '';
  registrationNumber: string = '';
  accessToken: string = '';
}

/**
 * AGC云函数调用工具类
 * 用于调用后端云函数处理华为账号登录
 */
export class AGCloudFunction {
  private static instance: AGCloudFunction;

  private constructor() {}

  static getInstance(): AGCloudFunction {
    if (!AGCloudFunction.instance) {
      AGCloudFunction.instance = new AGCloudFunction();
    }
    return AGCloudFunction.instance;
  }

  /**
   * 调用华为账号登录云函数
   * @param authorizationCode 华为账号授权码
   */
  async loginWithHuaweiID(authorizationCode: string): Promise<CloudFunctionResponse<LoginData>> {
    console.info('[CloudFunction] 开始调用AGC云函数');

    try {
      const result = await cloudFunction.call({
        name: CLOUD_FUNCTION_NAME,
        version: CLOUD_FUNCTION_VERSION,
        data: {
          authCode: authorizationCode,
          timestamp: Date.now()
        }
      });

      console.info('[CloudFunction] 云函数调用成功');

      // 转换结果
      const response = new CloudFunctionResponse<LoginData>();
      response.retCode = 0;
      response.retMsg = 'success';
      response.data = this.convertToLoginData(result);

      return response;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[CloudFunction] 调用登录云函数失败: ${err.code}, ${err.message}`);
      const response = new CloudFunctionResponse<LoginData>();
      response.retCode = err.code || -1;
      response.retMsg = err.message || '未知错误';
      return response;
    }
  }

  /**
   * 转换数据为LoginData类型
   */
  private convertToLoginData(result: Object): LoginData {
    const data = new LoginData();
    const obj = result as Record<string, Object>;
    if (obj) {
      data.unionId = String(obj['unionId'] || '');
      data.openId = String(obj['openId'] || '');
      data.nickName = String(obj['nickName'] || '华为账号用户');
      data.avatarUrl = String(obj['avatarUrl'] || '');
      data.phoneNumber = String(obj['phoneNumber'] || '');
      data.registrationNumber = String(obj['registrationNumber'] || '');
      data.accessToken = String(obj['accessToken'] || '');
    }
    return data;
  }

  /**
   * 通用云函数调用方法
   */
  async callFunction<T>(functionName: string, data: Record<string, object>): Promise<CloudFunctionResponse<T>> {
    console.info(`[CloudFunction] 调用云函数: ${functionName}`);

    try {
      const result = await cloudFunction.call({
        name: functionName,
        version: CLOUD_FUNCTION_VERSION,
        data: data
      });

      console.info(`[CloudFunction] 云函数${functionName}调用成功`);

      const response = new CloudFunctionResponse<T>();
      response.retCode = 0;
      response.retMsg = 'success';
      response.data = result as T;

      return response;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[CloudFunction] 调用云函数${functionName}失败: ${err.message}`);
      const response = new CloudFunctionResponse<T>();
      response.retCode = err.code || -1;
      response.retMsg = err.message || '未知错误';
      return response;
    }
  }
}
