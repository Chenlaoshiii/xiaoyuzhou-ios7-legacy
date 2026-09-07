#import "XYZAuthManager.h"
#import "XYZAPIClient.h"

NSString * const XYZAuthDidLoginNotification = @"XYZAuthDidLoginNotification";
NSString * const XYZAuthDidLogoutNotification = @"XYZAuthDidLogoutNotification";

static NSString * const kKeyAccess = @"xyz.accessToken";
static NSString * const kKeyRefresh = @"xyz.refreshToken";
static NSString * const kKeyDevice = @"xyz.deviceId";
static NSString * const kKeyUserJSON = @"xyz.userJSON";

@implementation XYZAuthManager

+ (instancetype)sharedManager {
    static XYZAuthManager *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ m = [[XYZAuthManager alloc] init]; });
    return m;
}

- (BOOL)isLoggedIn {
    return [XYZAPIClient sharedClient].accessToken.length > 0;
}

- (void)loadStoredCredentials {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    XYZAPIClient *api = [XYZAPIClient sharedClient];
    api.accessToken = [ud stringForKey:kKeyAccess];
    api.refreshToken = [ud stringForKey:kKeyRefresh];
    NSString *dev = [ud stringForKey:kKeyDevice];
    if (dev.length) api.deviceId = dev;
    NSData *udata = [ud objectForKey:kKeyUserJSON];
    if ([udata isKindOfClass:[NSData class]]) {
        id json = [NSJSONSerialization JSONObjectWithData:udata options:0 error:NULL];
        if ([json isKindOfClass:[NSDictionary class]]) {
            self.currentUser = [XYZUserProfile profileWithDictionary:json];
        }
    }
}

- (void)saveTokensAccess:(NSString *)access refresh:(NSString *)refresh deviceId:(NSString *)deviceId {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    XYZAPIClient *api = [XYZAPIClient sharedClient];
    if (access.length) { api.accessToken = access; [ud setObject:access forKey:kKeyAccess]; }
    if (refresh.length) { api.refreshToken = refresh; [ud setObject:refresh forKey:kKeyRefresh]; }
    if (deviceId.length) { api.deviceId = deviceId; [ud setObject:deviceId forKey:kKeyDevice]; }
    [ud synchronize];
}

- (void)clearCredentials {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:kKeyAccess];
    [ud removeObjectForKey:kKeyRefresh];
    [ud removeObjectForKey:kKeyUserJSON];
    [ud synchronize];
    XYZAPIClient *api = [XYZAPIClient sharedClient];
    api.accessToken = nil;
    api.refreshToken = nil;
    self.currentUser = nil;
}

- (void)sendCodeToPhone:(NSString *)phone areaCode:(NSString *)areaCode completion:(void (^)(NSError *))completion {
    [[XYZAPIClient sharedClient] sendSMSCodeWithPhone:phone areaCode:areaCode success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        if (completion) completion(nil);
    } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
        if (completion) completion(error);
    }];
}

- (void)loginWithPhone:(NSString *)phone areaCode:(NSString *)areaCode code:(NSString *)code completion:(void (^)(NSError *))completion {
    __weak typeof(self) weakSelf = self;
    [[XYZAPIClient sharedClient] loginWithPhone:phone areaCode:areaCode verifyCode:code success:^(NSDictionary *json, NSHTTPURLResponse *response) {
        XYZAPIClient *api = [XYZAPIClient sharedClient];
        [weakSelf saveTokensAccess:api.accessToken refresh:api.refreshToken deviceId:api.deviceId];
        // try parse user
        NSDictionary *data = json[@"data"];
        if ([data isKindOfClass:[NSDictionary class]]) {
            id user = data[@"data"] ?: data[@"user"] ?: data;
            if ([user isKindOfClass:[NSDictionary class]]) {
                weakSelf.currentUser = [XYZUserProfile profileWithDictionary:user];
                NSData *raw = [NSJSONSerialization dataWithJSONObject:user options:0 error:NULL];
                if (raw) [[NSUserDefaults standardUserDefaults] setObject:raw forKey:kKeyUserJSON];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:XYZAuthDidLoginNotification object:nil];
        if (completion) completion(nil);
        // refresh profile in background
        [weakSelf fetchProfileWithCompletion:nil];
    } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
        if (completion) completion(error);
    }];
}

- (void)refreshIfNeededWithCompletion:(void (^)(BOOL))completion {
    XYZAPIClient *api = [XYZAPIClient sharedClient];
    if (!api.refreshToken.length) { if (completion) completion(NO); return; }
    __weak typeof(self) weakSelf = self;
    [api refreshTokenWithSuccess:^(NSDictionary *json, NSHTTPURLResponse *response) {
        [weakSelf saveTokensAccess:api.accessToken refresh:api.refreshToken deviceId:api.deviceId];
        if (completion) completion(YES);
    } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
        if (completion) completion(NO);
    }];
}

- (void)fetchProfileWithCompletion:(void (^)(XYZUserProfile *, NSError *))completion {
    __weak typeof(self) weakSelf = self;
    [[XYZAPIClient sharedClient] fetchProfileSuccess:^(NSDictionary *json, NSHTTPURLResponse *response) {
        XYZUserProfile *u = [XYZUserProfile profileWithDictionary:json];
        weakSelf.currentUser = u;
        if (json) {
            NSData *raw = [NSJSONSerialization dataWithJSONObject:json options:0 error:NULL];
            if (raw) [[NSUserDefaults standardUserDefaults] setObject:raw forKey:kKeyUserJSON];
        }
        if (completion) completion(u, nil);
    } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
        if (statusCode == 401) {
            [weakSelf refreshIfNeededWithCompletion:^(BOOL ok) {
                if (ok) [weakSelf fetchProfileWithCompletion:completion];
                else if (completion) completion(nil, error);
            }];
            return;
        }
        if (completion) completion(nil, error);
    }];
}

- (void)logout {
    [self clearCredentials];
    [[NSNotificationCenter defaultCenter] postNotificationName:XYZAuthDidLogoutNotification object:nil];
}

@end
