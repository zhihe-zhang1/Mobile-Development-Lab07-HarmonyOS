import { Product } from '../model/Product';

// 先定义契约：调用方不关心数据来自网络还是 Mock。
export interface ProductGateway {
  list(): Promise<Product[]>;
}
