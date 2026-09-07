#import "XYZMiniPlayerView.h"
#import "XYZPlayerManager.h"
#import "XYZImageCache.h"
#import "XYZUIHelpers.h"
#import "XYZPlayerViewController.h"

@interface XYZMiniPlayerView ()
@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *playButton;
@end

@implementation XYZMiniPlayerView
+ (CGFloat)preferredHeight { return 48.0; }
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.98 alpha:0.98];
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.12;
        self.layer.shadowOffset = CGSizeMake(0, -1);
        _coverView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 6, 36, 36)];
        _coverView.layer.cornerRadius = 4;
        _coverView.clipsToBounds = YES;
        [self addSubview:_coverView];
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(52, 8, 200, 32)];
        _titleLabel.font = [UIFont systemFontOfSize:13];
        _titleLabel.textColor = [XYZUIHelpers textPrimary];
        [self addSubview:_titleLabel];
        _playButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _playButton.frame = CGRectMake(frame.size.width - 48, 4, 40, 40);
        [_playButton setTitle:@"▶" forState:UIControlStateNormal];
        _playButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [_playButton addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playButton];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPlayer)];
        [self addGestureRecognizer:tap];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:XYZPlayerDidUpdateNotification object:nil];
    }
    return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.playButton.frame = CGRectMake(self.bounds.size.width - 48, 4, 40, 40);
    self.titleLabel.frame = CGRectMake(52, 8, self.bounds.size.width - 108, 32);
}
- (void)refresh {
    XYZPlayerManager *pm = [XYZPlayerManager sharedManager];
    self.hidden = (pm.currentEpisode == nil);
    if (!pm.currentEpisode) return;
    self.titleLabel.text = pm.currentEpisode.title;
    [[XYZImageCache sharedCache] loadImageURL:pm.currentEpisode.coverURL intoImageView:self.coverView placeholder:[XYZUIHelpers placeholderCover]];
    [self.playButton setTitle:pm.isPlaying ? @"❚❚" : @"▶" forState:UIControlStateNormal];
}
- (void)toggle {
    [[XYZPlayerManager sharedManager] togglePlayPause];
}
- (void)openPlayer {
    if (![XYZPlayerManager sharedManager].currentEpisode) return;
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;
    XYZPlayerViewController *pvc = [[XYZPlayerViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:pvc];
    [root presentViewController:nav animated:YES completion:nil];
}
@end
