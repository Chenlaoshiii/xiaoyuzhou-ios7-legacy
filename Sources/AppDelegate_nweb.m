#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];
    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(20, 180, 280, 80)];
    lab.text = @"小宇宙";
    lab.textAlignment = NSTextAlignmentCenter;
    lab.font = [UIFont boldSystemFontOfSize:36];
    lab.textColor = [UIColor blackColor];
    lab.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    [vc.view addSubview:lab];
    self.statusLabel = lab;
    self.rootVC = vc;
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
