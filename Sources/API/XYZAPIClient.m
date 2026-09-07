#import "XYZAPIClient.h"

static NSString * const kXYZBaseURL = @"https://api.xiaoyuzhoufm.com";
static NSString * const kXYZAuthBaseURL = @"https://podcaster-api.xiaoyuzhoufm.com";
static NSString * const kXYZUserAgent = @"Xiaoyuzhou/2.57.1 (build:1576; iOS 7.1.2)";
static NSString * const kXYZAppVersion = @"2.57.1";
static NSString * const kXYZAppBuild = @"1576";
static NSString * const kXYZBundleID = @"app.podcast.cosmos";

@interface XYZAPIClient ()
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation XYZAPIClient

+ (instancetype)sharedClient {
    static XYZAPIClient *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[XYZAPIClient alloc] init];
    });
    return client;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Prefer CFUUID only; do NOT create NSURLSession here — defer until first request
        // so splash / first frame never touches CFNetwork.
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        NSString *uuidStr = nil;
        if (uuid) {
            uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
            CFRelease(uuid);
        }
        if (uuidStr.length == 0) {
            uuidStr = [NSString stringWithFormat:@"ios7-%08x-%08x", (unsigned)arc4random(), (unsigned)arc4random()];
        }
        _deviceId = uuidStr;
    }
    return self;
}

- (NSURLSession *)session {
    if (_session) return _session;
    @try {
        NSURLSessionConfiguration *cfg = nil;
        if ([NSURLSessionConfiguration respondsToSelector:@selector(defaultSessionConfiguration)]) {
            cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        if (cfg) {
            cfg.timeoutIntervalForRequest = 30.0;
            cfg.HTTPMaximumConnectionsPerHost = 4;
            _session = [NSURLSession sessionWithConfiguration:cfg];
        } else {
            _session = [NSURLSession sharedSession];
        }
    } @catch (__unused NSException *ex) {
        _session = [NSURLSession sharedSession];
    }
    return _session;
}

#pragma mark - Headers

- (NSString *)localTimeISO {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    fmt.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    fmt.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    return [fmt stringFromDate:[NSDate date]];
}

- (NSMutableURLRequest *)requestWithURL:(NSString *)urlString method:(NSString *)method auth:(BOOL)auth {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = method;
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [req setValue:kXYZUserAgent forHTTPHeaderField:@"User-Agent"];
    [req setValue:@"AppStore" forHTTPHeaderField:@"Market"];
    [req setValue:kXYZAppBuild forHTTPHeaderField:@"App-BuildNo"];
    [req setValue:@"ios" forHTTPHeaderField:@"OS"];
    [req setValue:@"Apple" forHTTPHeaderField:@"Manufacturer"];
    [req setValue:kXYZBundleID forHTTPHeaderField:@"BundleID"];
    [req setValue:@"zh-Hans-CN;q=1.0" forHTTPHeaderField:@"Accept-Language"];
    [req setValue:@"iPhone5,3" forHTTPHeaderField:@"Model"];
    [req setValue:@"4" forHTTPHeaderField:@"app-permissions"];
    [req setValue:kXYZAppVersion forHTTPHeaderField:@"App-Version"];
    [req setValue:@"true" forHTTPHeaderField:@"WifiConnected"];
    [req setValue:@"7.1.2" forHTTPHeaderField:@"OS-Version"];
    [req setValue:[self localTimeISO] forHTTPHeaderField:@"Local-Time"];
    [req setValue:@"Asia/Shanghai" forHTTPHeaderField:@"Timezone"];
    [req setValue:self.deviceId ?: @"" forHTTPHeaderField:@"x-jike-device-id"];
    if (auth && self.accessToken.length) {
        [req setValue:self.accessToken forHTTPHeaderField:@"x-jike-access-token"];
    }
    if (self.refreshToken.length) {
        [req setValue:self.refreshToken forHTTPHeaderField:@"x-jike-refresh-token"];
    }
    return req;
}

- (void)performRequest:(NSMutableURLRequest *)request
               success:(XYZAPISuccessBlock)success
               failure:(XYZAPIFailureBlock)failure {
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        NSInteger status = http.statusCode;
        NSDictionary *json = nil;
        if (data.length) {
            id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            if ([obj isKindOfClass:[NSDictionary class]]) {
                json = obj;
            } else if ([obj isKindOfClass:[NSArray class]]) {
                json = @{@"data": obj};
            }
        }
        // Capture tokens from response headers if present
        NSString *at = http.allHeaderFields[@"x-jike-access-token"];
        if (!at) at = http.allHeaderFields[@"X-Jike-Access-Token"];
        NSString *rt = http.allHeaderFields[@"x-jike-refresh-token"];
        if (!rt) rt = http.allHeaderFields[@"X-Jike-Refresh-Token"];
        if (at.length) self.accessToken = at;
        if (rt.length) self.refreshToken = rt;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                if (failure) failure(error, status, json);
                return;
            }
            if (status >= 200 && status < 300) {
                if (success) success(json, http);
            } else {
                NSError *err = [NSError errorWithDomain:@"XYZAPI" code:status userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"HTTP %ld", (long)status]}];
                if (failure) failure(err, status, json);
            }
        });
    }];
    [task resume];
}

