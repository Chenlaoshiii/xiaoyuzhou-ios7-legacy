#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface XYZUIHelpers : NSObject
+ (UIColor *)brandGreen;
+ (UIColor *)bgGray;
+ (UIColor *)textPrimary;
+ (UIColor *)textSecondary;
+ (void)stylePrimaryButton:(UIButton *)btn;
+ (NSString *)formatDuration:(NSTimeInterval)sec;
+ (void)showToast:(NSString *)text onView:(UIView *)view;
+ (CGFloat)screenWidth;
+ (UIImage *)placeholderCover;
@end
NS_ASSUME_NONNULL_END
