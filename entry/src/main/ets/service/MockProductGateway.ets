import { LoadMode, Product } from '../model/Product';
import { ProductGateway } from './ProductGateway';

// 本地测试数据是人为编写的样例，不代表实际库存或成交价格。
const MOCK_PRODUCTS: Product[] = [
  { id: 'EL-101', name: '无线蓝牙耳机', category: '数码', price: 129.00,
    currency: 'CNY', stock: 18, description: '轻巧的入耳设计，适合通勤和学习。' },
  { id: 'DS-102', name: '方格笔记本', category: '文具', price: 19.90,
    currency: 'CNY', stock: 42, description: '细方格内页，方便整理课堂笔记。' },
  { id: 'EL-103', name: '折叠桌面支架', category: '数码', price: 39.90,
    currency: 'CNY', stock: 24, description: '可折叠收纳，适合桌面摆放手机。' },
  { id: 'LT-104', name: '随行保温杯', category: '日用', price: 69.00,
    currency: 'CNY', stock: 31, description: '旋盖式随行杯，适合日常出行。' },
  { id: 'DS-105', name: '抽绳帆布笔袋', category: '文具', price: 29.90,
    currency: 'CNY', stock: 26, description: '可放入多支笔和小尺子。' }
];

export class MockProductGateway implements ProductGateway {
  private readonly mode: LoadMode;

  constructor(mode: LoadMode) { this.mode = mode; }

  async list(): Promise<Product[]> {
    await new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, 900);
    });
    if (this.mode === LoadMode.Failure) {
      throw new Error('模拟请求失败（Mock 测试）');
    }
    if (this.mode === LoadMode.Empty) { return []; }
    return MOCK_PRODUCTS.slice();
  }
}
