import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * HTTP 请求工具类
 */
export class HttpClient {
  private static instance: HttpClient;
  private baseUrl: string = '';

  private constructor() {}

  static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient();
    }
    return HttpClient.instance;
  }

  /**
   * 设置服务器地址
   */
  setBaseUrl(url: string): void {
    this.baseUrl = url;
  }

  /**
   * POST 请求
   */
  async post<T>(path: string, data: Record<string, Object>): Promise<T> {
    const url = this.baseUrl + path;

    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(data)
      });

      if (response.responseCode === 200) {
        return JSON.parse(response.result as string) as T;
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } finally {
      request.destroy();
    }
  }
}

// 登录响应数据类
export class LoginResponseData {
  sessionId: string = '';
  unionId: string = '';
  openId: string = '';
  nickName: string = '';
  avatarUrl: string = '';
  phoneNumber: string = '';
  registrationNumber: string = '';
}

// 登录响应类
export class LoginResponse {
  success: boolean = false;
  data?: LoginResponseData = undefined;
  error: string = '';
  message: string = '';
}
