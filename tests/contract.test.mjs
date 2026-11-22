import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const get = (name) => fs.readFileSync(path.join(root, name), 'utf8');
const exists = (name) => assert.ok(fs.existsSync(path.join(root, name)), `缺少文件：${name}`);
const prefix = 'entry/src/main/ets/';
const layers = {
  pages: ['Index.ets', 'ProductDetail.ets'],
  components: ['ProductList.ets', 'SourceSwitcher.ets', 'RequestStatusPanel.ets'],
  state: ['CatalogStore.ets', 'ProductPreferences.ets'],
  service: ['ProductService.ets', 'ProductGateway.ets', 'HttpClient.ets', 'HttpProductGateway.ets', 'MockProductGateway.ets']
};

for (const [layer, files] of Object.entries(layers)) {
  for (const file of files) exists(`${prefix}${layer}/${file}`);
}
exists(`${prefix}model/Product.ets`);

const route = JSON.parse(get('entry/src/main/resources/base/profile/router_map.json'));
assert.equal(route.routerMap.find(r => r.name === 'ProductDetail')?.buildFunction, 'ProductDetailBuilder');
const moduleConfig = get('entry/src/main/module.json5');
assert.match(moduleConfig, /ohos\.permission\.INTERNET/);
assert.match(moduleConfig, /\$profile:router_map/);

const mock = JSON.parse(get('contracts/mock-products.json'));
assert.equal(mock.source, 'local-mock');
assert.equal(mock.products.length, 5);
const ids = new Set();
for (const p of mock.products) {
  assert.equal(typeof p.id, 'string');
  assert.equal(typeof p.name, 'string');
  assert.equal(typeof p.category, 'string');
  assert.equal(p.currency, 'CNY');
  assert.ok(Number.isFinite(p.price) && p.price >= 0);
  assert.ok(Number.isInteger(p.stock) && p.stock >= 0);
  assert.equal(typeof p.description, 'string');
  assert.ok(!ids.has(p.id), '商品编号必须唯一');
  ids.add(p.id);
}

const mockCode = get(`${prefix}service/MockProductGateway.ets`);
for (const p of mock.products) {
  assert.ok(mockCode.includes(p.id), `Mock 实现遗漏 ${p.id}`);
  assert.ok(mockCode.includes(p.name), `Mock 实现遗漏 ${p.name}`);
}
const gateway = get(`${prefix}service/ProductGateway.ets`);
assert.match(gateway, /list\(\): Promise<Product\[\]>/);
const store = get(`${prefix}state/CatalogStore.ets`);
assert.match(store, /request !== this\.generation/);
assert.match(store, /saveFavorites\(context, ids\)/);
assert.match(get(`${prefix}state/ProductPreferences.ets`), /await db\.flush\(\)/);
assert.match(get(`${prefix}service/HttpProductGateway.ets`), /products\?limit=12/);
for (const doc of ['01-需求分析.md','02-系统架构.md','03-接口文档.md',
  '04-原型设计.md','05-团队协作与评审.md','06-测试计划.md',
  '07-答辩材料.md','08-工程伦理与引用.md','09-打包与交付.md']) {
  exists(`docs/${doc}`);
}
console.log('PASS：四层代码、导航映射、Mock 数据契约、存储、文档静态检查');
console.log('注意：该检查未编译 ArkTS，也未执行 HarmonyOS 设备测试。');
