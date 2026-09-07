#import "XYZPodcastDetailViewController.h"
#import "XYZAPIClient.h"
#import "XYZJSONHelper.h"
#import "XYZEpisodeCell.h"
#import "XYZImageCache.h"
#import "XYZUIHelpers.h"
#import "XYZEpisodeDetailViewController.h"

@interface XYZPodcastDetailViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) XYZPodcast *podcast;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *episodes;
@property (nonatomic, strong) NSDictionary *loadMoreKey;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, strong) UIButton *subBtn;
@property (nonatomic, strong) UIView *headerView;
@end

@implementation XYZPodcastDetailViewController
- (instancetype)initWithPodcast:(XYZPodcast *)podcast {
    self = [super init];
    if (self) _podcast = podcast;
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.podcast.title.length ? self.podcast.title : @"节目";
    self.episodes = [NSMutableArray array];
    self.view.backgroundColor = [UIColor whiteColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 72;
    [self.tableView registerClass:[XYZEpisodeCell class] forCellReuseIdentifier:@"ep"];
    [self.view addSubview:self.tableView];

    [self buildHeader];
    [self loadDetail];
    [self loadEpisodes:YES];
}
- (void)buildHeader {
    CGFloat w = [XYZUIHelpers screenWidth];
    UIView *h = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 170)];
    h.backgroundColor = [XYZUIHelpers bgGray];
    UIImageView *cover = [[UIImageView alloc] initWithFrame:CGRectMake(16, 16, 90, 90)];
    cover.layer.cornerRadius = 8;
    cover.clipsToBounds = YES;
    cover.tag = 100;
    [h addSubview:cover];
    [[XYZImageCache sharedCache] loadImageURL:self.podcast.coverURL intoImageView:cover placeholder:[XYZUIHelpers placeholderCover]];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(120, 16, w - 136, 40)];
    title.font = [UIFont boldSystemFontOfSize:16];
    title.numberOfLines = 2;
    title.text = self.podcast.title;
    title.tag = 101;
    [h addSubview:title];

    UILabel *author = [[UILabel alloc] initWithFrame:CGRectMake(120, 58, w - 136, 18)];
    author.font = [UIFont systemFontOfSize:12];
    author.textColor = [XYZUIHelpers textSecondary];
    author.text = self.podcast.author;
    author.tag = 102;
    [h addSubview:author];

    self.subBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.subBtn.frame = CGRectMake(120, 84, 100, 32);
    [self updateSubButton];
    [self.subBtn addTarget:self action:@selector(toggleSub) forControlEvents:UIControlEventTouchUpInside];
    [h addSubview:self.subBtn];

    UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(16, 118, w - 32, 44)];
    desc.font = [UIFont systemFontOfSize:12];
    desc.textColor = [XYZUIHelpers textSecondary];
    desc.numberOfLines = 3;
    desc.text = self.podcast.descriptionText.length ? self.podcast.descriptionText : self.podcast.brief;
    desc.tag = 103;
    [h addSubview:desc];

    self.headerView = h;
    self.tableView.tableHeaderView = h;
}
- (void)updateSubButton {
    BOOL on = self.podcast.subscribed;
    [self.subBtn setTitle:on ? @"已订阅" : @"+ 订阅" forState:UIControlStateNormal];
    self.subBtn.backgroundColor = on ? [UIColor lightGrayColor] : [XYZUIHelpers brandGreen];
    self.subBtn.layer.cornerRadius = 4;
    [self.subBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.subBtn.titleLabel.font = [UIFont systemFontOfSize:14];
}
- (void)toggleSub {
    NSString *mode = self.podcast.subscribed ? @"OFF" : @"ON";
    __weak typeof(self) weakSelf = self;
    [[XYZAPIClient sharedClient] updateSubscriptionPid:self.podcast.pid mode:mode success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        weakSelf.podcast.subscribed = !weakSelf.podcast.subscribed;
        [weakSelf updateSubButton];
        [XYZUIHelpers showToast:weakSelf.podcast.subscribed ? @"已订阅" : @"已取消订阅" onView:weakSelf.view];
    } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
        [XYZUIHelpers showToast:error.localizedDescription ?: @"操作失败" onView:weakSelf.view];
    }];
}
- (void)loadDetail {
    __weak typeof(self) weakSelf = self;
    [[XYZAPIClient sharedClient] fetchPodcastWithPid:self.podcast.pid success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        XYZPodcast *p = [XYZPodcast podcastWithDictionary:json];
        if (p.pid.length) {
            weakSelf.podcast = p;
            weakSelf.title = p.title;
            UIImageView *cover = (UIImageView *)[weakSelf.headerView viewWithTag:100];
            UILabel *title = (UILabel *)[weakSelf.headerView viewWithTag:101];
            UILabel *author = (UILabel *)[weakSelf.headerView viewWithTag:102];
            UILabel *desc = (UILabel *)[weakSelf.headerView viewWithTag:103];
            title.text = p.title;
            author.text = p.author;
            desc.text = p.descriptionText.length ? p.descriptionText : p.brief;
            [[XYZImageCache sharedCache] loadImageURL:p.coverURL intoImageView:cover placeholder:[XYZUIHelpers placeholderCover]];
            [weakSelf updateSubButton];
        }
    } failure:nil];
}
- (void)loadEpisodes:(BOOL)reset {
    if (self.loading) return;
    if (reset) { [self.episodes removeAllObjects]; self.loadMoreKey = nil; }
    self.loading = YES;
    __weak typeof(self) weakSelf = self;
    [[XYZAPIClient sharedClient] fetchEpisodeListWithPid:self.podcast.pid order:@"desc" loadMoreKey:self.loadMoreKey success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        weakSelf.loading = NO;
        NSArray *raw = [XYZJSONHelper arrayFromResponse:json keys:@[@"data", @"list", @"items"]];
        NSArray *eps = [XYZEpisode episodesFromDataArray:raw];
        for (XYZEpisode *e in eps) {
            if (!e.podcastTitle.length) e.podcastTitle = weakSelf.podcast.title;
            if (!e.coverURL.length) e.coverURL = weakSelf.podcast.coverURL;
            if (!e.pid.length) e.pid = weakSelf.podcast.pid;
        }
        [weakSelf.episodes addObjectsFromArray:eps];
        weakSelf.loadMoreKey = [XYZJSONHelper loadMoreKeyFromResponse:json];
        [weakSelf.tableView reloadData];
    } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
        weakSelf.loading = NO;
        [XYZUIHelpers showToast:error.localizedDescription ?: @"单集加载失败" onView:weakSelf.view];
    }];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.episodes.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XYZEpisodeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ep" forIndexPath:indexPath];
    [cell configureWithEpisode:self.episodes[indexPath.row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:[[XYZEpisodeDetailViewController alloc] initWithEpisode:self.episodes[indexPath.row]] animated:YES];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.loadMoreKey && !self.loading) {
        if (scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - 100)
            [self loadEpisodes:NO];
    }
}
@end
