import { LoadMode } from '../model/Product';

@Component
export struct SourceSwitcher {
  @Prop currentMode: LoadMode = LoadMode.Sample;
  onChoose: (mode: LoadMode) => void = (_mode: LoadMode): void => {};

  build() {
    Column({ space: 9 }) {
      Text('数据源与状态验证').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#20382D');
      Row({ space: 6 }) {
        Button('真实网络').onClick((): void => { this.onChoose(LoadMode.Network); });
        Button('Mock 商品').onClick((): void => { this.onChoose(LoadMode.Sample); });
      }
      Row({ space: 6 }) {
        Button('空列表').onClick((): void => { this.onChoose(LoadMode.Empty); });
        Button('模拟失败').onClick((): void => { this.onChoose(LoadMode.Failure); });
      }
      Text('当前模式：' + (this.currentMode === LoadMode.Network ? '真实网络' : 'Mock 测试'))
        .fontSize(12).fontColor('#245643')
      Text('Mock、空列表与模拟失败均为本地测试；真实网络使用公开 HTTPS 接口。')
        .fontSize(11).fontColor('#667A70');
    }.width('100%').alignItems(HorizontalAlign.Start)
      .padding(13).backgroundColor('#FFFFFF').borderRadius(15);
  }
}
