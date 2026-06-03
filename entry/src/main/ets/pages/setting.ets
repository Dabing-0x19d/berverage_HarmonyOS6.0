import { router } from '@kit.ArkUI';
import { Font } from "@kit.ArkUI";
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { LoginStateManager, LoginState } from '../model/LoginStateManager';
import { HttpClient, LoginResponse } from '../utils/HttpClient';

// 服务器地址（改成你的服务器地址）
const SERVER_URL = 'http://localhost:3000';

// 云函数响应类型
class CloudFunctionResponseData {
  sessionId: string = '';
  unionId: string = '';
  openId: string = '';
  nickName: string = '';
  avatarUrl: string = '';
  phoneNumber: string = '';
  registrationNumber: string = '';
  accessToken: string = '';
}

class CloudFunctionResponse {
  retCode: number = 0;
  retMsg: string = '';
  data: CloudFunctionResponseData = new CloudFunctionResponseData();
}

@Entry
@Component
export struct setting {
  @State loginState: LoginState = LoginStateManager.getInstance().getLoginState();
  @State showLoginDialog: boolean = false;
  @State isLoading: boolean = false;

  aboutToAppear(): void {
    // 注册登录状态监听
    LoginStateManager.getInstance().addListener((state: LoginState) => {
      this.loginState = state;
    });

    // 初始化登录状态
    LoginStateManager.getInstance().init(getContext(this));
  }

  aboutToDisappear(): void {
    // 移除监听
    LoginStateManager.getInstance().removeListener(() => {
      // 监听器移除
    });
  }

