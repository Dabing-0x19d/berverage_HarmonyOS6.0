/**
 * 云存储服务导出索引
 *
 * 注意：
 * 云同步功能需要在 AppGallery Connect 中配置云存储服务。
 * 配置完成后，使用 relationalStore 的云同步相关 API。
 */

// 同步状态类型（保留供未来使用）
export enum SyncStatus {
  IDLE = 'idle',
  SYNCING = 'syncing',
  SUCCESS = 'success',
  ERROR = 'error',
  STOPPED = 'stopped'
}

export interface SyncResult {
  success: boolean;
  message: string;
  timestamp: number;
}

export interface CloudData {
  records: any[];
  shops: any[];
  version: number;
  lastSyncTime: number;
}
