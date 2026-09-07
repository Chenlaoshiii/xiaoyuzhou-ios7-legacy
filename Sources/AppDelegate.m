#import "AppDelegate.h"
#import "XYZAuthManager.h"
#import "XYZLoginViewController.h"
#import "XYZTabBarController.h"
#import "XYZUIHelpers.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Match nweb launch path for first frame: window + label + makeKeyAndVisible only.
    // No AuthManager, no NSURLSession, no AVFoundation until after first paint.
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
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];

    // Defer native Login/TabBar (+ any network) until after first frame settles.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentNativeRoot];
    });
    return YES;
}

- (void)presentNativeRoot {
    @try {
        BOOL loggedIn = NO;
        @try {
            [[XYZAuthManager sharedManager] loadStoredCredentials];
            loggedIn = [XYZAuthManager sharedManager].isLoggedIn;
        } @catch (__unused NSException *ex) {
            loggedIn = NO;
        }

        if (loggedIn) {
            self.window.rootViewController = [[XYZTabBarController alloc] init];
            // Defer token refresh further — do not touch network on this turn.
            dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    [[XYZAuthManager sharedManager] refreshIfNeededWithCompletion:nil];
                } @catch (__unused NSException *ex) {
                }
            });
        } else {
            XYZLoginViewController *login = [[XYZLoginViewController alloc] init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:login];
            @try {
                nav.navigationBar.tintColor = [XYZUIHelpers brandGreen];
            } @catch (__unused NSException *ex) {
            }
            self.window.rootViewController = nav;
        }
    } @catch (__unused NSException *ex) {
        // Keep the splash label if native UI fails.
    }
}

@end
