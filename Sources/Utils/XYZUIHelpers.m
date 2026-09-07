#import "XYZUIHelpers.h"

@implementation XYZUIHelpers
+ (UIColor *)brandGreen { return [UIColor colorWithRed:0.18 green:0.66 blue:0.43 alpha:1.0]; }
+ (UIColor *)bgGray { return [UIColor colorWithRed:0.96 green:0.96 blue:0.97 alpha:1.0]; }
+ (UIColor *)textPrimary { return [UIColor colorWithRed:0.12 green:0.14 blue:0.16 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithRed:0.45 green:0.48 blue:0.52 alpha:1.0]; }
+ (void)stylePrimaryButton:(UIButton *)btn {
    btn.backgroundColor = [self brandGreen];
    btn.layer.cornerRadius = 6.0;
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
}
+ (NSString *)formatDuration:(NSTimeInterval)sec {
    if (sec < 0 || !isfinite(sec)) return @"--:--";
    int s = (int)sec;
    int h = s / 3600; int m = (s % 3600) / 60; int r = s % 60;
    if (h > 0) return [NSString stringWithFormat:@"%d:%02d:%02d", h, m, r];
    return [NSString stringWithFormat:@"%d:%02d", m, r];
}
+ (void)showToast:(NSString *)text onView:(UIView *)view {
    if (!view || !text.length) return;
    UILabel *lab = [[UILabel alloc] init];
    lab.text = text;
    lab.textColor = [UIColor whiteColor];
    lab.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    lab.font = [UIFont systemFontOfSize:14];
    lab.textAlignment = NSTextAlignmentCenter;
    lab.numberOfLines = 0;
    lab.layer.cornerRadius = 8;
    lab.clipsToBounds = YES;
    CGSize size = [text sizeWithFont:lab.font constrainedToSize:CGSizeMake(260, 80) lineBreakMode:NSLineBreakByWordWrapping];
    lab.frame = CGRectMake(0, 0, size.width + 28, size.height + 16);
    lab.center = CGPointMake(view.bounds.size.width/2, view.bounds.size.height * 0.72);
    [view addSubview:lab];
    [UIView animateWithDuration:0.3 delay:1.4 options:0 animations:^{ lab.alpha = 0; } completion:^(BOOL finished) { [lab removeFromSuperview]; }];
}
+ (CGFloat)screenWidth { return [UIScreen mainScreen].bounds.size.width; }
+ (UIImage *)placeholderCover {
    CGSize sz = CGSizeMake(80, 80);
    UIGraphicsBeginImageContextWithOptions(sz, YES, 0);
    [[self brandGreen] setFill];
    UIRectFill(CGRectMake(0, 0, sz.width, sz.height));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
@end
