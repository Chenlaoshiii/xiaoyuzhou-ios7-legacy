#import "XYZPlayerViewController.h"
#import "XYZPlayerManager.h"
#import "XYZImageCache.h"
#import "XYZUIHelpers.h"

@interface XYZPlayerViewController ()
@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *podcastLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, assign) BOOL scrubbing;
@end

@implementation XYZPlayerViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"正在播放";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(close)];

    CGFloat w = [XYZUIHelpers screenWidth];
    self.coverView = [[UIImageView alloc] initWithFrame:CGRectMake((w-200)/2, 40, 200, 200)];
    self.coverView.layer.cornerRadius = 12;
    self.coverView.clipsToBounds = YES;
    self.coverView.backgroundColor = [XYZUIHelpers brandGreen];
    [self.view addSubview:self.coverView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 260, w-48, 44)];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];

    self.podcastLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 306, w-48, 20)];
    self.podcastLabel.font = [UIFont systemFontOfSize:13];
    self.podcastLabel.textColor = [XYZUIHelpers textSecondary];
    self.podcastLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.podcastLabel];

    self.slider = [[UISlider alloc] initWithFrame:CGRectMake(24, 350, w-48, 30)];
    self.slider.minimumTrackTintColor = [XYZUIHelpers brandGreen];
    [self.slider addTarget:self action:@selector(sliderTouchDown) forControlEvents:UIControlEventTouchDown];
    [self.slider addTarget:self action:@selector(sliderTouchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self.slider addTarget:self action:@selector(sliderChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.slider];

    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 380, w-48, 18)];
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.textColor = [XYZUIHelpers textSecondary];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.timeLabel];

    UIButton *back15 = [UIButton buttonWithType:UIButtonTypeSystem];
    back15.frame = CGRectMake(w/2 - 110, 420, 50, 44);
    [back15 setTitle:@"-15s" forState:UIControlStateNormal];
    [back15 addTarget:self action:@selector(back15) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back15];

    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playBtn.frame = CGRectMake(w/2 - 32, 412, 64, 64);
    self.playBtn.layer.cornerRadius = 32;
    self.playBtn.backgroundColor = [XYZUIHelpers brandGreen];
    [self.playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.playBtn.titleLabel.font = [UIFont systemFontOfSize:22];
    [self.playBtn addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playBtn];

    UIButton *fwd30 = [UIButton buttonWithType:UIButtonTypeSystem];
    fwd30.frame = CGRectMake(w/2 + 60, 420, 50, 44);
    [fwd30 setTitle:@"+30s" forState:UIControlStateNormal];
    [fwd30 addTarget:self action:@selector(fwd30) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:fwd30];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:XYZPlayerDidUpdateNotification object:nil];
    [self refresh];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)close {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
- (void)refresh {
    XYZPlayerManager *pm = [XYZPlayerManager sharedManager];
    XYZEpisode *e = pm.currentEpisode;
    if (!e) return;
    self.titleLabel.text = e.title;
    self.podcastLabel.text = e.podcastTitle;
    [[XYZImageCache sharedCache] loadImageURL:e.coverURL intoImageView:self.coverView placeholder:[XYZUIHelpers placeholderCover]];
    [self.playBtn setTitle:pm.isPlaying ? @"❚❚" : @"▶" forState:UIControlStateNormal];
    NSTimeInterval dur = pm.duration > 0 ? pm.duration : e.duration;
    if (!self.scrubbing) {
        self.slider.maximumValue = dur > 0 ? dur : 1;
        self.slider.value = pm.currentTime;
    }
    self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", [XYZUIHelpers formatDuration:pm.currentTime], [XYZUIHelpers formatDuration:dur]];
    // userInfo errors handled via toast if needed — notification object may carry userInfo on NSNotification
}
- (void)toggle { [[XYZPlayerManager sharedManager] togglePlayPause]; }
- (void)back15 { [[XYZPlayerManager sharedManager] seekBy:-15]; }
- (void)fwd30 { [[XYZPlayerManager sharedManager] seekBy:30]; }
- (void)sliderTouchDown { self.scrubbing = YES; }
- (void)sliderTouchUp {
    self.scrubbing = NO;
    [[XYZPlayerManager sharedManager] seekTo:self.slider.value];
}
- (void)sliderChanged {
    self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", [XYZUIHelpers formatDuration:self.slider.value], [XYZUIHelpers formatDuration:self.slider.maximumValue]];
}
@end
