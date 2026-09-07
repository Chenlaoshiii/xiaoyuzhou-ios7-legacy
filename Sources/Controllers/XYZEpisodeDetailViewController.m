#import "XYZEpisodeDetailViewController.h"
#import "XYZAPIClient.h"
#import "XYZJSONHelper.h"
#import "XYZCommentCell.h"
#import "XYZImageCache.h"
#import "XYZUIHelpers.h"
#import "XYZPlayerManager.h"
#import "XYZPlayerViewController.h"

@interface XYZEpisodeDetailViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) XYZEpisode *episode;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) NSDictionary *loadMoreKey;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UITextView *notesView;
@end

@implementation XYZEpisodeDetailViewController
- (instancetype)initWithEpisode:(XYZEpisode *)episode {
    self = [super init];
    if (self) _episode = episode;
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"单集";
    self.comments = [NSMutableArray array];
    self.view.backgroundColor = [UIColor whiteColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[XYZCommentCell class] forCellReuseIdentifier:@"cmt"];
    [self.view addSubview:self.tableView];

    [self buildHeader];
    [self loadDetail];
    [self loadComments:YES];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"播放" style:UIBarButtonItemStylePlain target:self action:@selector(play)];
}
- (void)buildHeader {
    CGFloat w = [XYZUIHelpers screenWidth];
    UIView *h = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 280)];
    UIImageView *cover = [[UIImageView alloc] initWithFrame:CGRectMake((w-100)/2, 16, 100, 100)];
    cover.layer.cornerRadius = 8;
    cover.clipsToBounds = YES;
    cover.tag = 200;
    [h addSubview:cover];
    [[XYZImageCache sharedCache] loadImageURL:self.episode.coverURL intoImageView:cover placeholder:[XYZUIHelpers placeholderCover]];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 128, w-32, 44)];
    title.font = [UIFont boldSystemFontOfSize:16];
    title.numberOfLines = 2;
    title.textAlignment = NSTextAlignmentCenter;
    title.text = self.episode.title;
    title.tag = 201;
    [h addSubview:title];

    UILabel *meta = [[UILabel alloc] initWithFrame:CGRectMake(16, 174, w-32, 18)];
    meta.font = [UIFont systemFontOfSize:12];
    meta.textColor = [XYZUIHelpers textSecondary];
    meta.textAlignment = NSTextAlignmentCenter;
    meta.text = [NSString stringWithFormat:@"%@ · %@", self.episode.podcastTitle ?: @"", [XYZUIHelpers formatDuration:self.episode.duration]];
    meta.tag = 202;
    [h addSubview:meta];

    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playBtn.frame = CGRectMake((w-140)/2, 200, 140, 36);
    [playBtn setTitle:@"▶ 立即播放" forState:UIControlStateNormal];
    [XYZUIHelpers stylePrimaryButton:playBtn];
    [playBtn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    [h addSubview:playBtn];

    self.notesView = [[UITextView alloc] initWithFrame:CGRectMake(12, 248, w-24, 80)];
    self.notesView.editable = NO;
    self.notesView.scrollEnabled = NO;
    self.notesView.font = [UIFont systemFontOfSize:13];
    self.notesView.textColor = [XYZUIHelpers textPrimary];
    self.notesView.backgroundColor = [UIColor clearColor];
    self.notesView.text = self.episode.shownotes.length ? self.episode.shownotes : self.episode.descriptionText;
    [h addSubview:self.notesView];

    // size notes
    CGSize sz = [self.notesView sizeThatFits:CGSizeMake(w-24, CGFLOAT_MAX)];
    CGRect nf = self.notesView.frame;
    nf.size.height = MIN(sz.height, 200);
    self.notesView.frame = nf;
    CGRect hf = h.frame;
    hf.size.height = CGRectGetMaxY(self.notesView.frame) + 12;
    h.frame = hf;

    // add section label via table section instead
    self.headerView = h;
    self.tableView.tableHeaderView = h;
}
- (void)resizeHeader {
    CGFloat w = [XYZUIHelpers screenWidth];
    CGSize sz = [self.notesView sizeThatFits:CGSizeMake(w-24, CGFLOAT_MAX)];
    CGRect nf = self.notesView.frame;
    nf.size.height = MIN(MAX(sz.height, 40), 220);
    self.notesView.frame = nf;
    CGRect hf = self.headerView.frame;
    hf.size.height = CGRectGetMaxY(self.notesView.frame) + 16;
    self.headerView.frame = hf;
    self.tableView.tableHeaderView = self.headerView;
}
- (void)loadDetail {
    __weak typeof(self) weakSelf = self;
    [[XYZAPIClient sharedClient] fetchEpisodeWithEid:self.episode.eid success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        XYZEpisode *e = [XYZEpisode episodeWithDictionary:json];
        if (e.eid.length) {
            weakSelf.episode = e;
            UILabel *title = (UILabel *)[weakSelf.headerView viewWithTag:201];
            UILabel *meta = (UILabel *)[weakSelf.headerView viewWithTag:202];
            UIImageView *cover = (UIImageView *)[weakSelf.headerView viewWithTag:200];
            title.text = e.title;
            meta.text = [NSString stringWithFormat:@"%@ · %@", e.podcastTitle ?: @"", [XYZUIHelpers formatDuration:e.duration]];
            weakSelf.notesView.text = e.shownotes.length ? e.shownotes : e.descriptionText;
            [[XYZImageCache sharedCache] loadImageURL:e.coverURL intoImageView:cover placeholder:[XYZUIHelpers placeholderCover]];
            [weakSelf resizeHeader];
        }
    } failure:nil];
}
- (void)loadComments:(BOOL)reset {
    if (self.loading) return;
    if (reset) { [self.comments removeAllObjects]; self.loadMoreKey = nil; }
    self.loading = YES;
    __weak typeof(self) weakSelf = self;
    [[XYZAPIClient sharedClient] fetchCommentsForEid:self.episode.eid order:@"HOT" loadMoreKey:self.loadMoreKey success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        weakSelf.loading = NO;
        NSArray *raw = [XYZJSONHelper arrayFromResponse:json keys:@[@"data", @"list", @"items"]];
        [weakSelf.comments addObjectsFromArray:[XYZComment commentsFromDataArray:raw]];
        weakSelf.loadMoreKey = [XYZJSONHelper loadMoreKeyFromResponse:json];
        [weakSelf.tableView reloadData];
    } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
        weakSelf.loading = NO;
    }];
}
- (void)play {
    [[XYZPlayerManager sharedManager] playEpisode:self.episode];
    XYZPlayerViewController *pvc = [[XYZPlayerViewController alloc] init];
    [self.navigationController pushViewController:pvc animated:YES];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @"评论"; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.comments.count; }
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [XYZCommentCell heightForComment:self.comments[indexPath.row] width:tableView.bounds.size.width];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XYZCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cmt" forIndexPath:indexPath];
    [cell configureWithComment:self.comments[indexPath.row]];
    return cell;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.loadMoreKey && !self.loading) {
        if (scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - 100)
            [self loadComments:NO];
    }
}
@end
