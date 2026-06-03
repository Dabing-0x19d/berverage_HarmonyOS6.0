import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import http from '@ohos.net.http';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct LoginPage {
  // 登录状态管理
  @StorageProp('isLoggedIn') isLoggedIn: boolean = false;
  @StorageProp('userInfo') userInfo: string = '';

  // 获取UIAbilityContext
  getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  // 华为账号登录
  async signInWithHuaweiID() {
    try {
      // 创建授权请求
      const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      authRequest.permissions = ['serviceauthcode'];
      authRequest.forceAuthorization = true;
      authRequest.state = util.generateRandomUUID();

      // 执行请求
      const controller = new authentication.AuthenticationController(this.getAbilityContext());
      const response = await controller.executeRequest(authRequest) as authentication.AuthorizationWithHuaweiIDResponse;

      // 验证state防止CSRF
      if (response.state && response.state !== authRequest.state) {
        hilog.error(0x0000, 'testTag', 'State mismatch');
        promptAction.showToast({ message: '登录失败' });
        return;
      }

      const authCode = response.data?.authorizationCode;
      if (authCode) {
        hilog.info(0x0000, 'testTag', '获取授权码成功');
        this.sendAuthCodeToServer(authCode);
      }
    } catch (error) {
      const err = error as BusinessError;
      this.dealAllError(err);
    }
  }

  // 发送authCode到服务器
  sendAuthCodeToServer(authCode: string) {
    let httpRequest = http.createHttp();
    // 读取当前应用的clientId（请替换为自己在 AGC 创建应用后获得的真实 Client ID）
    const clientId = 'your_client_id_here';
    // 服务器地址（请替换为自己的后端地址，仓库内已移除默认的本地 Node 示例）
    const serverUrl = 'http://your-server-host:port';
    httpRequest.request(
      `${serverUrl}/api/huawei/login`,
      {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: { authorizationCode: authCode, clientId: clientId }
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (err) {
          hilog.error(0x0000, 'testTag', 'HTTP request failed: %{public}s', err.message);
          promptAction.showToast({ message: '登录失败，请重试' });
          return;
        }
        const resultData = data.result as string;
        const result = JSON.parse(resultData) as Record<string, Object>;
        if (result.success) {
          AppStorage.setOrCreate('isLoggedIn', true);
          AppStorage.setOrCreate('userInfo', JSON.stringify(result.data));
          promptAction.showToast({ message: '登录成功' });
        } else {
          promptAction.showToast({ message: result.message as string || '登录失败' });
        }
        httpRequest.destroy();
      }
    );
  }

  // 错误处理
  dealAllError(error: BusinessError): void {
    hilog.error(0x0000, 'testTag', '登录失败: %{public}d, %{public}s', error.code, error.message);
    if (error.code === 1001502001) {
      promptAction.showToast({ message: '请先登录华为账号' });
    } else if (error.code === 1001502005) {
      promptAction.showToast({ message: '网络异常，请检查网络' });
    } else if (error.code === 1001502012) {
      // 用户取消授权
    } else if (error.code === 12300001) {
      promptAction.showToast({ message: '系统服务异常' });
    } else if (error.code === 1005300001) {
      promptAction.showToast({ message: '请同意隐私协议' });
    } else {
      promptAction.showToast({ message: '登录失败' });
    }
  }

  build() {
    Column() {
      Button('华为账号登录')
        .width('80%')
        .height(50)
        .fontColor($r('app.color.text_on_primary'))
        .backgroundColor($r('app.color.huawei_red'))
        .onClick(() => {
          this.signInWithHuaweiID();
        })
    }
    .justifyContent(FlexAlign.Center)
    .constraintSize({ minHeight: '100%' })
    .margin({ left: 16, right: 16 })
  }
}
