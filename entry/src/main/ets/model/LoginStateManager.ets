/**
 * 全局登录状态管理
 * 用于管理华为账号登录状态
 */

import { relationalStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

// 登录状态存储键名
const LOGIN_STATE_KEY: string = 'login_state';

/**
 * 登录状态数据
 */
export interface LoginState {
  isLoggedIn: boolean;           // 是否已登录
  unionId: string;              // 华为账号UnionID
  openId: string;               // 华为账号OpenID
  nickName: string;             // 用户昵称
  avatarUrl: string;            // 头像URL
  phoneNumber: string;          // 手机号
  registrationNumber: string;   // 注册编号
  loginTime: number;            // 登录时间戳
}

/**
 * 默认登录状态
 */
export const DEFAULT_LOGIN_STATE: LoginState = {
  isLoggedIn: false,
  unionId: '',
  openId: '',
  nickName: '',
  avatarUrl: '',
  phoneNumber: '',
  registrationNumber: '',
  loginTime: 0
};

/**
 * 全局登录状态管理类
 */
export class LoginStateManager {
  private static instance: LoginStateManager | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: Context | null = null;
  private loginState: LoginState = DEFAULT_LOGIN_STATE;
  private listeners: Set<(state: LoginState) => void> = new Set();

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): LoginStateManager {
    if (!LoginStateManager.instance) {
      LoginStateManager.instance = new LoginStateManager();
    }
    return LoginStateManager.instance;
  }

  /**
   * 初始化登录状态管理器
   */
  async init(context: Context): Promise<void> {
    this.context = context;
    await this.initDatabase();
    await this.loadLoginState();
  }

  /**
   * 初始化数据库表
   */
  private async initDatabase(): Promise<void> {
    if (!this.context) return;

    const config: relationalStore.StoreConfig = {
      name: 'login_state.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };

    this.rdbStore = await relationalStore.getRdbStore(this.context, config);

    const sqlCreateTable = `
      CREATE TABLE IF NOT EXISTS ${LOGIN_STATE_KEY} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_name TEXT UNIQUE,
        key_value TEXT
      )
    `;
    await this.rdbStore.executeSql(sqlCreateTable);
  }

  /**
   * 从数据库加载登录状态
   */
  private async loadLoginState(): Promise<void> {
    if (!this.rdbStore) return;

    const predicates = new relationalStore.RdbPredicates(LOGIN_STATE_KEY);
    predicates.equalTo('key_name', LOGIN_STATE_KEY);

    const resultSet = await this.rdbStore.query(predicates);
    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow();
      const value = resultSet.getString(resultSet.getColumnIndex('key_value'));
      try {
        this.loginState = JSON.parse(value);
        this.notifyListeners();
      } catch (e) {
        console.error('解析登录状态失败:', e);
        this.loginState = DEFAULT_LOGIN_STATE;
      }
    }
    resultSet.close();
  }

  /**
   * 保存登录状态到数据库
   */
  private async saveLoginState(): Promise<void> {
    if (!this.rdbStore) return;

    const value = JSON.stringify(this.loginState);
    const sqlUpsert = `
      INSERT OR REPLACE INTO ${LOGIN_STATE_KEY} (id, key_name, key_value)
      VALUES (1, '${LOGIN_STATE_KEY}', '${value}')
    `;
    await this.rdbStore.executeSql(sqlUpsert);
  }

  /**
   * 获取当前登录状态
   */
  getLoginState(): LoginState {
    const state: LoginState = {
      isLoggedIn: this.loginState.isLoggedIn,
      unionId: this.loginState.unionId,
      openId: this.loginState.openId,
      nickName: this.loginState.nickName,
      avatarUrl: this.loginState.avatarUrl,
      phoneNumber: this.loginState.phoneNumber,
      registrationNumber: this.loginState.registrationNumber,
      loginTime: this.loginState.loginTime
    };
    return state;
  }

  /**
   * 判断是否已登录
   */
  isLoggedIn(): boolean {
    return this.loginState.isLoggedIn;
  }

  /**
   * 设置已登录状态（服务端验证成功后调用）
   */
  async setLoggedIn(unionId: string, openId: string, nickName: string = '', avatarUrl: string = '', phoneNumber: string = '', registrationNumber: string = ''): Promise<void> {
    this.loginState = {
      isLoggedIn: true,
      unionId,
      openId,
      nickName: nickName || '华为账号用户',
      avatarUrl,
      phoneNumber,
      registrationNumber,
      loginTime: Date.now()
    };
    await this.saveLoginState();
    this.notifyListeners();
  }

  /**
   * 退出登录
   */
  async logout(): Promise<void> {
    this.loginState = DEFAULT_LOGIN_STATE;
    await this.saveLoginState();
    this.notifyListeners();
  }

  /**
   * 注册状态变化监听
   */
  addListener(listener: (state: LoginState) => void): void {
    this.listeners.add(listener);
  }

  /**
   * 移除状态变化监听
   */
  removeListener(listener: (state: LoginState) => void): void {
    this.listeners.delete(listener);
  }

  /**
   * 通知所有监听器
   */
  private notifyListeners(): void {
    this.listeners.forEach(listener => {
      try {
        listener(this.loginState);
      } catch (e) {
        console.error('通知监听器失败:', e);
      }
    });
  }
}
