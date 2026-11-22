import { common } from '@kit.AbilityKit';
import { ProductList } from '../components/ProductList';
import { SourceSwitcher } from '../components/SourceSwitcher';
import { RequestStatusPanel } from '../components/RequestStatusPanel';
import { Product, DetailRequest, DetailResult, DETAIL_ROUTE, LoadMode, LoadStatus } from '../model/Product';
import { CatalogStore, CatalogSnapshot } from '../state/CatalogStore';

@Entry
@Component
struct Index {
  private readonly catalogStore: CatalogStore = new CatalogStore();
  private readonly pathStack: NavPathStack = new NavPathStack();
  private readonly tabs: TabsController = new TabsController();
  private initialized: boolean = false;

  @State private view: CatalogSnapshot = new CatalogSnapshot();
  @State private selectedTab: number = 0;

  aboutToAppear(): void {
    if (this.initialized) { return; }
    this.initialized = true;
    this.bootstrap();
  }

  private context(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private async bootstrap(): Promise<void> {
    this.view = await this.catalogStore.restore(this.context());
    // 首次启动默认 Mock；公网请求必须由用户主动发起。
    await this.fetch(LoadMode.Sample);
  }

  private async fetch(mode: LoadMode): Promise<void> {
    await this.catalogStore.load(this.context(), mode, (state: CatalogSnapshot): void => {
      this.view = state;
    });
  }

  private openDetail(item: Product): void {
    if (this.pathStack.size() > 0) { return; }
    const options: Product[] = this.selectedTab === 0
      ? this.catalogStore.visible(this.view) : this.catalogStore.saved(this.view);
    if (!options.some((p: Product): boolean => p.id === item.id)) { return; }
    const param = new DetailRequest(item.id, this.view.favorites.includes(item.id), item);
    this.pathStack.pushPathByName(DETAIL_ROUTE, param, (info: PopInfo): void => {
      const result = info.result as DetailResult | undefined;
      if (!result || result.id !== item.id || typeof result.favorite !== 'boolean') { return; }
      this.commitFavorite(result);
    });
  }

  private async commitFavorite(result: DetailResult): Promise<void> {
    this.view = await this.catalogStore.changeFavorite(this.context(), result);
  }

  @Builder
  private header() {
    Column({ space: 6 }) {
      Text('LAB 07 · ARKTS').fontSize(11).letterSpacing(2).fontColor('#C2DFCE');
      Text('商品服务台').fontSize(26).fontWeight(FontWeight.Bold).fontColor('#FFFFFF');
      Text('页面 / 组件 / 状态 / 服务 · 四层架构').fontSize(12).fontColor('#E0EFE6');
    }.width('100%').alignItems(HorizontalAlign.Start)
      .padding(18).backgroundColor('#245643').borderRadius(18);
  }

  @Builder
  private catalogPage() {
    Scroll() {
      Column({ space: 13 }) {
        this.header();
        SourceSwitcher({
          currentMode: this.view.mode,
          onChoose: (mode: LoadMode): void => { this.fetch(mode); }
        });
        if (this.view.status !== LoadStatus.Success) {
          RequestStatusPanel({
            status: this.view.status,
            errorText: this.view.errorText,
            retryLabel: this.view.mode === LoadMode.Network ? '重试真实网络' : '重新加载 Mock',
            cacheCount: this.view.cached.length,
            onRetry: (): void => {
              this.fetch(this.view.mode === LoadMode.Network ? LoadMode.Network : LoadMode.Sample);
            },
            onCache: (): void => { this.view = this.catalogStore.showCache(); }
          });
        } else {
          Column({ space: 10 }) {
            Row() {
              Text('加载成功 · Success').fontWeight(FontWeight.Bold).fontColor('#245643');
              Text(this.view.origin).fontSize(11).fontColor('#60746A');
            }.width('100%').justifyContent(FlexAlign.SpaceBetween);
            TextInput({ text: this.view.query, placeholder: '搜索名称、分类或编号' })
              .height(43).backgroundColor('#F2F6F1')
              .onChange((text: string): void => { this.view = this.catalogStore.updateQuery(text); });
            Text('筛选结果：' + this.catalogStore.visible(this.view).length + ' 件')
              .fontSize(12).fontColor('#60746A');
            if (this.catalogStore.visible(this.view).length === 0) {
              Text('没有匹配的商品。').fontSize(13).fontColor('#60746A').padding(14);
            } else {
              ProductList({
                items: this.catalogStore.visible(this.view), favorites: this.view.favorites,
                onSelect: (item: Product): void => { this.openDetail(item); }
              });
            }
          }.width('100%');
        }
        if (this.view.actionText.length > 0) {
          Text(this.view.actionText).fontSize(13).fontColor('#245643');
        }
        Text(this.view.persistenceText).fontSize(12).fontColor('#60746A');
        Text('真实网络与 Mock 数据已明确区分；本地不记录账号密码或 Token。')
          .fontSize(11).fontColor('#60746A');
      }.width('100%').padding(16);
    }.width('100%').height('100%').scrollBar(BarState.Off);
  }

  @Builder
  private favoritePage() {
    Scroll() {
      Column({ space: 13 }) {
        this.header();
        Text('我的收藏 · ' + this.view.favorites.length + ' 件')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#20382D');
        Text('收藏经过 Preferences.put + flush 保存，可在重启后读取。')
          .fontSize(12).fontColor('#60746A');
        if (this.catalogStore.saved(this.view).length === 0) {
          Text('还没有可显示的收藏商品。')
            .width('100%').padding(18).backgroundColor('#FFFFFF').borderRadius(13);
        } else {
          ProductList({
            items: this.catalogStore.saved(this.view), favorites: this.view.favorites,
            onSelect: (item: Product): void => { this.openDetail(item); }
          });
        }
        Button('返回商品列表').backgroundColor('#245643').onClick((): void => {
          this.tabs.changeIndex(0);
        });
        Text(this.view.actionText).fontSize(12).fontColor('#60746A');
      }.width('100%').padding(16);
    }.width('100%').height('100%').scrollBar(BarState.Off);
  }

  build() {
    Navigation(this.pathStack) {
      Tabs({ barPosition: BarPosition.End, index: this.selectedTab, controller: this.tabs }) {
        TabContent() { this.catalogPage(); }.tabBar('商品');
        TabContent() { this.favoritePage(); }.tabBar('收藏');
      }.width('100%').height('100%').barHeight(56)
        .barBackgroundColor('#FFFFFF').scrollable(false)
        .onChange((index: number): void => { this.selectedTab = index; });
    }.width('100%').height('100%').hideTitleBar(true)
      .mode(NavigationMode.Stack).backgroundColor('#F4F7F2');
  }
}
