#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XYZPodcast : NSObject
@property (nonatomic, copy) NSString *pid;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *brief;
@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, copy) NSString *coverURL;
@property (nonatomic, assign) NSInteger episodeCount;
@property (nonatomic, assign) BOOL subscribed;
+ (instancetype)podcastWithDictionary:(NSDictionary *)dict;
@end

@interface XYZEpisode : NSObject
@property (nonatomic, copy) NSString *eid;
@property (nonatomic, copy) NSString *pid;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, copy) NSString *shownotes;
@property (nonatomic, copy) NSString *coverURL;
@property (nonatomic, copy) NSString *mediaURL;
@property (nonatomic, copy) NSString *podcastTitle;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, copy, nullable) NSString *pubDate;
@property (nonatomic, assign) NSInteger playCount;
@property (nonatomic, assign) NSInteger commentCount;
+ (instancetype)episodeWithDictionary:(NSDictionary *)dict;
+ (NSArray *)episodesFromDataArray:(NSArray *)array;
@end

@interface XYZComment : NSObject
@property (nonatomic, copy) NSString *cid;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *authorName;
@property (nonatomic, copy) NSString *authorAvatarURL;
@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, copy, nullable) NSString *createdAt;
+ (instancetype)commentWithDictionary:(NSDictionary *)dict;
+ (NSArray *)commentsFromDataArray:(NSArray *)array;
@end

@interface XYZUserProfile : NSObject
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *avatarURL;
@property (nonatomic, copy) NSString *bio;
@property (nonatomic, copy) NSString *phoneMasked;
+ (instancetype)profileWithDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
