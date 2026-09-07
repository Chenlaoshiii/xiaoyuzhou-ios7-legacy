#import <Foundation/Foundation.h>
#import "XYZModels.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const XYZAuthDidLoginNotification;
extern NSString * const XYZAuthDidLogoutNotification;

@interface XYZAuthManager : NSObject
+ (instancetype)sharedManager;
@property (nonatomic, readonly) BOOL isLoggedIn;
@property (nonatomic, strong, nullable) XYZUserProfile *currentUser;

- (void)loadStoredCredentials;
- (void)saveTokensAccess:(NSString *)access refresh:(NSString *)refresh deviceId:(NSString *)deviceId;
- (void)clearCredentials;
- (void)sendCodeToPhone:(NSString *)phone areaCode:(NSString *)areaCode completion:(void(^)(NSError * _Nullable error))completion;
- (void)loginWithPhone:(NSString *)phone areaCode:(NSString *)areaCode code:(NSString *)code completion:(void(^)(NSError * _Nullable error))completion;
- (void)refreshIfNeededWithCompletion:(void(^ _Nullable)(BOOL ok))completion;
- (void)fetchProfileWithCompletion:(void(^ _Nullable)(XYZUserProfile * _Nullable user, NSError * _Nullable error))completion;
- (void)logout;
@end

NS_ASSUME_NONNULL_END
