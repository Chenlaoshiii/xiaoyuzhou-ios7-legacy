#import "XYZJSONHelper.h"
@implementation XYZJSONHelper
+ (NSArray *)arrayFromResponse:(NSDictionary *)json keys:(NSArray *)keys {
    if (![json isKindOfClass:[NSDictionary class]]) return @[];
    id data = json[@"data"] ?: json;
    if ([data isKindOfClass:[NSArray class]]) return data;
    if ([data isKindOfClass:[NSDictionary class]]) {
        for (NSString *k in keys) {
            id v = data[k];
            if ([v isKindOfClass:[NSArray class]]) return v;
        }
        // discovery: data is often array of sections
        id items = data[@"data"];
        if ([items isKindOfClass:[NSArray class]]) return items;
    }
    id top = json[@"data"];
    if ([top isKindOfClass:[NSArray class]]) return top;
    return @[];
}
+ (NSDictionary *)loadMoreKeyFromResponse:(NSDictionary *)json {
    if (![json isKindOfClass:[NSDictionary class]]) return nil;
    id key = json[@"loadMoreKey"];
    if (!key) {
        id data = json[@"data"];
        if ([data isKindOfClass:[NSDictionary class]]) key = data[@"loadMoreKey"];
    }
    if ([key isKindOfClass:[NSDictionary class]]) return key;
    if ([key isKindOfClass:[NSString class]] || [key isKindOfClass:[NSNumber class]]) return @{@"value": key};
    return nil;
}
@end
