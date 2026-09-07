#import <UIKit/UIKit.h>
@interface AppDelegate : UIResponder <UIApplicationDelegate, UIWebViewDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UILabel *statusLabel;
@end