  /**
   * 华为账号登录（同时获取手机号、头像、昵称）
   */
  async loginWithHuaweiID(): Promise<void> {
    hilog.info(0x0000, 'CoffeeApp', '开始华为账号登录');
    this.isLoading = true;

    try {
      // 创建授权请求，同时请求 profile（头像昵称）和 phone（手机号）
      const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      authRequest.scopes = ['profile']; // 暂时只获取头像昵称，需要在AGC配置phone权限后才能获取手机号
      authRequest.permissions = ['serviceauthcode'];
      authRequest.forceAuthorization = true;
      authRequest.state = util.generateRandomUUID();

      // 获取UI上下文并创建认证控制器
      const uiContext = getContext(this);
      const controller = new authentication.AuthenticationController(uiContext);

      // 执行授权请求
      controller.executeRequest(authRequest).then((data) => {
        const authResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
        const state = authResponse.state;

        hilog.info(0x0000, 'CoffeeApp', '华为账号授权成功');

        // 验证state防止CSRF攻击
        if (state && authRequest.state !== state) {
          hilog.error(0x0000, 'CoffeeApp', `授权失败，state不匹配`);
          this.isLoading = false;
          return;
        }

        const credential = authResponse?.data;
        const authorizationCode = credential?.authorizationCode;

        hilog.info(0x0000, 'CoffeeApp', `获取到 authorizationCode: ${authorizationCode}`);

        if (authorizationCode) {
          // 调用服务器登录
          this.handleLoginSuccessWithServer(authorizationCode);
        } else {
          hilog.warn(0x0000, 'CoffeeApp', '无 authorizationCode，使用离线模式');
          this.handleLoginSuccessOffline();
        }
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'CoffeeApp', `授权失败: ${err.code}, ${err.message}`);
        this.dealAllError(err);
        this.isLoading = false;
      });
    } catch (error) {
      hilog.error(0x0000, 'CoffeeApp', `登录异常: ${JSON.stringify(error)}`);
      this.isLoading = false;
    }
  }

  /**
   * 错误处理
   */
  dealAllError(error: BusinessError): void {
    hilog.error(0x0000, 'CoffeeApp',
      `登录失败, errorCode: ${error.code}, errorMessage: ${error.message}`);

    if (error.code === 1001502012) {
      // 用户取消授权，无需提示
    } else if (error.code === 1001502001) {
      // 华为账号未登录
    } else if (error.code === 1001502005) {
      // 网络异常
    } else {
      // 其他错误
    }
  }

  /**
   * 处理登录成功
   * 调用自己的服务器验证 authorizationCode 并获取用户信息
   */
  async handleLoginSuccessWithServer(authorizationCode: string): Promise<void> {
    hilog.info(0x0000, 'CoffeeApp', '开始调用服务器登录');

    try {
      // 设置服务器地址并调用登录接口
      const httpClient = HttpClient.getInstance();
      httpClient.setBaseUrl(SERVER_URL);
      const result = await httpClient.post<LoginResponse>('/api/huawei/login', {
        'authorizationCode': authorizationCode
      });

      hilog.info(0x0000, 'CoffeeApp', '服务器响应: ' + JSON.stringify(result));

      if (result.success && result.data) {
        hilog.info(0x0000, 'CoffeeApp', '登录成功: ' + result.data.nickName);

        // 保存登录状态
        await LoginStateManager.getInstance().setLoggedIn(
          result.data.unionId,
          result.data.openId,
          result.data.nickName,
          result.data.avatarUrl,
          result.data.phoneNumber,
          result.data.registrationNumber
        );
        this.showLoginDialog = false;
        this.isLoading = false;
        hilog.info(0x0000, 'CoffeeApp', `登录完成，注册编号: ${result.data.registrationNumber}`);
      } else {
        hilog.error(0x0000, 'CoffeeApp', '登录失败: ' + (result.error || result.message));
        this.isLoading = false;
      }
    } catch (error) {
      hilog.error(0x0000, 'CoffeeApp', '登录异常: ' + JSON.stringify(error));
      this.isLoading = false;
    }
  }

  /**
   * 处理登录成功（离线模式）
   * 服务器不可用时直接保存登录状态
   */
  async handleLoginSuccessOffline(): Promise<void> {
    hilog.info(0x0000, 'CoffeeApp', '登录成功（离线模式）');

    // 保存登录状态
    await LoginStateManager.getInstance().setLoggedIn(
      'demo_user_' + Date.now(),
      'demo_open_' + Date.now(),
      '华为账号用户',
      '',
      '',
      ''
    );

    this.showLoginDialog = false;
    this.isLoading = false;

    hilog.info(0x0000, 'CoffeeApp', '登录完成');
  }

  /**
   * 退出登录
   */
  async handleLogout(): Promise<void> {
    // 华为账号登录无需服务器端登出，只需清除本地登录状态
    await LoginStateManager.getInstance().logout();
    hilog.info(0x0000, 'CoffeeApp', '已退出登录');
  }

  /**
   * 账号区域点击事件
   */
  onAccountClick(): void {
    if (!this.loginState.isLoggedIn) {
      this.showLoginDialog = true;
    }
  }

  @StorageProp('bottomRectHeight')
  bottomRectHeight: number = 0;
  @StorageProp('topRectHeight')
  topRectHeight: number = 0;

  build() {
    Stack() {
      // 主内容
      Column() {
        Row() {
          Text("设置")
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 20 })
        }
        .width("100%")
        .height(50)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)

        Column({ space: 0 }) {
          // 账号区域
          Row() {
            // 头像
            if (this.loginState.isLoggedIn && this.loginState.avatarUrl) {
              Image(this.loginState.avatarUrl)
                .width(50)
                .height(50)
                .borderRadius(25)
                .backgroundColor('#E0E0E0')
            } else {
              Circle({ width: 50, height: 50 })
                .fill(this.loginState.isLoggedIn ? $r('app.color.tab_selected') : '#E0E0E0')
            }

            Column() {
              Text(this.loginState.isLoggedIn ? this.loginState.nickName : "点击登录")
                .fontSize(17)
                .fontColor($r('app.color.text_primary'))
              if (this.loginState.isLoggedIn) {
                Text("已登录华为账号")
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
              }
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })

            Blank()

            Text(this.loginState.isLoggedIn ? "已登录" : ">")
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
          }
          .width("94%")
          .height(70)
          .backgroundColor($r('app.color.background_card'))
          .borderRadius(15)
          .shadow({
            radius: 20,
            color: $r('app.color.shadow_color'),
            offsetY: 8
          })
          .margin({ left: "3%", right: "3%" })
          .padding({ left: 16, right: 16 })
          .onClick(() => this.onAccountClick())

          // 设置卡片
          Column() {
            // 店铺管理
            Row() {
              Text("店铺管理")
                .fontSize(17)
            }
            .width("100%")
            .height(50)
            .padding({ left: 25, right: 25 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/ShopManagePage' });
            })

            // 分隔线
            Row()
              .width("100%")
              .height(0.5)
              .backgroundColor("#c6c6c8")

            // 显示注册编号（已登录时）
            if (this.loginState.isLoggedIn && this.loginState.registrationNumber) {
              Row() {
                Text("注册编号")
                  .fontSize(17)
                Blank()
                Text(this.loginState.registrationNumber)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width("100%")
              .height(50)
              .padding({ left: 25, right: 25 })

              // 分隔线
              Row()
                .width("100%")
                .height(0.5)
                .backgroundColor("#c6c6c8")
            }

            // 退出登录（仅已登录时显示）
            if (this.loginState.isLoggedIn) {
              Row() {
                Text("退出登录")
                  .fontSize(17)
                  .fontColor($r('app.color.chart_concentration_high'))
              }
              .width("100%")
              .height(50)
              .padding({ left: 25, right: 25 })
              .onClick(() => {
                this.handleLogout();
              })

              // 分隔线
              Row()
                .width("100%")
                .height(0.5)
                .backgroundColor("#c6c6c8")
            }

            // 建议
            Row() {
              Text("建议")
                .fontSize(17)
            }
            .width("100%")
            .height(50)
            .padding({ left: 25, right: 25 })

            // 分隔线
            Row()
              .width("100%")
              .height(0.5)
              .backgroundColor("#c6c6c8")

            // 关于
            Column({ space: 10 }) {
              Text("一杯一档")
                .fontSize(17)

                .fontColor($r('app.color.text_primary'))

              Text("版本 1.4.0")
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
            }
            .width("100%")
            .padding({ left: 25, right: 25, top: 15, bottom: 15 })
            .alignItems(HorizontalAlign.Start)
          }
          .width("94%")
          .backgroundColor($r('app.color.background_card'))
          .borderRadius(15)
          .shadow({
            radius: 20,
            color: $r('app.color.shadow_color'),
            offsetY: 8
          })
          .margin({ left: "3%", right: "3%", top: 15 })
        }
        .width("100%")
        .layoutWeight(1)
        .backgroundColor($r('app.color.background_primary'))
      }
      .width("100%")
      .height("100%")
      .backgroundColor($r('app.color.background_primary'))

      // 登录弹窗
      if (this.showLoginDialog) {
        Stack({ alignContent: Alignment.Center }) {
          // 遮罩层
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#80000000')
            .onClick(() => {
              this.showLoginDialog = false;
              this.isLoading = false;
            })

          // 登录面板
          Column({ space: 16 }) {
            Text("华为账号登录")
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 20 })

            Text("登录后即可同步您的咖啡记录")
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 10 })

            if (!this.isLoading) {
              Button({ type: ButtonType.Capsule }) {
                Text("华为账号登录")
                  .fontSize(16)
                  .fontColor(Color.White)
              }
              .width('85%')
              .height(44)
              .backgroundColor($r('app.color.huawei_red'))
              .onClick(() => {
                this.loginWithHuaweiID();
              })
            } else {
              Row() {
                LoadingProgress()
                  .width(24)
                  .height(24)
                  .color($r('app.color.text_primary'))
                Text("登录中...")
                  .fontSize(16)
                  .margin({ left: 10 })
              }
              .height(44)
              .justifyContent(FlexAlign.Center)
            }

            Text("取消")
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 10, bottom: 15 })
              .onClick(() => {
                this.showLoginDialog = false;
                this.isLoading = false;
              })
          }
          .width('82%')
          .backgroundColor($r('app.color.background_card'))
          .borderRadius(20)
          .padding({ left: 24, right: 24 })
        }
        .width('100%')
        .height('100%')
      }
    }
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),
      bottom: this.getUIContext().px2vp(this.bottomRectHeight)
    })
    .width("100%")
    .height("100%")
  }
}
