#import "AppDelegate.h"
#import "XYZAuthManager.h"
#import "XYZLoginViewController.h"
#import "XYZTabBarController.h"
#import "XYZUIHelpers.h"

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    @try {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        if (!self.window) {
            self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        }

        BOOL loggedIn = NO;
        @try {
            [[XYZAuthManager sharedManager] loadStoredCredentials];
            loggedIn = [XYZAuthManager sharedManager].isLoggedIn;
        } @catch (__unused NSException *ex) {
            loggedIn = NO;
        }

        if (loggedIn) {
            self.window.rootViewController = [[XYZTabBarController alloc] init];
            @try {
                [[XYZAuthManager sharedManager] refreshIfNeededWithCompletion:nil];
            } @catch (__unused NSException *ex) {
            }
        } else {
            XYZLoginViewController *login = [[XYZLoginViewController alloc] init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:login];
            @try {
                nav.navigationBar.tintColor = [XYZUIHelpers brandGreen];
            } @catch (__unused NSException *ex) {
            }
            self.window.rootViewController = nav;
        }
        [self.window makeKeyAndVisible];
    } @catch (__unused NSException *ex) {
        // Last-resort blank window so we don't flash-crash before any UI.
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = [UIColor whiteColor];
        self.window.rootViewController = vc;
        [self.window makeKeyAndVisible];
    }
    return YES;
}
@end
