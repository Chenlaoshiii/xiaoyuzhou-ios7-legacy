#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface XYZJSONHelper : NSObject
+ (NSArray *)arrayFromResponse:(NSDictionary *)json keys:(NSArray *)keys;
+ (NSDictionary * _Nullable)loadMoreKeyFromResponse:(NSDictionary *)json;
@end
NS_ASSUME_NONNULL_END
