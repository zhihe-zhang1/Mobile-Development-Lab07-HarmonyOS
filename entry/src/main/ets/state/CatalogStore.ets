import { Product, LoadMode, LoadStatus, DetailResult, filterProducts } from '../model/Product';
import { ProductService } from '../service/ProductService';
import { ProductPreferences } from './ProductPreferences';

// 视图快照是不可变更新的载体：每次修改都创建新的快照并整体赋给 @State。
export class CatalogSnapshot {
  mode: LoadMode = LoadMode.Sample;
  status: LoadStatus = LoadStatus.Loading;
  products: Product[] = [];
  cached: Product[] = [];
  favorites: string[] = [];
  query: string = '';
  errorText: string = '';
  origin: string = '本地 Mock';
  persistenceText: string = '';
  actionText: string = '';

  copy(): CatalogSnapshot {
    const next = new CatalogSnapshot();
    next.mode = this.mode;
    next.status = this.status;
    next.products = this.products.slice();
    next.cached = this.cached.slice();
    next.favorites = this.favorites.slice();
    next.query = this.query;
    next.errorText = this.errorText;
    next.origin = this.origin;
    next.persistenceText = this.persistenceText;
    next.actionText = this.actionText;
    return next;
  }
}

export class CatalogStore {
  private current: CatalogSnapshot = new CatalogSnapshot();
  private generation: number = 0;

  snapshot(): CatalogSnapshot { return this.current.copy(); }

  async restore(context: Context): Promise<CatalogSnapshot> {
    const next = this.current.copy();
    try {
      const restored = await ProductPreferences.load(context);
      next.favorites = restored.favorites;
      next.cached = restored.cached;
      next.persistenceText = '恢复收藏 ' + restored.favorites.length +
        ' 件；本地商品缓存 ' + restored.cached.length + ' 件';
    } catch (_) {
      next.persistenceText = 'Preferences 读取失败，可继续使用 Mock 商品';
    }
    this.current = next;
    return this.snapshot();
  }

  updateQuery(text: string): CatalogSnapshot {
    const next = this.current.copy();
    next.query = text;
    this.current = next;
    return this.snapshot();
  }

  visible(snapshot: CatalogSnapshot): Product[] {
    return filterProducts(snapshot.products, snapshot.query);
  }

  saved(snapshot: CatalogSnapshot): Product[] {
    const merged = snapshot.products.concat(snapshot.cached.filter((item: Product): boolean =>
      !snapshot.products.some((fresh: Product): boolean => fresh.id === item.id)));
    return merged.filter((item: Product): boolean => snapshot.favorites.includes(item.id));
  }

  async load(context: Context, mode: LoadMode,
    notify: (state: CatalogSnapshot) => void): Promise<void> {
    const request = ++this.generation;
    const loading = this.current.copy();
    loading.mode = mode;
    loading.status = LoadStatus.Loading;
    loading.errorText = '';
    loading.actionText = '';
    this.current = loading;
    notify(this.snapshot());

    try {
      const list = await ProductService.list(mode);
      // 后发请求优先，防止切换数据源时旧响应反向覆盖。
      if (request !== this.generation) { return; }
      const ready = this.current.copy();
      ready.products = list;
      ready.status = list.length === 0 ? LoadStatus.Empty : LoadStatus.Success;
      ready.origin = mode === LoadMode.Network ? 'DummyJSON 真实接口' : '本地 Mock 测试数据';
      if (list.length > 0) {
        ready.cached = list.concat(ready.cached.filter((old: Product): boolean =>
          !list.some((p: Product): boolean => p.id === old.id))).slice(0, 80);
      }
      this.current = ready;
      notify(this.snapshot());
      if (list.length > 0) {
        try {
          await ProductPreferences.saveProducts(context, ready.cached);
          if (request !== this.generation) { return; }
          const stored = this.current.copy();
          stored.persistenceText = '商品缓存已保存到 Preferences';
          this.current = stored;
          notify(this.snapshot());
        } catch (_) {
          if (request !== this.generation) { return; }
          const warning = this.current.copy();
          warning.persistenceText = '商品加载成功，但缓存写入失败';
          this.current = warning;
          notify(this.snapshot());
        }
      }
    } catch (error) {
      if (request !== this.generation) { return; }
      const failed = this.current.copy();
      failed.products = [];
      failed.status = LoadStatus.Failure;
      failed.errorText = error instanceof Error ? error.message : '未知请求错误';
      this.current = failed;
      notify(this.snapshot());
    }
  }

  showCache(): CatalogSnapshot {
    if (this.current.cached.length === 0) { return this.snapshot(); }
    ++this.generation;
    const next = this.current.copy();
    next.products = next.cached.slice();
    next.status = LoadStatus.Success;
    next.origin = 'Preferences 离线缓存';
    next.errorText = '';
    this.current = next;
    return this.snapshot();
  }

  async changeFavorite(context: Context, result: DetailResult): Promise<CatalogSnapshot> {
    const next = this.current.copy();
    const exists = next.cached.some((p: Product): boolean => p.id === result.id) ||
      next.products.some((p: Product): boolean => p.id === result.id);
    if (!exists) {
      next.actionText = '商品不存在，收藏未修改';
      this.current = next;
      return this.snapshot();
    }
    const ids = next.favorites.filter((id: string): boolean => id !== result.id);
    if (result.favorite) { ids.push(result.id); }
    try {
      // 先 flush，再报告成功；失败时不修改内存中的收藏状态。
      await ProductPreferences.saveFavorites(context, ids);
      const saved = this.current.copy();
      saved.favorites = ids;
      saved.actionText = result.favorite ? '收藏已保存' : '已取消收藏';
      saved.persistenceText = '收藏记录已持久化，重启应用可恢复';
      this.current = saved;
    } catch (_) {
      const failed = this.current.copy();
      failed.actionText = '保存失败，请重新操作';
      this.current = failed;
    }
    return this.snapshot();
  }
}
