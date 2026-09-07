#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface XYZImageCache : NSObject
+ (instancetype)sharedCache;
- (void)loadImageURL:(NSString *)urlString intoImageView:(UIImageView *)imageView placeholder:(UIImage * _Nullable)placeholder;
@end
NS_ASSUME_NONNULL_END
