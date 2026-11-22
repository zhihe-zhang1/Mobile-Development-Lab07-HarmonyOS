import { http } from '@kit.NetworkKit';

// HarmonyOS 原生网络异常通常带 code 和 message，不一定是 JS Error。
interface NativeRequestError {
  code?: number;
  message?: string;
}

export class HttpClient {
  static readonly BASE_URL: string = 'https://dummyjson.com';
  static readonly CONNECT_TIMEOUT_MS: number = 8000;
  static readonly READ_TIMEOUT_MS: number = 10000;

  // 返回可显示的错误原因，并保留系统错误码，便于在模拟器上排障。
  private static explain(error: Object | string | undefined | null): string {
    let code: number = 0;
    let detail: string = '';
    if (typeof error === 'string') {
      detail = error;
    } else if (error !== undefined && error !== null && typeof error === 'object') {
      const nativeError: NativeRequestError = error as NativeRequestError;
      if (typeof nativeError.code === 'number') { code = nativeError.code; }
      if (typeof nativeError.message === 'string') { detail = nativeError.message; }
    }
    switch (code) {
      case 201: return '无网络访问权限（201），检查 module.json5 的 INTERNET 权限';
      case 2300006: return 'DNS 解析失败（2300006），请检查模拟器联网和域名';
      case 2300007: return '服务器连接失败（2300007），请检查模拟器网络';
      case 2300028: return '网络请求超时（2300028），请稍后重试';
      case 2300058: return 'SSL 证书验证失败（2300058），请检查模拟器时间与证书';
    }
    if (detail.toLowerCase().includes('timeout')) {
      return '网络请求超时：' + detail;
    }
    return (code !== 0 ? '错误码 ' + code + '：' : '') +
      (detail.length > 0 ? detail : '系统未返回详细原因，请检查 HiLog');
  }

  static async get(path: string): Promise<string> {
    if (!path.startsWith('/') || path.startsWith('//')) {
      throw new Error('非法的接口路径');
    }
    const request = http.createHttp();
    try {
      const response = await request.request(HttpClient.BASE_URL + path, {
        method: http.RequestMethod.GET,
        header: { 'Accept': 'application/json' },
        connectTimeout: HttpClient.CONNECT_TIMEOUT_MS,
        readTimeout: HttpClient.READ_TIMEOUT_MS
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error('HTTP ' + response.responseCode);
      }
      if (typeof response.result !== 'string') {
        throw new Error('接口响应不是文本 JSON');
      }
      return response.result;
    } catch (error) {
      // 不能只用 instanceof Error：HarmonyOS BusinessError 可能是普通对象。
      throw new Error('网络请求失败：' + HttpClient.explain(error));
    } finally {
      try {
        request.destroy();
      } catch (_) {
        // 清理失败不覆盖原始网络错误。
      }
    }
  }
}
