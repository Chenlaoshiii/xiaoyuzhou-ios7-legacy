#import "XYZPlayerManager.h"
#import "XYZAPIClient.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

NSString * const XYZPlayerDidUpdateNotification = @"XYZPlayerDidUpdateNotification";

@interface XYZPlayerManager ()
@property (nonatomic, strong) id timeObserver;
@end

@implementation XYZPlayerManager

+ (instancetype)sharedManager {
    static XYZPlayerManager *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ m = [[XYZPlayerManager alloc] init]; });
    return m;
}

- (instancetype)init {
    self = [super init];
    // Defer AVAudioSession activation until first playback — safer for launch.
    return self;
}

- (void)ensureAudioSession {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            NSError *err = nil;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&err];
            [[AVAudioSession sharedInstance] setActive:YES error:&err];
        } @catch (__unused NSException *ex) {
        }
    });
}

- (BOOL)isPlaying {
    return self.player && self.player.rate > 0.01;
}

- (NSTimeInterval)currentTime {
    if (!self.player) return 0;
    CMTime t = self.player.currentTime;
    if (CMTIME_IS_INVALID(t) || CMTIME_IS_INDEFINITE(t)) return 0;
    return CMTimeGetSeconds(t);
}

- (NSTimeInterval)duration {
    if (!self.player || !self.player.currentItem) return self.currentEpisode.duration;
    CMTime d = self.player.currentItem.duration;
    if (CMTIME_IS_INVALID(d) || CMTIME_IS_INDEFINITE(d)) return self.currentEpisode.duration;
    return CMTimeGetSeconds(d);
}

- (void)playEpisode:(XYZEpisode *)episode {
    if (!episode) return;
    self.currentEpisode = episode;
    NSString *urlStr = episode.mediaURL;
    if (!urlStr.length) {
        // try private media
        __weak typeof(self) weakSelf = self;
        [[XYZAPIClient sharedClient] fetchPrivateMediaForEid:episode.eid success:^(NSDictionary *json, NSHTTPURLResponse *response) {
            NSString *u = nil;
            NSDictionary *data = json[@"data"] ?: json;
            if ([data isKindOfClass:[NSDictionary class]]) {
                u = data[@"url"] ?: data[@"mediaUrl"] ?: data[@"source"][@"url"];
                if (!u && [data[@"media"] isKindOfClass:[NSDictionary class]]) {
                    u = data[@"media"][@"url"] ?: data[@"media"][@"source"][@"url"];
                }
            }
            if ([u isKindOfClass:[NSString class]] && u.length) {
                episode.mediaURL = u;
                [weakSelf startPlaybackWithURL:u episode:episode];
            } else {
                // reload episode detail
                [[XYZAPIClient sharedClient] fetchEpisodeWithEid:episode.eid success:^(NSDictionary *ej, NSHTTPURLResponse *r) {
                    XYZEpisode *full = [XYZEpisode episodeWithDictionary:ej];
                    if (full.mediaURL.length) {
                        episode.mediaURL = full.mediaURL;
                        [weakSelf startPlaybackWithURL:full.mediaURL episode:episode];
                    } else {
                        [[NSNotificationCenter defaultCenter] postNotificationName:XYZPlayerDidUpdateNotification object:nil userInfo:@{@"error": @"无法获取音频地址"}];
                    }
                } failure:^(NSError *error, NSInteger statusCode, NSDictionary *j) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:XYZPlayerDidUpdateNotification object:nil userInfo:@{@"error": error.localizedDescription ?: @"播放失败"}];
                }];
            }
        } failure:^(NSError *error, NSInteger statusCode, NSDictionary *json) {
            [[XYZAPIClient sharedClient] fetchEpisodeWithEid:episode.eid success:^(NSDictionary *ej, NSHTTPURLResponse *r) {
                XYZEpisode *full = [XYZEpisode episodeWithDictionary:ej];
                if (full.mediaURL.length) {
                    episode.mediaURL = full.mediaURL;
                    [weakSelf startPlaybackWithURL:full.mediaURL episode:episode];
                }
            } failure:nil];
        }];
        return;
    }
    [self startPlaybackWithURL:urlStr episode:episode];
}

- (void)startPlaybackWithURL:(NSString *)urlStr episode:(XYZEpisode *)episode {
    [self ensureAudioSession];
    if (self.timeObserver && self.player) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) return;
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    if (!self.player) {
        self.player = [AVPlayer playerWithPlayerItem:item];
    } else {
        [self.player replaceCurrentItemWithPlayerItem:item];
    }
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 2) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [[NSNotificationCenter defaultCenter] postNotificationName:XYZPlayerDidUpdateNotification object:weakSelf];
    }];
    [self.player play];
    [self updateNowPlaying];
    [[NSNotificationCenter defaultCenter] postNotificationName:XYZPlayerDidUpdateNotification object:self];
}

- (void)updateNowPlaying {
    if (!self.currentEpisode) return;
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[MPMediaItemPropertyTitle] = self.currentEpisode.title ?: @"";
    info[MPMediaItemPropertyArtist] = self.currentEpisode.podcastTitle ?: @"小宇宙";
    info[MPMediaItemPropertyPlaybackDuration] = @(self.duration > 0 ? self.duration : self.currentEpisode.duration);
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.currentTime);
    info[MPNowPlayingInfoPropertyPlaybackRate] = @(self.isPlaying ? 1.0 : 0.0);
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
}

- (void)togglePlayPause {
    if (self.isPlaying) [self pause]; else [self play];
}

- (void)pause {
    [self.player pause];
    [self updateNowPlaying];
    [[NSNotificationCenter defaultCenter] postNotificationName:XYZPlayerDidUpdateNotification object:self];
}

- (void)play {
    [self.player play];
    [self updateNowPlaying];
    [[NSNotificationCenter defaultCenter] postNotificationName:XYZPlayerDidUpdateNotification object:self];
}

- (void)seekTo:(NSTimeInterval)time {
    CMTime t = CMTimeMakeWithSeconds(time, NSEC_PER_SEC);
    [self.player seekToTime:t];
}

- (void)seekBy:(NSTimeInterval)delta {
    [self seekTo:MAX(0, self.currentTime + delta)];
}

@end
