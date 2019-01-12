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
//上一个时间
@property (nonatomic, assign) NSInteger lastTime;

@end

@implementation SHAVPlayer

- (void)dealloc {
    //清除播放器
    [self cleanPlayer];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {//播放状态
        
        //获取对象
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] intValue];
        
        switch (status) {
            case AVPlayerStatusReadyToPlay://准备播放
            {
                //获取资源总时长
                CMTime duration = playerItem.asset.duration;
                //转换成秒
                NSInteger totalTime = CMTimeGetSeconds(duration);
                
                if (totalTime) {
                    //回调
                    if ([self.delegate respondsToSelector:@selector(shAVPlayWithTotalTime:)]) {
                        [self.delegate shAVPlayWithTotalTime:totalTime];
                    }
                }
                
                if (self.isAutomatic) {
                    [self play];
                }
                //监听播放进度
                [self addPeriodicTime];
            }
                break;
            case AVPlayerItemStatusFailed:case AVPlayerItemStatusUnknown://播放错误、未知错误
            {
                if ([self.delegate respondsToSelector:@selector(shAVPlayFailedWithError:)]) {
                    [self.delegate shAVPlayFailedWithError:playerItem.error];
                }
            }
                break;
            default:
                break;
        }
        
        //移除监听
        [object removeObserver:self forKeyPath:@"status"];
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {//缓存进度
        
        //获取缓存时间
        NSInteger cacheTime = [self getCacheTime];
        //回调
        if ([self.delegate respondsToSelector:@selector(shAVPlayWithCacheTime:)]) {
            [self.delegate shAVPlayWithCacheTime:cacheTime];
        }
    }else if ([keyPath isEqualToString:@"frame"]){
        
        CGRect frame = [change[NSKeyValueChangeNewKey] CGRectValue];
        self.playerLayer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    }
}

#pragma mark 监听播放进度
- (void)addPeriodicTime{
    
    __weak typeof(self) weakSelf = self;
    //监听当前播放进度
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        
        //计算当前在第几秒
        NSInteger currentTime = CMTimeGetSeconds(time);
        
        //避免重复调用
        if (currentTime == weakSelf.lastTime) {
            return ;
        }
        weakSelf.lastTime = currentTime;
        
        //回调
        if ([weakSelf.delegate respondsToSelector:@selector(shAVPlayWithCurrentTime:)]) {
            [weakSelf.delegate shAVPlayWithCurrentTime:currentTime];
        }
    }];
}

#pragma mark 播放完成
- (void)playFinished {
    //回调
    if ([self.delegate respondsToSelector:@selector(shAVPlayEnd)]) {
        [self.delegate shAVPlayEnd];
    }
}

#pragma mark 获取缓存时间
- (NSInteger)getCacheTime{
    
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    //获取缓冲区域
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    NSInteger statrtTime = CMTimeGetSeconds(timeRange.start);
    NSInteger durationTime = CMTimeGetSeconds(timeRange.duration);
    //计算缓冲总进度
    NSInteger result =  statrtTime + durationTime;
    
    return result;
}

#pragma mark - 公共方法
#pragma mark 准备播放
- (void)preparePlay{

    [self.playerLayer removeFromSuperlayer];
    
    //初始化
    self.playerItem = [AVPlayerItem playerItemWithURL:self.url];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    //创建播放器层
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.frame = self.bounds;
    [self.layer addSublayer:self.playerLayer];
    
    //监听status属性
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听loadedTimeRanges属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监听frame
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    //播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    
    if (self.isBackPlay) {//支持后台播放
        //不随着静音键和屏幕关闭而静音
        //设置锁屏仍能继续播放
        [[AVAudioSession sharedInstance] setActive:YES error: nil];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        //让app支持接受远程控制事件
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
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

#pragma mark 处理时间
- (NSString *)dealTime:(NSTimeInterval)time{
    
    if (isnan(time)) {
        return @"00:00";
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    
    if (time/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    return [formatter stringFromDate:date];
}

#pragma mark 清除播放器
- (void)cleanPlayer{
    
    [self pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.playerItem];
}

@end
