/**
 * 同步状态枚举
 *
 * 用于显示云同步状态
 */
export enum SyncStatus {
  IDLE = 'idle',           // 空闲
  SYNCING = 'syncing',     // 同步中
  SUCCESS = 'success',     // 同步成功
  ERROR = 'error',         // 同步失败
  STOPPED = 'stopped'      // 同步停止
}

/**
 * 同步结果接口
 */
export interface SyncResult {
  success: boolean;
  message: string;
  timestamp: number;
  state?: string;
}

/**
 * 云端数据结构接口
 */
export interface CloudData {
  records: any[];
  shops: any[];
  version: number;
  lastSyncTime: number;
}