- (void)POST:(NSString *)urlString body:(NSDictionary *)body auth:(BOOL)auth success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSMutableURLRequest *req = [self requestWithURL:urlString method:@"POST" auth:auth];
    if (body) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:NULL];
        req.HTTPBody = data;
    }
    [self performRequest:req success:success failure:failure];
}

- (void)GET:(NSString *)urlString auth:(BOOL)auth success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSMutableURLRequest *req = [self requestWithURL:urlString method:@"GET" auth:auth];
    [self performRequest:req success:success failure:failure];
}

#pragma mark - Auth (podcaster-api, aligned with ultrazg/xyz)

- (void)sendSMSCodeWithPhone:(NSString *)phone areaCode:(NSString *)areaCode success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSString *url = [kXYZAuthBaseURL stringByAppendingString:@"/v1/auth/send-code"];
    NSDictionary *body = @{
        @"mobilePhoneNumber": phone ?: @"",
        @"areaCode": areaCode.length ? areaCode : @"+86"
    };
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json, text/plain, */*" forHTTPHeaderField:@"Accept"];
    [req setValue:@"https://podcaster.xiaoyuzhoufm.com" forHTTPHeaderField:@"Origin"];
    [req setValue:@"https://podcaster.xiaoyuzhoufm.com/" forHTTPHeaderField:@"Referer"];
    [req setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2" forHTTPHeaderField:@"User-Agent"];
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:NULL];
    [self performRequest:req success:success failure:failure];
}

- (void)loginWithPhone:(NSString *)phone areaCode:(NSString *)areaCode verifyCode:(NSString *)code success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSString *url = [kXYZAuthBaseURL stringByAppendingString:@"/v1/auth/login-with-sms"];
    NSDictionary *body = @{
        @"mobilePhoneNumber": phone ?: @"",
        @"areaCode": areaCode.length ? areaCode : @"+86",
        @"verifyCode": code ?: @""
    };
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json, text/plain, */*" forHTTPHeaderField:@"Accept"];
    [req setValue:@"https://podcaster.xiaoyuzhoufm.com" forHTTPHeaderField:@"Origin"];
    [req setValue:@"https://podcaster.xiaoyuzhoufm.com/" forHTTPHeaderField:@"Referer"];
    [req setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2" forHTTPHeaderField:@"User-Agent"];
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:NULL];

    __weak typeof(self) weakSelf = self;
    [self performRequest:req success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        // Tokens may be in headers (already captured) or nested in body (proxy style)
        NSDictionary *data = json[@"data"];
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSString *at = data[@"x-jike-access-token"];
            NSString *rt = data[@"x-jike-refresh-token"];
            if ([at isKindOfClass:[NSString class]] && at.length) weakSelf.accessToken = at;
            if ([rt isKindOfClass:[NSString class]] && rt.length) weakSelf.refreshToken = rt;
        }
        if (success) success(json, response);
    } failure:failure];
}

- (void)refreshTokenWithSuccess:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSString *url = [kXYZBaseURL stringByAppendingString:@"/app_auth_tokens.refresh"];
    NSMutableURLRequest *req = [self requestWithURL:url method:@"POST" auth:YES];
    [req setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    if (self.refreshToken.length) {
        [req setValue:self.refreshToken forHTTPHeaderField:@"x-jike-refresh-token"];
    }
    __weak typeof(self) weakSelf = self;
    [self performRequest:req success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        NSString *at = json[@"x-jike-access-token"] ?: json[@"access_token"];
        NSString *rt = json[@"x-jike-refresh-token"] ?: json[@"refresh_token"];
        NSDictionary *data = json[@"data"];
        if ([data isKindOfClass:[NSDictionary class]]) {
            if (!at) at = data[@"x-jike-access-token"];
            if (!rt) rt = data[@"x-jike-refresh-token"];
        }
        if ([at isKindOfClass:[NSString class]] && at.length) weakSelf.accessToken = at;
        if ([rt isKindOfClass:[NSString class]] && rt.length) weakSelf.refreshToken = rt;
        if (success) success(json, response);
    } failure:failure];
}

