export const DETAIL_ROUTE: string = 'ProductDetail';

export interface Product {
  id: string;
  name: string;
  category: string;
  price: number;
  currency: string;
  stock: number;
  description: string;
}

export class DetailRequest {
  id: string;
  favorite: boolean;
  product: Product;
  constructor(id: string, favorite: boolean, product: Product) {
    this.id = id;
    this.favorite = favorite;
    this.product = product;
  }
}

export class DetailResult {
  id: string;
  favorite: boolean;
  constructor(id: string, favorite: boolean) {
    this.id = id;
    this.favorite = favorite;
  }
}

export enum LoadMode { Network = 0, Sample = 1, Empty = 2, Failure = 3 }
export enum LoadStatus { Loading = 0, Success = 1, Empty = 2, Failure = 3 }

export function filterProducts(items: Product[], text: string): Product[] {
  const keyword = text.trim().toLowerCase();
  if (!keyword) { return items; }
  return items.filter((item: Product): boolean =>
    item.name.toLowerCase().includes(keyword) ||
    item.category.toLowerCase().includes(keyword) ||
    item.id.toLowerCase().includes(keyword));
}

export function formatPrice(price: number, currency: string): string {
  const symbol = currency === 'USD' ? '$ ' : '¥ ';
  return symbol + price.toFixed(2);
}

export function validatedProduct(value: Product): boolean {
  if (value === null || typeof value !== 'object') { return false; }
  return typeof value.id === 'string' && typeof value.name === 'string' &&
    typeof value.category === 'string' && typeof value.currency === 'string' &&
    (value.currency === 'USD' || value.currency === 'CNY') && typeof value.description === 'string' &&
    typeof value.price === 'number' && Number.isFinite(value.price) &&
    typeof value.stock === 'number' && Number.isFinite(value.stock);
}
