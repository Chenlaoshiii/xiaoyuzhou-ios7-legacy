#import <UIKit/UIKit.h>
#import "XYZModels.h"
@interface XYZCommentCell : UITableViewCell
- (void)configureWithComment:(XYZComment *)comment;
+ (CGFloat)heightForComment:(XYZComment *)comment width:(CGFloat)width;
@end
