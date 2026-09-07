#import "XYZHomeViewController.h"
#import "XYZAPIClient.h"
#import "XYZModels.h"
#import "XYZJSONHelper.h"
#import "XYZEpisodeCell.h"
#import "XYZPodcastCell.h"
#import "XYZUIHelpers.h"
#import "XYZEpisodeDetailViewController.h"
#import "XYZPodcastDetailViewController.h"
#import "XYZAuthManager.h"

@interface XYZHomeViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *items; // mix of podcast/episode
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, copy) NSString *loadMoreKey;
@property (nonatomic, assign) BOOL loading;
@end

@implementation XYZHomeViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [XYZUIHelpers bgGray];
    self.items = [NSMutableArray array];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 76;
    [self.tableView registerClass:[XYZEpisodeCell class] forCellReuseIdentifier:@"ep"];
    [self.tableView registerClass:[XYZPodcastCell class] forCellReuseIdentifier:@"pod"];
    [self.view addSubview:self.tableView];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = self.view.center;
    [self.view addSubview:self.spinner];

    [self reload];
}
- (void)reload {
    self.loadMoreKey = nil;
    [self.items removeAllObjects];
    [self loadMore];
}
- (void)loadMore {
    if (self.loading) return;
    self.loading = YES;
    if (!self.refreshControl.refreshing) [self.spinner startAnimating];
    __weak typeof(self) weakSelf = self;
    [[XYZAPIClient sharedClient] fetchDiscoveryWithLoadMoreKey:self.loadMoreKey success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        [weakSelf.spinner stopAnimating];
        [weakSelf.refreshControl endRefreshing];
        weakSelf.loading = NO;
        NSArray *raw = [XYZJSONHelper arrayFromResponse:json keys:@[@"data", @"items", @"list"]];
        // discovery feed: array of sections or items
        for (id section in raw) {
            if (![section isKindOfClass:[NSDictionary class]]) continue;
            NSArray *inner = nil;
            if ([section[@"data"] isKindOfClass:[NSArray class]]) inner = section[@"data"];
            else if ([section[@"items"] isKindOfClass:[NSArray class]]) inner = section[@"items"];
            else if (section[@"episode"] || section[@"podcast"] || section[@"eid"] || section[@"pid"]) {
                inner = @[section];
            }
            if (!inner) continue;
            for (NSDictionary *item in inner) {
                if (![item isKindOfClass:[NSDictionary class]]) continue;
                if (item[@"episode"] || item[@"eid"] || [item[@"type"] isEqual:@"EPISODE"]) {
                    XYZEpisode *e = [XYZEpisode episodeWithDictionary:item];
                    if (e.eid.length) [weakSelf.items addObject:e];
                } else if (item[@"podcast"] || item[@"pid"] || [item[@"type"] isEqual:@"PODCAST"]) {
                    NSDictionary *pd = item[@"podcast"] ?: item;
                    XYZPodcast *p = [XYZPodcast podcastWithDictionary:pd];
                    if (p.pid.length) [weakSelf.items addObject:p];
                }
            }
        }
        // also handle flat episode lists
        if (weakSelf.items.count == 0) {
            NSArray *eps = [XYZEpisode episodesFromDataArray:raw];
            [weakSelf.items addObjectsFromArray:eps];
        }
        id lm = json[@"loadMoreKey"];
        if (!lm && [json[@"data"] isKindOfClass:[NSDictionary class]]) lm = json[@"data"][@"loadMoreKey"];
        if ([lm isKindOfClass:[NSString class]]) weakSelf.loadMoreKey = lm;
        else if ([lm isKindOfClass:[NSNumber class]]) weakSelf.loadMoreKey = [lm stringValue];
        else weakSelf.loadMoreKey = nil;
        [weakSelf.tableView reloadData];
        if (weakSelf.items.count == 0) {
            [XYZUIHelpers showToast:@"暂无内容，下拉刷新" onView:weakSelf.view];
        }
    } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
        [weakSelf.spinner stopAnimating];
        [weakSelf.refreshControl endRefreshing];
        weakSelf.loading = NO;
        if (statusCode == 401) {
            [[XYZAuthManager sharedManager] refreshIfNeededWithCompletion:^(BOOL ok) {
                if (ok) [weakSelf reload];
                else [XYZUIHelpers showToast:@"请重新登录" onView:weakSelf.view];
            }];
            return;
        }
        [XYZUIHelpers showToast:error.localizedDescription ?: @"加载失败" onView:weakSelf.view];
    }];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.items.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id obj = self.items[indexPath.row];
    if ([obj isKindOfClass:[XYZEpisode class]]) {
        XYZEpisodeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ep" forIndexPath:indexPath];
        [cell configureWithEpisode:obj];
        return cell;
    } else {
        XYZPodcastCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pod" forIndexPath:indexPath];
        [cell configureWithPodcast:obj];
        return cell;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id obj = self.items[indexPath.row];
    if ([obj isKindOfClass:[XYZEpisode class]]) {
        XYZEpisodeDetailViewController *vc = [[XYZEpisodeDetailViewController alloc] initWithEpisode:obj];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([obj isKindOfClass:[XYZPodcast class]]) {
        XYZPodcastDetailViewController *vc = [[XYZPodcastDetailViewController alloc] initWithPodcast:obj];
        [self.navigationController pushViewController:vc animated:YES];
    }
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.loadMoreKey.length && !self.loading) {
        CGFloat offset = scrollView.contentOffset.y + scrollView.bounds.size.height;
        if (offset > scrollView.contentSize.height - 120) [self loadMore];
    }
}
@end
