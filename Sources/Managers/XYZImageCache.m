#import "XYZImageCache.h"

@interface XYZImageCache ()
@property (nonatomic, strong) NSCache *cache;
@property (nonatomic, strong) NSMutableDictionary *tasks; // url -> NSMutableArray of imageViews
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation XYZImageCache
+ (instancetype)sharedCache {
    static XYZImageCache *c;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ c = [[XYZImageCache alloc] init]; });
    return c;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        _cache.countLimit = 100;
        _tasks = [NSMutableDictionary dictionary];
        _session = [NSURLSession sharedSession];
    }
    return self;
}
- (void)loadImageURL:(NSString *)urlString intoImageView:(UIImageView *)imageView placeholder:(UIImage *)placeholder {
    imageView.image = placeholder;
    if (!urlString.length) return;
    imageView.accessibilityIdentifier = urlString;
    UIImage *cached = [self.cache objectForKey:urlString];
    if (cached) { imageView.image = cached; return; }
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    __weak typeof(self) weakSelf = self;
    __weak UIImageView *weakIV = imageView;
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || error) return;
        UIImage *img = [UIImage imageWithData:data];
        if (!img) return;
        [weakSelf.cache setObject:img forKey:urlString];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([weakIV.accessibilityIdentifier isEqualToString:urlString]) {
                weakIV.image = img;
            }
        });
    }];
    [task resume];
}
@end
