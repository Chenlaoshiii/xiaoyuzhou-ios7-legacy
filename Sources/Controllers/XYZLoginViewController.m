#import "XYZLoginViewController.h"
#import "XYZAuthManager.h"
#import "XYZUIHelpers.h"
#import "XYZTabBarController.h"

@interface XYZLoginViewController ()
@property (nonatomic, strong) UITextField *phoneField;
@property (nonatomic, strong) UITextField *codeField;
@property (nonatomic, strong) UIButton *sendBtn;
@property (nonatomic, strong) UIButton *loginBtn;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, assign) NSInteger cooldown;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation XYZLoginViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"登录";

    UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 280, 40)];
    logo.text = @"小宇宙";
    logo.font = [UIFont boldSystemFontOfSize:32];
    logo.textColor = [XYZUIHelpers brandGreen];
    logo.textAlignment = NSTextAlignmentCenter;
    logo.frame = CGRectMake(0, 70, [XYZUIHelpers screenWidth], 40);
    [self.view addSubview:logo];

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(0, 112, [XYZUIHelpers screenWidth], 20)];
    sub.text = @"非官方 Legacy 客户端 · iOS 7";
    sub.font = [UIFont systemFontOfSize:12];
    sub.textColor = [XYZUIHelpers textSecondary];
    sub.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:sub];

    CGFloat x = 24, w = [XYZUIHelpers screenWidth] - 48;
    self.phoneField = [[UITextField alloc] initWithFrame:CGRectMake(x, 160, w, 44)];
    self.phoneField.placeholder = @"手机号";
    self.phoneField.keyboardType = UIKeyboardTypeNumberPad;
    self.phoneField.borderStyle = UITextBorderStyleRoundedRect;
    self.phoneField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:self.phoneField];

    self.codeField = [[UITextField alloc] initWithFrame:CGRectMake(x, 216, w - 110, 44)];
    self.codeField.placeholder = @"验证码";
    self.codeField.keyboardType = UIKeyboardTypeNumberPad;
    self.codeField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.codeField];

    self.sendBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sendBtn.frame = CGRectMake(x + w - 100, 216, 100, 44);
    [self.sendBtn setTitle:@"获取验证码" forState:UIControlStateNormal];
    self.sendBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.sendBtn addTarget:self action:@selector(sendCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendBtn];

    self.loginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.loginBtn.frame = CGRectMake(x, 280, w, 46);
    [self.loginBtn setTitle:@"登录" forState:UIControlStateNormal];
    [XYZUIHelpers stylePrimaryButton:self.loginBtn];
    [self.loginBtn addTarget:self action:@selector(doLogin) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginBtn];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake([XYZUIHelpers screenWidth]/2, 360);
    [self.view addSubview:self.spinner];

    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(x, 340, w, 60)];
    tip.text = @"使用小宇宙账号短信登录。本应用为非官方客户端，与小宇宙官方无关。";
    tip.font = [UIFont systemFontOfSize:11];
    tip.textColor = [XYZUIHelpers textSecondary];
    tip.numberOfLines = 0;
    [self.view addSubview:tip];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEdit)];
    [self.view addGestureRecognizer:tap];
}
- (void)endEdit { [self.view endEditing:YES]; }
- (void)sendCode {
    NSString *phone = [self.phoneField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (phone.length < 6) {
        [XYZUIHelpers showToast:@"请输入有效手机号" onView:self.view];
        return;
    }
    self.sendBtn.enabled = NO;
    [self.spinner startAnimating];
    __weak typeof(self) weakSelf = self;
    [[XYZAuthManager sharedManager] sendCodeToPhone:phone areaCode:@"+86" completion:^(NSError *error) {
        [weakSelf.spinner stopAnimating];
        if (error) {
            weakSelf.sendBtn.enabled = YES;
            [XYZUIHelpers showToast:error.localizedDescription ?: @"发送失败" onView:weakSelf.view];
        } else {
            [XYZUIHelpers showToast:@"验证码已发送" onView:weakSelf.view];
            weakSelf.cooldown = 60;
            weakSelf.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:weakSelf selector:@selector(tick) userInfo:nil repeats:YES];
        }
    }];
}
- (void)tick {
    self.cooldown--;
    if (self.cooldown <= 0) {
        [self.timer invalidate];
        self.timer = nil;
        self.sendBtn.enabled = YES;
        [self.sendBtn setTitle:@"获取验证码" forState:UIControlStateNormal];
    } else {
        [self.sendBtn setTitle:[NSString stringWithFormat:@"%lds", (long)self.cooldown] forState:UIControlStateNormal];
    }
}
- (void)doLogin {
    NSString *phone = [self.phoneField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *code = [self.codeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (phone.length < 6 || code.length < 4) {
        [XYZUIHelpers showToast:@"请填写手机号和验证码" onView:self.view];
        return;
    }
    [self.spinner startAnimating];
    self.loginBtn.enabled = NO;
    __weak typeof(self) weakSelf = self;
    [[XYZAuthManager sharedManager] loginWithPhone:phone areaCode:@"+86" code:code completion:^(NSError *error) {
        [weakSelf.spinner stopAnimating];
        weakSelf.loginBtn.enabled = YES;
        if (error) {
            [XYZUIHelpers showToast:error.localizedDescription ?: @"登录失败" onView:weakSelf.view];
        } else {
            UIWindow *win = [UIApplication sharedApplication].keyWindow;
            win.rootViewController = [[XYZTabBarController alloc] init];
        }
    }];
}
@end
