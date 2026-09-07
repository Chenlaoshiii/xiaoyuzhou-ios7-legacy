#import "XYZPlayerManager.h"
#import <UIKit/UIKit.h>

NSString * const XYZPlayerDidUpdateNotification = @"XYZPlayerDidUpdateNotification";

@implementation XYZPlayerManager

+ (instancetype)sharedManager {
    static XYZPlayerManager *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ m = [[XYZPlayerManager alloc] init]; });
    return m;
}

- (BOOL)isPlaying { return NO; }

- (NSTimeInterval)currentTime { return 0; }

- (NSTimeInterval)duration {
    return self.currentEpisode ? self.currentEpisode.duration : 0;
}

- (void)playEpisode:(XYZEpisode *)episode {
    if (!episode) return;
    self.currentEpisode = episode;
    [[NSNotificationCenter defaultCenter] postNotificationName:XYZPlayerDidUpdateNotification object:self];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"播放稍后"
                                                    message:@"本构建未链接 AVFoundation，音频播放稍后再开。登录/搜索/列表可用。"
                                                   delegate:nil
                                          cancelButtonTitle:@"好"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)togglePlayPause {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"播放稍后"
                                                    message:@"音频播放稍后启用。"
                                                   delegate:nil
                                          cancelButtonTitle:@"好"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)pause {}
- (void)play { [self togglePlayPause]; }
- (void)seekTo:(NSTimeInterval)time { (void)time; }
- (void)seekBy:(NSTimeInterval)delta { (void)delta; }

@end
