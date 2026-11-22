import { Product, validatedProduct } from '../model/Product';
import { ProductGateway } from './ProductGateway';
import { HttpClient } from './HttpClient';

// 使用公开演示接口，不需要用户登录。
interface RemoteProduct {
  id: number;
  title: string;
  category: string;
  price: number;
  stock: number;
  description: string;
}
interface RemoteResponse {
  products: RemoteProduct[];
  total: number;
  skip: number;
  limit: number;
}

export class HttpProductGateway implements ProductGateway {
  async list(): Promise<Product[]> {
    const text: string = await HttpClient.get('/products?limit=12');
    let payload: RemoteResponse;
    try {
      payload = JSON.parse(text) as RemoteResponse;
    } catch (_) {
      throw new Error('接口返回了无效 JSON');
    }
    if (!payload || !Array.isArray(payload.products)) {
      throw new Error('接口缺少 products 数组');
    }
    const result: Product[] = [];
    for (const remote of payload.products) {
      if (typeof remote.id !== 'number' || !Number.isInteger(remote.id) ||
        typeof remote.title !== 'string' || typeof remote.category !== 'string' ||
        typeof remote.description !== 'string' || typeof remote.price !== 'number' ||
        typeof remote.stock !== 'number') {
        throw new Error('商品字段与接口契约不一致');
      }
      const item: Product = {
        id: 'API-' + remote.id,
        name: remote.title,
        category: remote.category,
        price: remote.price,
        currency: 'USD',
        stock: remote.stock,
        description: remote.description
      };
      if (!validatedProduct(item)) { throw new Error('商品校验失败'); }
      result.push(item);
    }
    return result;
  }
}
