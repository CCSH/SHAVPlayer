//
//  SHAVPlayer.m
//  SHAVPlayer
//
//  Created by CSH on 2019/1/3.
//  Copyright © 2019 CSH. All rights reserved.
//

#import "SHAVPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface SHAVPlayer ()

//播放器对象
@property (nonatomic, strong) AVPlayer *player;
//播放器管理器
@property (nonatomic, strong) AVPlayerItem *playerItem;
//播放器播放层
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
//当前时间
@property (nonatomic, assign) NSInteger currentTime;

//播放监听
@property (nonatomic, assign) id timeObserver;

//锁屏信息
@property (nonatomic, strong) NSMutableDictionary *lockInfo;

@end

@implementation SHAVPlayer

#pragma mark - 懒加载
- (AVPlayer *)player{
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

- (AVPlayerLayer *)playerLayer{
    if (!_playerLayer) {
        _playerLayer = [[AVPlayerLayer alloc]init];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        _playerLayer.frame = self.bounds;
        [self.layer addSublayer:_playerLayer];
    }
    return _playerLayer;
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
                
                if (totalTime > 0) {
                    
                    self.totalTime = totalTime;
                    //回调
                    if ([self.delegate respondsToSelector:@selector(shAVPlayWithTotalTime:)]) {
                        [self.delegate shAVPlayWithTotalTime:totalTime];
                    }
                }
                //监听播放进度
                [self addPlayProgress];
                //自动播放
                if (self.isAutomatic) {
                    [self play];
                }
            }
                break;
                case AVPlayerItemStatusFailed:case AVPlayerItemStatusUnknown://播放错误、未知错误
            {
                if ([self.delegate respondsToSelector:@selector(shAVPlayStatusChange:)]) {
                    [self.delegate shAVPlayStatusChange:SHAVPlayStatus_failure];
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
    }else if ([keyPath isEqualToString:@"frame"]){//视图frame
        
        self.playerLayer.frame = self.bounds;
    }else if ([keyPath isEqualToString:@"rate"]){//播放器状态
        
        if ([self.delegate respondsToSelector:@selector(shAVPlayStatusChange:)]) {
            
            if (self.player.rate == 1) {
                [self.delegate shAVPlayStatusChange:SHAVPlayStatus_play];
            }else{
                [self.delegate shAVPlayStatusChange:SHAVPlayStatus_pause];
            }
            
        }
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){//缓存为空

        if ([self.delegate respondsToSelector:@selector(shAVPlayStatusChange:)]) {
            [self.delegate shAVPlayStatusChange:SHAVPlayStatus_loading];
        }
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){//缓存可以用
        
        if ([self.delegate respondsToSelector:@selector(shAVPlayStatusChange:)]) {
            [self.delegate shAVPlayStatusChange:SHAVPlayStatus_prepare];
        }
    }
}

#pragma mark 监听播放进度
- (void)addPlayProgress{
    
    __weak typeof(self) weakSelf = self;
    //监听当前播放进度
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        
        //计算当前在第几秒
        NSInteger currentTime = CMTimeGetSeconds(time);
        
        //避免重复调用
        if (currentTime == weakSelf.currentTime) {
            return ;
        }
        weakSelf.currentTime = currentTime;
        
        if (weakSelf.isBackPlay) {//后台播放

            // 设置歌曲的总时长
            [weakSelf.lockInfo setObject:@(weakSelf.totalTime) forKey:MPMediaItemPropertyPlaybackDuration];
            // 设置当前时间
            [weakSelf.lockInfo setObject:@(currentTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
            
            // 音乐信息赋值给获取锁屏中心的nowPlayingInfo属性
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:weakSelf.lockInfo];
        }
        
        //回调
        if ([weakSelf.delegate respondsToSelector:@selector(shAVPlayWithCurrentTime:)]) {
            [weakSelf.delegate shAVPlayWithCurrentTime:currentTime];
        }
    }];
}

#pragma mark 播放完成
- (void)playFinished {
    //回调
    if ([self.delegate respondsToSelector:@selector(shAVPlayStatusChange:)]) {
        [self.delegate shAVPlayStatusChange:SHAVPlayStatus_end];
    }
}

#pragma mark 中断处理
- (void)handleInterreption{
    [self pause];
}

#pragma mark 移除播放器
- (void)removePlayerOnPlayerLayer {
    self.playerLayer.player = nil;
}

