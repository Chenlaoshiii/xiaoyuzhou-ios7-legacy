#import "XYZTabBarController.h"
#import "XYZHomeViewController.h"
#import "XYZSearchViewController.h"
#import "XYZSubscriptionViewController.h"
#import "XYZProfileViewController.h"
#import "XYZMiniPlayerView.h"
#import "XYZUIHelpers.h"
#import "XYZPlayerManager.h"

@interface XYZTabBarController ()
@property (nonatomic, strong) XYZMiniPlayerView *miniPlayer;
@end

@implementation XYZTabBarController
- (void)viewDidLoad {
    [super viewDidLoad];
    UINavigationController *(^wrap)(UIViewController *, NSString *, NSString *) = ^UINavigationController *(UIViewController *vc, NSString *title, NSString *tab) {
        vc.title = title;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:tab image:nil tag:0];
        nav.navigationBar.tintColor = [XYZUIHelpers brandGreen];
        return nav;
    };
    self.viewControllers = @[
        wrap([[XYZHomeViewController alloc] init], @"首页", @"首页"),
        wrap([[XYZSearchViewController alloc] init], @"搜索", @"搜索"),
        wrap([[XYZSubscriptionViewController alloc] init], @"订阅", @"订阅"),
        wrap([[XYZProfileViewController alloc] init], @"我的", @"我的")
    ];
    self.tabBar.tintColor = [XYZUIHelpers brandGreen];

    CGFloat h = [XYZMiniPlayerView preferredHeight];
    CGFloat tabH = self.tabBar.bounds.size.height;
    CGFloat y = self.view.bounds.size.height - tabH - h;
    self.miniPlayer = [[XYZMiniPlayerView alloc] initWithFrame:CGRectMake(0, y, self.view.bounds.size.width, h)];
    self.miniPlayer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.miniPlayer.hidden = YES;
    [self.view addSubview:self.miniPlayer];
    [self.miniPlayer refresh];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerUpdated) name:XYZPlayerDidUpdateNotification object:nil];
}
- (void)playerUpdated {
    [self.miniPlayer refresh];
    CGFloat h = self.miniPlayer.hidden ? 0 : [XYZMiniPlayerView preferredHeight];
    // inset child tables if needed — keep simple
    (void)h;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
