import { hilog } from '@kit.PerformanceAnalysisKit';
import { DetailRequest, DetailResult, Product, formatPrice, validatedProduct } from '../model/Product';

@Builder
export function ProductDetailBuilder() {
  ProductDetail();
}

@Component
struct ProductDetail {
  private pathStack: NavPathStack | undefined = undefined;
  @State private item: Product | undefined = undefined;
  @State private favorite: boolean = false;
  @State private leaving: boolean = false;
  @State private message: string = '';

  private initialize(context: NavDestinationContext): void {
    this.pathStack = context.pathStack;
    this.leaving = false;
    this.item = undefined;
    const param = context.pathInfo.param as DetailRequest | undefined;
    if (!param || typeof param.id !== 'string' || typeof param.favorite !== 'boolean') {
      this.message = '详情参数不合法';
      hilog.warn(0, 'Lab07', '详情页面参数校验失败');
      return;
    }
    // 请求参数同时携带当前商品快照，避免页面直接发起网络请求。
    const request = context.pathInfo.param as DetailRequest;
    if (!request.product || !validatedProduct(request.product) || request.product.id !== param.id) {
      this.message = '商品内容不存在';
      return;
    }
    this.item = request.product;
    this.favorite = param.favorite;
    this.message = '';
  }

  private back(save: boolean): void {
    if (this.leaving || !this.pathStack || this.pathStack.size() === 0) { return; }
    this.leaving = true;
    if (save && this.item !== undefined) {
      this.pathStack.pop(new DetailResult(this.item.id, this.favorite));
    } else {
      this.pathStack.pop();
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 14 }) {
          if (this.item !== undefined) {
            Column({ space: 9 }) {
              Text(this.item.name).fontSize(25).fontWeight(FontWeight.Bold).fontColor('#1E3229');
              Text(this.item.category + ' · ' + this.item.id).fontSize(13).fontColor('#60746A');
              Text(formatPrice(this.item.price, this.item.currency)).fontSize(22).fontColor('#A34F29');
              Text('库存 ' + this.item.stock + ' 件').fontSize(13).fontColor('#60746A');
              Text(this.item.description).fontSize(14).fontColor('#1E3229');
            }.width('100%').alignItems(HorizontalAlign.Start)
              .padding(20).backgroundColor('#FFFFFF').borderRadius(16);
            Row() {
              Text('收藏商品（重启保留）').layoutWeight(1).fontSize(15);
              Toggle({ type: ToggleType.Switch, isOn: this.favorite })
                .selectedColor('#245643')
                .onChange((value: boolean): void => { this.favorite = value; });
            }.width('100%').padding(14).backgroundColor('#DCEDE1').borderRadius(14);
            Button('保存收藏并返回').width('100%').backgroundColor('#245643')
              .enabled(!this.leaving).onClick((): void => { this.back(true); });
            Button('不保存直接返回').width('100%').fontColor('#245643').backgroundColor('#FFFFFF')
              .enabled(!this.leaving).onClick((): void => { this.back(false); });
          } else {
            Text(this.message).fontSize(18).fontColor('#B44B37');
            Button('返回列表').onClick((): void => { this.back(false); });
          }
        }.width('100%').padding(16);
      }.width('100%').height('100%');
    }.title('商品详情').backgroundColor('#F4F7F2')
      .onReady((context: NavDestinationContext): void => { this.initialize(context); });
  }
}
