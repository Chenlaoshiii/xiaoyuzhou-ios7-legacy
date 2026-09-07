#import "XYZSubscriptionViewController.h"
#import "XYZAPIClient.h"
#import "XYZModels.h"
#import "XYZJSONHelper.h"
#import "XYZPodcastCell.h"
#import "XYZUIHelpers.h"
#import "XYZPodcastDetailViewController.h"

@interface XYZSubscriptionViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *podcasts;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSDictionary *loadMoreKey;
@property (nonatomic, assign) BOOL loading;
@end

@implementation XYZSubscriptionViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.podcasts = [NSMutableArray array];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 76;
    [self.tableView registerClass:[XYZPodcastCell class] forCellReuseIdentifier:@"pod"];
    [self.view addSubview:self.tableView];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.podcasts.count == 0) [self reload];
}
- (void)reload {
    self.loadMoreKey = nil;
    [self.podcasts removeAllObjects];
    [self loadMore];
}
- (void)loadMore {
    if (self.loading) return;
    self.loading = YES;
    __weak typeof(self) weakSelf = self;
    [[XYZAPIClient sharedClient] fetchSubscriptionsWithLoadMoreKey:self.loadMoreKey success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        weakSelf.loading = NO;
        [weakSelf.refreshControl endRefreshing];
        NSArray *raw = [XYZJSONHelper arrayFromResponse:json keys:@[@"data", @"list", @"items"]];
        for (NSDictionary *item in raw) {
            NSDictionary *d = item[@"podcast"] ?: item;
            if ([d isKindOfClass:[NSDictionary class]]) {
                XYZPodcast *p = [XYZPodcast podcastWithDictionary:d];
                p.subscribed = YES;
                if (p.pid.length) [weakSelf.podcasts addObject:p];
            }
        }
        weakSelf.loadMoreKey = [XYZJSONHelper loadMoreKeyFromResponse:json];
        [weakSelf.tableView reloadData];
        if (weakSelf.podcasts.count == 0) [XYZUIHelpers showToast:@"还没有订阅" onView:weakSelf.view];
    } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
        weakSelf.loading = NO;
        [weakSelf.refreshControl endRefreshing];
        [XYZUIHelpers showToast:error.localizedDescription ?: @"加载失败" onView:weakSelf.view];
    }];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.podcasts.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XYZPodcastCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pod" forIndexPath:indexPath];
    [cell configureWithPodcast:self.podcasts[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    XYZPodcastDetailViewController *vc = [[XYZPodcastDetailViewController alloc] initWithPodcast:self.podcasts[indexPath.row]];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.loadMoreKey && !self.loading) {
        if (scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - 100)
            [self loadMore];
    }
}
@end
