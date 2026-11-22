import { preferences } from '@kit.ArkData';
import { Product, validatedProduct } from '../model/Product';

export class StoredData {
  favorites: string[] = [];
  cached: Product[] = [];
}

export class ProductPreferences {
  private static readonly FILE: string = 'lab07_preferences';
  private static readonly FAVORITES: string = 'favorite_product_ids';
  private static readonly CACHE: string = 'last_success_products';

  static async load(context: Context): Promise<StoredData> {
    const data = new StoredData();
    let rawIds: string = '[]';
    let rawItems: string = '[]';
    // Preferences 的读写可能抛异常，由本层统一转换错误。
    try {
      const db = await preferences.getPreferences(context, ProductPreferences.FILE);
      rawIds = await db.get(ProductPreferences.FAVORITES, '[]') as string;
      rawItems = await db.get(ProductPreferences.CACHE, '[]') as string;
    } catch (_) {
      throw new Error('读取本地 Preferences 失败');
    }
    try {
      const ids = JSON.parse(rawIds) as string[];
      if (Array.isArray(ids)) {
        data.favorites = ids.filter((id: string): boolean => typeof id === 'string');
      }
    } catch (_) { /* 收藏数据损坏时按空数据恢复 */ }
    try {
      const items = JSON.parse(rawItems) as Product[];
      if (Array.isArray(items)) {
        data.cached = items.filter((item: Product): boolean => validatedProduct(item));
      }
    } catch (_) { /* 商品缓存损坏时不阻断启动 */ }
    return data;
  }

  static async saveFavorites(context: Context, ids: string[]): Promise<void> {
    try {
      const db = await preferences.getPreferences(context, ProductPreferences.FILE);
      await db.put(ProductPreferences.FAVORITES, JSON.stringify(ids));
      await db.flush(); // flush 后收藏才能在重启应用后恢复
    } catch (_) {
      throw new Error('保存收藏到 Preferences 失败');
    }
  }

  static async saveProducts(context: Context, items: Product[]): Promise<void> {
    try {
      const db = await preferences.getPreferences(context, ProductPreferences.FILE);
      // 只缓存公开商品信息，不写入密码、Token 或 Cookie。
      await db.put(ProductPreferences.CACHE, JSON.stringify(items));
      await db.flush();
    } catch (_) {
      throw new Error('保存商品缓存到 Preferences 失败');
    }
  }
}
