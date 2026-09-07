#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    CGRect frame = [[UIScreen mainScreen] bounds];
    if (frame.size.width < 1) frame = CGRectMake(0, 0, 320, 568);
    self.window = [[UIWindow alloc] initWithFrame:frame];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];
    vc.view.frame = frame;

    CGFloat top = 20.0f;
    if (frame.size.height >= 568) top = 20.0f;

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, top, frame.size.width - 20, 36)];
    self.statusLabel.text = @"小宇宙";
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont boldSystemFontOfSize:16];
    self.statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.55 blue:0.35 alpha:1.0];
    self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [vc.view addSubview:self.statusLabel];

    CGRect webFrame = CGRectMake(0, top + 36, frame.size.width, frame.size.height - (top + 36));
    self.webView = [[UIWebView alloc] initWithFrame:webFrame];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.backgroundColor = [UIColor whiteColor];
    [vc.view addSubview:self.webView];

    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];

    // Defer network until after first frame so launch cannot flash-crash on TLS.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadHome];
    });
    return YES;
}

- (void)loadHome {
    self.statusLabel.text = @"加载中…";
    NSURL *url = [NSURL URLWithString:@"https://www.xiaoyuzhoufm.com/"];
    NSURLRequest *req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    [self.webView loadRequest:req];
}

- (void)loadFallbackHTML:(NSString *)reason {
    NSString *html = [NSString stringWithFormat:
        @"<html><head><meta name='viewport' content='width=device-width,initial-scale=1'/>"
        @"<meta charset='utf-8'/></head><body style='font-family:-apple-system,Helvetica;padding:24px;'>"
        @"<h2>小宇宙 Legacy</h2>"
        @"<p>应用已成功启动（iOS 7 / armv7）。</p>"
        @"<p style='color:#666'>网页加载失败：%@</p>"
        @"<p>可尝试：</p><ul>"
        @"<li><a href='https://www.xiaoyuzhoufm.com/'>https://www.xiaoyuzhoufm.com/</a></li>"
        @"<li><a href='http://www.xiaoyuzhoufm.com/'>http://www.xiaoyuzhoufm.com/</a></li>"
        @"</ul>"
        @"<p><button onclick=\"location.reload()\">重试</button></p>"
        @"</body></html>", reason ?: @"unknown"];
    [self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"https://www.xiaoyuzhoufm.com/"]];
    self.statusLabel.text = @"本地页（站点 TLS 可能不兼容 iOS7）";
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.statusLabel.text = @"加载中…";
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (title.length) self.statusLabel.text = title;
    else self.statusLabel.text = @"小宇宙";
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // Ignore cancellations from rapid redirects
    if ([error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == NSURLErrorCancelled) return;
    NSString *msg = error.localizedDescription ?: @"load failed";
    self.statusLabel.text = @"加载失败，显示本地页";
    // Try http once, then fallback HTML
    static int tries = 0;
    if (tries == 0) {
        tries = 1;
        NSURL *url = [NSURL URLWithString:@"http://www.xiaoyuzhoufm.com/"];
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
        return;
    }
    [self loadFallbackHTML:msg];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

@end
