import { LoadMode, Product } from '../model/Product';
import { ProductGateway } from './ProductGateway';
import { HttpProductGateway } from './HttpProductGateway';
import { MockProductGateway } from './MockProductGateway';

export class ProductService {
  static async list(mode: LoadMode): Promise<Product[]> {
    const gateway: ProductGateway = mode === LoadMode.Network
      ? new HttpProductGateway() : new MockProductGateway(mode);
    return gateway.list();
  }
}
