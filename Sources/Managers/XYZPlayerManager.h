#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "XYZModels.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const XYZPlayerDidUpdateNotification;

@interface XYZPlayerManager : NSObject
+ (instancetype)sharedManager;
@property (nonatomic, strong, nullable) AVPlayer *player;
@property (nonatomic, strong, nullable) XYZEpisode *currentEpisode;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) NSTimeInterval currentTime;
@property (nonatomic, readonly) NSTimeInterval duration;

- (void)playEpisode:(XYZEpisode *)episode;
- (void)togglePlayPause;
- (void)pause;
- (void)play;
- (void)seekTo:(NSTimeInterval)time;
- (void)seekBy:(NSTimeInterval)delta;
@end

NS_ASSUME_NONNULL_END
