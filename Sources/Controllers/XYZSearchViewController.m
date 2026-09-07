#import "XYZSearchViewController.h"
#import "XYZAPIClient.h"
#import "XYZModels.h"
#import "XYZJSONHelper.h"
#import "XYZPodcastCell.h"
#import "XYZEpisodeCell.h"
#import "XYZUIHelpers.h"
#import "XYZPodcastDetailViewController.h"
#import "XYZEpisodeDetailViewController.h"

@interface XYZSearchViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISegmentedControl *seg;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSDictionary *loadMoreKey;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, copy) NSString *keyword;
@end

@implementation XYZSearchViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.results = [NSMutableArray array];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, [XYZUIHelpers screenWidth], 44)];
    self.searchBar.placeholder = @"搜索节目或单集";
    self.searchBar.delegate = self;
    self.navigationItem.titleView = self.searchBar;

    self.seg = [[UISegmentedControl alloc] initWithItems:@[@"节目", @"单集"]];
    self.seg.frame = CGRectMake(12, 8, [XYZUIHelpers screenWidth] - 24, 30);
    self.seg.selectedSegmentIndex = 0;
    [self.seg addTarget:self action:@selector(segChanged) forControlEvents:UIControlEventValueChanged];

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [XYZUIHelpers screenWidth], 46)];
    [header addSubview:self.seg];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableHeaderView = header;
    self.tableView.rowHeight = 76;
    [self.tableView registerClass:[XYZPodcastCell class] forCellReuseIdentifier:@"pod"];
    [self.tableView registerClass:[XYZEpisodeCell class] forCellReuseIdentifier:@"ep"];
    [self.view addSubview:self.tableView];
}
- (NSString *)currentType {
    return self.seg.selectedSegmentIndex == 0 ? @"PODCAST" : @"EPISODE";
}
- (void)segChanged {
    if (self.keyword.length) [self performSearch:YES];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    self.keyword = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self performSearch:YES];
}
- (void)performSearch:(BOOL)reset {
    if (!self.keyword.length || self.loading) return;
    if (reset) { [self.results removeAllObjects]; self.loadMoreKey = nil; }
    self.loading = YES;
    __weak typeof(self) weakSelf = self;
    [[XYZAPIClient sharedClient] searchWithKeyword:self.keyword type:[self currentType] loadMoreKey:self.loadMoreKey success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        weakSelf.loading = NO;
        NSArray *raw = [XYZJSONHelper arrayFromResponse:json keys:@[@"data", @"items", @"list"]];
        if ([weakSelf.currentType isEqualToString:@"PODCAST"]) {
            for (NSDictionary *item in raw) {
                NSDictionary *d = item[@"podcast"] ?: item;
                if ([d isKindOfClass:[NSDictionary class]]) {
                    XYZPodcast *p = [XYZPodcast podcastWithDictionary:d];
                    if (p.pid.length) [weakSelf.results addObject:p];
                }
            }
        } else {
            [weakSelf.results addObjectsFromArray:[XYZEpisode episodesFromDataArray:raw]];
        }
        weakSelf.loadMoreKey = [XYZJSONHelper loadMoreKeyFromResponse:json];
        [weakSelf.tableView reloadData];
        if (weakSelf.results.count == 0) [XYZUIHelpers showToast:@"无结果" onView:weakSelf.view];
    } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
        weakSelf.loading = NO;
        [XYZUIHelpers showToast:error.localizedDescription ?: @"搜索失败" onView:weakSelf.view];
    }];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.results.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id obj = self.results[indexPath.row];
    if ([obj isKindOfClass:[XYZPodcast class]]) {
        XYZPodcastCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pod" forIndexPath:indexPath];
        [cell configureWithPodcast:obj];
        return cell;
    }
    XYZEpisodeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ep" forIndexPath:indexPath];
    [cell configureWithEpisode:obj];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id obj = self.results[indexPath.row];
    if ([obj isKindOfClass:[XYZPodcast class]]) {
        [self.navigationController pushViewController:[[XYZPodcastDetailViewController alloc] initWithPodcast:obj] animated:YES];
    } else {
        [self.navigationController pushViewController:[[XYZEpisodeDetailViewController alloc] initWithEpisode:obj] animated:YES];
    }
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.loadMoreKey && !self.loading) {
        if (scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - 100)
            [self performSearch:NO];
    }
}
@end
