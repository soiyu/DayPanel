import { CLOUD_ENV } from '../../config.ts';

declare const wx: any;

export class WeRunError extends Error {
  readonly code: string;
  constructor(code: string) {
    super(code);
    this.name = 'WeRunError';
    this.code = code;
  }
}

let initialized = false;

export async function requestWeRunCloudID(): Promise<string> {
  if (!initialized) {
    if (!wx?.cloud?.init) throw new WeRunError('cloud_unavailable');
    wx.cloud.init({ env: CLOUD_ENV || undefined, traceUser: false });
    initialized = true;
  }
  return new Promise((resolve, reject) => {
    wx.getWeRunData({
      success: (result: any) => {
        if (result?.cloudID) resolve(result.cloudID);
        else reject(new WeRunError('cloud_id_missing'));
      },
      fail: (error: any) => reject(new WeRunError(error?.errMsg ?? 'werun_failed')),
    });
  });
}
