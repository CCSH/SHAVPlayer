//
//  SHAVPlayer.m
//  SHAVPlayer
//
//  Created by CSH on 2019/1/3.
//  Copyright © 2019 CSH. All rights reserved.
//

#import "SHAVPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface SHAVPlayer ()

//播放器对象
@property (nonatomic, strong) AVPlayer *player;
//播放器管理器
@property (nonatomic, strong) AVPlayerItem *playerItem;
//播放器播放层
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
//播放总时间
@property (nonatomic, assign) NSInteger totalTime;
//上一个时间
@property (nonatomic, assign) NSInteger lastTime;

@end

@implementation SHAVPlayer

- (void)dealloc {
    [self pause];
    
    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    //获取对象
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if (!self.totalTime) {
        //获取视频总长度
        CMTime duration = playerItem.duration;
        //转换成秒
        self.totalTime = CMTimeGetSeconds(duration);
        //回调
        if ([self.delegate respondsToSelector:@selector(videoPlayWithTotalTime:)]) {
            [self.delegate videoPlayWithTotalTime:self.totalTime];
        }
    }
    
    if ([keyPath isEqualToString:@"status"]) {//播放状态
        
        switch (playerItem.status) {
            case AVPlayerStatusReadyToPlay://播放
            {
                __weak typeof(self) weakSelf = self;
                [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
                
                    //计算当前在第几秒
                    NSInteger currentTime = CMTimeGetSeconds(time);
                    
                    if (currentTime == weakSelf.lastTime) {
                        return ;
                    }
                    weakSelf.lastTime = currentTime;
                    
                    //回调
                    if ([weakSelf.delegate respondsToSelector:@selector(videoPlayWithCurrentTime:)]) {
                        [weakSelf.delegate videoPlayWithCurrentTime:currentTime];
                    }
                }];
            }
                break;
            case AVPlayerItemStatusFailed://播放错误
            {
                if ([self.delegate respondsToSelector:@selector(videoPlayFailedWithError:)]) {
                    [self.delegate videoPlayFailedWithError:playerItem.error];
                }
            }
                break;
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {//缓存进度
        
        //获取缓存进度
        NSInteger cacheTime = [self availableDuration] / self.totalTime;
        //回调
        if ([self.delegate respondsToSelector:@selector(videoPlayCacheProgressWithProgress:)]) {
            [self.delegate videoPlayCacheProgressWithProgress:cacheTime];
        }
    }
}

#pragma mark 获取缓存进度
- (NSInteger)availableDuration{
    
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    //获取缓冲区域
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    NSInteger startSeconds = CMTimeGetSeconds(timeRange.start);
    NSInteger durationSeconds = CMTimeGetSeconds(timeRange.duration);
    //计算缓冲总进度
    NSInteger result = startSeconds + durationSeconds;
    
    return result;
}

#pragma mark 播放完成
- (void)playFinished {
    //回调
    if ([self.delegate respondsToSelector:@selector(videoPlayEnd)]) {
        [self.delegate videoPlayEnd];
    }
}

#pragma mark 是否全屏
- (void)setIsFullScreen:(BOOL)isFullScreen{
    _isFullScreen = isFullScreen;
    
    self.playerLayer.frame = self.frame;
}

#pragma mark - 公共方法
#pragma mark 跳转多少秒
- (void)seekToTime:(NSInteger)time{
    
    CGFloat rate = self.player.rate;
    
    CMTime changedTime = CMTimeMakeWithSeconds(time, 1);
    
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        if (finished) {
            if (rate == 1) {
                [weakSelf.player play];
            }else if (rate == 0){
                [weakSelf.player pause];
            }
        }
    }];
}

#pragma mark 准备播放
- (void)preparePlay{
    //初始化
    self.playerItem = [AVPlayerItem playerItemWithURL:self.videoUrl];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    //创建播放器层
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.frame = self.frame;
    [self.layer addSublayer:self.playerLayer];
    
    //监听status属性
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听loadedTimeRanges属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
}

#pragma mark 开始播放
- (void)play{
    //如果在停止播放状态就播放
    if (self.player.rate == 0) {
        [self.player play];
    }
}

#pragma mark 暂停播放
- (void)pause{
    //如果在播放状态就停止
    if (self.player.rate == 1) {
        [self.player pause];
    }
}

#pragma mark 停止播放
- (void)stop{
    [self pause];
    [self seekToTime:0];
}

@end
