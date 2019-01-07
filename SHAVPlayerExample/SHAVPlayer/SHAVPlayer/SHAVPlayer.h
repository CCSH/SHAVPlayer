//
//  SHAVPlayer.h
//  SHAVPlayer
//
//  Created by CSH on 2019/1/3.
//  Copyright © 2019 CSH. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 视频播放代理
 */
@protocol SHAVPlayerDelegate <NSObject>

@optional

//视频总时长(S)
- (void)videoPlayWithTotalTime:(NSInteger)totalTime;
//视频当前时长(S)
- (void)videoPlayWithCurrentTime:(NSInteger)currentTime;

//视频缓存进度
- (void)videoPlayCacheProgressWithProgress:(CGFloat)progress;
//视频播放错误
- (void)videoPlayFailedWithError:(NSError *)error;
//视频播放完成
- (void)videoPlayEnd;

@end

@interface SHAVPlayer : UIView

//视频url
@property (nonatomic, copy) NSURL *videoUrl;
//是否全屏
@property (nonatomic, assign) BOOL isFullScreen;
//代理
@property (nonatomic, weak) id<SHAVPlayerDelegate> delegate;

//跳转多少秒
- (void)seekToTime:(NSInteger)time;

//准备播放
- (void)preparePlay;
//开始播放
- (void)play;
//暂停播放
- (void)pause;
//停止播放
- (void)stop;

@end

NS_ASSUME_NONNULL_END
