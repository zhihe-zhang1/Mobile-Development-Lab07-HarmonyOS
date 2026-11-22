import { Product, formatPrice } from '../model/Product';

@Component
export struct ProductList {
  @Prop items: Product[] = [];
  @Prop favorites: string[] = [];
  onSelect: (item: Product) => void = (_item: Product): void => {};

  build() {
    Column({ space: 8 }) {
      ForEach(this.items, (item: Product) => {
        Row({ space: 12 }) {
          Text(item.name.substring(0, 1)).width(46).height(46)
            .textAlign(TextAlign.Center).fontSize(21).fontColor('#245643')
            .backgroundColor('#DCEDE1').borderRadius(13);
          Column({ space: 5 }) {
            Text(item.name).fontSize(15).fontWeight(FontWeight.Medium)
              .fontColor('#1E3229').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
            Text(item.category + ' · ' + item.id).fontSize(12).fontColor('#60746A');
          }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          Column({ space: 5 }) {
            Text(formatPrice(item.price, item.currency)).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#A34F29');
            if (this.favorites.includes(item.id)) {
              Text('已收藏').fontSize(11).fontColor('#245643');
            }
          }.alignItems(HorizontalAlign.End);
          Text('›').fontSize(21).fontColor('#60746A');
        }.padding(12).width('100%').backgroundColor('#FFFFFF').borderRadius(14)
          .onClick((): void => { this.onSelect(item); });
      }, (item: Product): string => item.id);
    }.width('100%');
  }
}
