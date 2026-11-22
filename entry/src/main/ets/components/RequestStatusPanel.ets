import { LoadStatus } from '../model/Product';

@Component
export struct RequestStatusPanel {
  @Prop status: LoadStatus = LoadStatus.Loading;
  @Prop errorText: string = '';
  @Prop retryLabel: string = '重新加载';
  @Prop cacheCount: number = 0;
  onRetry: () => void = (): void => {};
  onCache: () => void = (): void => {};

  build() {
    Column({ space: 9 }) {
      if (this.status === LoadStatus.Loading) {
        LoadingProgress().width(36).height(36).color('#245643');
        Text('正在加载 · Loading').fontWeight(FontWeight.Bold).fontSize(17);
        Text('请求已发起，请稍候…').fontSize(13).fontColor('#667A70');
      } else if (this.status === LoadStatus.Empty) {
        Text('没有商品 · Empty').fontWeight(FontWeight.Bold).fontSize(17);
        Text('本次返回了空数组，属于正常业务结果。').fontSize(12).fontColor('#667A70');
        Button(this.retryLabel).onClick((): void => { this.onRetry(); });
      } else if (this.status === LoadStatus.Failure) {
        Text('请求失败 · Error').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#B54B36');
        Text(this.errorText).fontSize(12).fontColor('#667A70');
        Button(this.retryLabel).onClick((): void => { this.onRetry(); });
        if (this.cacheCount > 0) {
          Button('查看离线缓存（' + this.cacheCount + '）')
            .onClick((): void => { this.onCache(); });
        }
      }
    }.width('100%').padding(24).backgroundColor('#FFFFFF').borderRadius(15);
  }
}