#pragma mark - Content APIs

- (void)fetchDiscoveryWithLoadMoreKey:(NSString *)loadMoreKey success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSMutableDictionary *body = [@{@"returnAll": @NO} mutableCopy];
    if (loadMoreKey.length) body[@"loadMoreKey"] = loadMoreKey;
    [self POST:[kXYZBaseURL stringByAppendingString:@"/v1/discovery-feed/list"] body:body auth:YES success:success failure:failure];
}

- (void)searchWithKeyword:(NSString *)keyword type:(NSString *)type loadMoreKey:(NSDictionary *)loadMoreKey success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSMutableDictionary *body = [@{
        @"limit": @"20",
        @"sourcePageName": @"4",
        @"type": type.length ? type : @"PODCAST",
        @"currentPageName": @"4",
        @"keyword": keyword ?: @""
    } mutableCopy];
    if (loadMoreKey) body[@"loadMoreKey"] = loadMoreKey;
    [self POST:[kXYZBaseURL stringByAppendingString:@"/v1/search/create"] body:body auth:YES success:success failure:failure];
}

- (void)fetchSubscriptionsWithLoadMoreKey:(NSDictionary *)loadMoreKey success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSMutableDictionary *body = [@{
        @"limit": @"20",
        @"sortOrder": @"desc",
        @"sortBy": @"subscribedAt"
    } mutableCopy];
    if (loadMoreKey) body[@"loadMoreKey"] = loadMoreKey;
    [self POST:[kXYZBaseURL stringByAppendingString:@"/v1/subscription/list"] body:body auth:YES success:success failure:failure];
}

- (void)updateSubscriptionPid:(NSString *)pid mode:(NSString *)mode success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSDictionary *body = @{@"pid": pid ?: @"", @"mode": mode ?: @"ON"};
    [self POST:[kXYZBaseURL stringByAppendingString:@"/v1/subscription/update"] body:body auth:YES success:success failure:failure];
}

- (void)fetchPodcastWithPid:(NSString *)pid success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSString *url = [NSString stringWithFormat:@"%@/v1/podcast/get?pid=%@", kXYZBaseURL, [pid stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [self GET:url auth:YES success:success failure:failure];
}

- (void)fetchEpisodeListWithPid:(NSString *)pid order:(NSString *)order loadMoreKey:(NSDictionary *)loadMoreKey success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSMutableDictionary *body = [@{
        @"limit": @"20",
        @"pid": pid ?: @"",
        @"order": order.length ? order : @"desc"
    } mutableCopy];
    if (loadMoreKey) body[@"loadMoreKey"] = loadMoreKey;
    [self POST:[kXYZBaseURL stringByAppendingString:@"/v1/episode/list"] body:body auth:YES success:success failure:failure];
}

- (void)fetchEpisodeWithEid:(NSString *)eid success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSString *url = [NSString stringWithFormat:@"%@/v1/episode/get?eid=%@", kXYZBaseURL, [eid stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [self GET:url auth:YES success:success failure:failure];
}

- (void)fetchCommentsForEid:(NSString *)eid order:(NSString *)order loadMoreKey:(NSDictionary *)loadMoreKey success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSMutableDictionary *body = [@{
        @"order": order.length ? order : @"HOT",
        @"owner": @{@"id": eid ?: @"", @"type": @"EPISODE"}
    } mutableCopy];
    if (loadMoreKey) body[@"loadMoreKey"] = loadMoreKey;
    [self POST:[kXYZBaseURL stringByAppendingString:@"/v1/comment/list-primary"] body:body auth:YES success:success failure:failure];
}

- (void)fetchPrivateMediaForEid:(NSString *)eid success:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    NSString *url = [NSString stringWithFormat:@"%@/v1/private-media/get?dubbing=false&eid=%@", kXYZBaseURL, [eid stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [self GET:url auth:YES success:success failure:failure];
}

- (void)fetchProfileSuccess:(XYZAPISuccessBlock)success failure:(XYZAPIFailureBlock)failure {
    [self GET:[kXYZBaseURL stringByAppendingString:@"/v1/profile/get"] auth:YES success:success failure:failure];
}

@end
