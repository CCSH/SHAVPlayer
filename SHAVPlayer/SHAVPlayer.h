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

//资源总时长(S)
- (void)shAVPlayWithTotalTime:(NSInteger)totalTime;
//资源当前时长(S)
- (void)shAVPlayWithCurrentTime:(NSInteger)currentTime;
//资源缓存时长(S)
- (void)shAVPlayWithCacheTime:(NSInteger)cacheTime;

//资源播放错误
- (void)shAVPlayFailedWithError:(NSError *)error;
//资源播放完成
- (void)shAVPlayEnd;

//播放状态改变
- (void)shAVPlayStatusChange:(BOOL)isPlay;
//是否加载中
- (void)shAVPlayLoading:(BOOL)isLoading;

@end

@interface SHAVPlayer : UIView

//资源url
@property (nonatomic, copy) NSURL *url;
//代理
@property (nonatomic, weak) id<SHAVPlayerDelegate> delegate;
//是否自动播放
@property (nonatomic, assign) BOOL isAutomatic;
//是否后台播放(需要设置app 后台模式 支持)
@property (nonatomic, assign) BOOL isBackPlay;

//锁屏音频信息(可以不设置)
//标题
@property (nonatomic, copy) NSString *title;
//音乐名
@property (nonatomic, copy) NSString *name;
//作者
@property (nonatomic, copy) NSString *artist;
//封面图片
@property (nonatomic, copy) UIImage *coverImage;
//总时长(如果能获取到 内部有设置)
@property (nonatomic, assign) NSInteger totalTime;

//准备播放
- (void)preparePlay;
//开始播放
- (void)play;
//暂停播放
- (void)pause;
//停止播放
- (void)stop;

//跳转多少秒
- (void)seekToTime:(NSTimeInterval)time block:(void (^)(BOOL finish))block;

//清除播放器
- (void)removeKVO;

//处理时间
+ (NSString *)dealTime:(NSTimeInterval)time;


@end

NS_ASSUME_NONNULL_END
