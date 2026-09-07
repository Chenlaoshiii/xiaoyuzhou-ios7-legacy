#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^XYZAPISuccessBlock)(NSDictionary * _Nullable json, NSHTTPURLResponse * _Nullable response);
typedef void (^_Nullable XYZAPISuccessBlockNullable)(NSDictionary * _Nullable json, NSHTTPURLResponse * _Nullable response);
typedef void (^XYZAPIFailureBlock)(NSError *error, NSInteger statusCode, NSDictionary * _Nullable json);

@interface XYZAPIClient : NSObject

+ (instancetype)sharedClient;

@property (nonatomic, copy, nullable) NSString *accessToken;
@property (nonatomic, copy, nullable) NSString *refreshToken;
@property (nonatomic, copy) NSString *deviceId;

- (void)sendSMSCodeWithPhone:(NSString *)phone
                    areaCode:(NSString *)areaCode
                     success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)loginWithPhone:(NSString *)phone
              areaCode:(NSString *)areaCode
            verifyCode:(NSString *)code
               success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)refreshTokenWithSuccess:(XYZAPISuccessBlock _Nullable)success
                        failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)fetchDiscoveryWithLoadMoreKey:(NSString * _Nullable)loadMoreKey
                              success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)searchWithKeyword:(NSString *)keyword
                     type:(NSString *)type
              loadMoreKey:(NSDictionary * _Nullable)loadMoreKey
                  success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)fetchSubscriptionsWithLoadMoreKey:(NSDictionary * _Nullable)loadMoreKey
                                  success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)updateSubscriptionPid:(NSString *)pid
                         mode:(NSString *)mode
                      success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)fetchPodcastWithPid:(NSString *)pid
                    success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)fetchEpisodeListWithPid:(NSString *)pid
                          order:(NSString *)order
                    loadMoreKey:(NSDictionary * _Nullable)loadMoreKey
                        success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)fetchEpisodeWithEid:(NSString *)eid
                    success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)fetchCommentsForEid:(NSString *)eid
                      order:(NSString *)order
                loadMoreKey:(NSDictionary * _Nullable)loadMoreKey
                    success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)fetchPrivateMediaForEid:(NSString *)eid
                        success:(XYZAPISuccessBlock _Nullable)success
                     failure:(XYZAPIFailureBlock _Nullable)failure;

- (void)fetchProfileSuccess:(XYZAPISuccessBlock _Nullable)success
                    failure:(XYZAPIFailureBlock _Nullable)failure;

@end

NS_ASSUME_NONNULL_END