#pragma mark 添加播放器
- (void)resetPlayerToPlayerLayer {
    self.playerLayer.player = self.player;
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

#pragma mark 添加监听
- (void)addKVO{
    
    //监听status属性
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听loadedTimeRanges属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监听frame
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    //监听播放状态
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    
    //监听播放的区域缓存是否为空
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    //缓存可以播放的时候调用
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    //播放完成通知
    [center addObserver:self selector:@selector(playFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    //中断通知
    [center addObserver:self selector:@selector(handleInterreption) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    
    
    if (self.isBackPlay) {//支持后台播放
        
        [center addObserver:self selector:@selector(removePlayerOnPlayerLayer) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [center addObserver:self selector:@selector(resetPlayerToPlayerLayer) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        //不随着静音键和屏幕关闭而静音
        //设置锁屏仍能继续播放
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
        
        //接收远程控制
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
        //设置控制方法
        MPRemoteCommandCenter *rcc = [MPRemoteCommandCenter sharedCommandCenter];
        
        //界面控制
        [rcc.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            [self play];
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        
        [rcc.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            [self pause];
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        
        //播放与暂停(耳机线控)
        [rcc.togglePlayPauseCommand setEnabled:YES];
        [rcc.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            if (self.player.rate) {
                [self pause];
            }else{
                [self play];
            }
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        
        //拖拽进度
        if (@available(iOS 9.1, *)) {
            
            [rcc.changePlaybackPositionCommand setEnabled:YES];
            [rcc.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
                
                //跳转时间
                MPChangePlaybackPositionCommandEvent *playEvent = (MPChangePlaybackPositionCommandEvent *)event;
                //进行跳转
                [self seekToTime:playEvent.positionTime block:nil];

                return MPRemoteCommandHandlerStatusSuccess;
            }];
        } else {
            // Fallback on earlier versions
        }
        
        
        //上一首
        [rcc.previousTrackCommand setEnabled:YES];
        [rcc.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            
            return MPRemoteCommandHandlerStatusSuccess;
        }];
    
        
        //下一首
        [rcc.nextTrackCommand setEnabled:YES];
        [rcc.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            
            return MPRemoteCommandHandlerStatusSuccess;
        }];
    }
}

#pragma mark - 公共方法
#pragma mark 准备播放
- (void)preparePlay{
    
    [self stop];
    //初始化
    self.playerItem = [AVPlayerItem playerItemWithURL:self.url];
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    self.playerLayer.player = self.player;
    
    if (self.isBackPlay) {//后台播放
        //锁屏信息
        self.lockInfo = [NSMutableDictionary dictionary];
        // 1、设置标题
        if (self.title) {
            [self.lockInfo setObject:self.title forKey:MPMediaItemPropertyTitle];
        }
        // 2、设置歌曲名
        if (self.name) {
            [self.lockInfo setObject:self.name forKey:MPMediaItemPropertyAlbumTitle];
        }
        // 3、设置艺术家
        if (self.artist) {
            [self.lockInfo setObject:self.artist forKey:MPMediaItemPropertyArtist];
        }
        // 4、设置封面的图片
        if (self.coverImage) {
            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:self.coverImage];
            [self.lockInfo setObject:artwork forKey:MPMediaItemPropertyArtwork];
        }
    }
    
    //清除监听
    [self removeKVO];
    //添加监听
    [self addKVO];
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
    [self seekToTime:0 block:nil];
}

#pragma mark 跳转多少秒
- (void)seekToTime:(NSTimeInterval)time block:(void (^)(BOOL))block{
    
    //向下取整
    time =  (int)time;
    
    //不能太大
    if (time > self.totalTime) {
        time = self.totalTime;
    }
    //不能太小
    if (time < 0) {
        time = 0;
    }

    CMTime changedTime = CMTimeMakeWithSeconds(time, 1);
    
    [self.player seekToTime:changedTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:block];
}

#pragma mark 处理时间
+ (NSString *)dealTime:(NSTimeInterval)time{
    
    if (isnan(time)) {
        return @"00:00";
    }
    
    NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
    formatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
    formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    
    if (time/3600 >= 1) {
        formatter.allowedUnits = kCFCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    } else {
        formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    }
    
    NSString *dealTime = [formatter stringFromTimeInterval:time];
    
    if (dealTime.length == 7  || dealTime.length == 4) {
        dealTime = [NSString stringWithFormat:@"0%@",dealTime];
    }
    return dealTime;
}

#pragma mark 清除播放器
- (void)removeKVO{
    [self pause];
    
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self.player];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    MPRemoteCommandCenter *rcc = [MPRemoteCommandCenter sharedCommandCenter];
    [rcc.playCommand removeTarget:self];
    [rcc.pauseCommand removeTarget:self];
    [rcc.togglePlayPauseCommand removeTarget:self];
}

@end
