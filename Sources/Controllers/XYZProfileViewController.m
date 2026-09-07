#import "XYZProfileViewController.h"
#import "XYZAuthManager.h"
#import "XYZImageCache.h"
#import "XYZUIHelpers.h"
#import "XYZLoginViewController.h"
#import "XYZAPIClient.h"

@interface XYZProfileViewController ()
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIButton *logoutBtn;
@end

@implementation XYZProfileViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [XYZUIHelpers bgGray];

    self.avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(([XYZUIHelpers screenWidth]-72)/2, 40, 72, 72)];
    self.avatarView.layer.cornerRadius = 36;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.backgroundColor = [XYZUIHelpers brandGreen];
    [self.view addSubview:self.avatarView];

    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 126, [XYZUIHelpers screenWidth]-40, 28)];
    self.nameLabel.font = [UIFont boldSystemFontOfSize:20];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.textColor = [XYZUIHelpers textPrimary];
    [self.view addSubview:self.nameLabel];

    self.bioLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 158, [XYZUIHelpers screenWidth]-40, 40)];
    self.bioLabel.font = [UIFont systemFontOfSize:13];
    self.bioLabel.textAlignment = NSTextAlignmentCenter;
    self.bioLabel.numberOfLines = 2;
    self.bioLabel.textColor = [XYZUIHelpers textSecondary];
    [self.view addSubview:self.bioLabel];

    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 210, [XYZUIHelpers screenWidth]-40, 60)];
    self.infoLabel.font = [UIFont systemFontOfSize:12];
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.textColor = [XYZUIHelpers textSecondary];
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.infoLabel];

    self.logoutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.logoutBtn.frame = CGRectMake(40, 290, [XYZUIHelpers screenWidth]-80, 44);
    [self.logoutBtn setTitle:@"退出登录" forState:UIControlStateNormal];
    [XYZUIHelpers stylePrimaryButton:self.logoutBtn];
    self.logoutBtn.backgroundColor = [UIColor colorWithRed:0.85 green:0.25 blue:0.25 alpha:1];
    [self.logoutBtn addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.logoutBtn];

    UILabel *disc = [[UILabel alloc] initWithFrame:CGRectMake(20, 360, [XYZUIHelpers screenWidth]-40, 80)];
    disc.text = @"小宇宙 Legacy\n非官方客户端 · Bundle: com.lars.xiaoyuzhoulegacy\n仅供学习研究，与小宇宙官方无关";
    disc.font = [UIFont systemFontOfSize:11];
    disc.textColor = [XYZUIHelpers textSecondary];
    disc.textAlignment = NSTextAlignmentCenter;
    disc.numberOfLines = 0;
    [self.view addSubview:disc];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshUI];
    __weak typeof(self) weakSelf = self;
    [[XYZAuthManager sharedManager] fetchProfileWithCompletion:^(XYZUserProfile *user, NSError *error) {
        [weakSelf refreshUI];
    }];
}
- (void)refreshUI {
    XYZUserProfile *u = [XYZAuthManager sharedManager].currentUser;
    self.nameLabel.text = u.nickname.length ? u.nickname : @"已登录用户";
    self.bioLabel.text = u.bio.length ? u.bio : @"欢迎使用小宇宙 Legacy";
    XYZAPIClient *api = [XYZAPIClient sharedClient];
    self.infoLabel.text = [NSString stringWithFormat:@"UID: %@\nDevice: %@…",
                           u.uid.length ? u.uid : @"-",
                           api.deviceId.length > 8 ? [api.deviceId substringToIndex:8] : api.deviceId];
    [[XYZImageCache sharedCache] loadImageURL:u.avatarURL intoImageView:self.avatarView placeholder:[XYZUIHelpers placeholderCover]];
}
- (void)logout {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"退出登录" message:@"确定要退出吗？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"退出", nil];
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[XYZAuthManager sharedManager] logout];
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[XYZLoginViewController alloc] init]];
        win.rootViewController = nav;
    }
}
@end
