//
//  ViewController.m
//  SHAVPlayer
//
//  Created by CSH on 2019/1/3.
//  Copyright © 2019 CSH. All rights reserved.
//

#import "ViewController.h"
#import "SHAVPlayer.h"
#import "AppDelegate.h"

@interface ViewController () < SHAVPlayerDelegate >

@property (nonatomic, strong) IBOutlet SHAVPlayer *player;

@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UILabel *timeLab;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;

//是否全屏
@property (nonatomic, assign) BOOL isFullScreen;
//是否拖动中
@property (nonatomic, assign) BOOL isDrag;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 视频流
//    self.player.url = [NSURL URLWithString:@"http://111.13.111.242/otttv.bj.chinamobile.com/PLTV/88888888/224/3221226226/1.m3u8"];
    // 视频
    self.player.url = [NSURL URLWithString:@"http://pgc.qcdn.xiaodutv.com/1669177126_393756565_20200620041608.mp4?Cache-Control%3Dmax-age-8640000%26responseExpires%3DMon%2C_28_Sep_2020_04%3A16%3A25_GMT=&xcode=f1fb5443800855aa3a6f37061c37658b7102230b81a27fa9&time=1598059319&_=1597975127589"];
    
    self.player.delegate = self;

    [self.player preparePlay];

    [self.view addSubview:self.player];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
}

#pragma mark - SHAVPlayerDelegate
#pragma mark 资源当前时长(S)
- (void)shAVPlayWithCurrentTime:(NSInteger)currentTime
{
    if (self.isDrag)
    { //拖动中不设置
        return;
    }
    if (self.player.isLive) {
        self.slider.maximumValue = currentTime;
        [self.slider setValue:currentTime animated:NO];
    }else{
        [self.slider setValue:currentTime animated:YES];
    }

    [self sliderChanged:self.slider];
}

#pragma mark 资源缓存时长(S)
- (void)shAVPlayWithCacheTime:(NSInteger)cacheTime
{
    NSLog(@"当前缓冲时间 --- %ld S", (long)cacheTime);
    self.progress.progress = (cacheTime / self.slider.maximumValue);
}

#pragma mark 播放状态
- (void)shAVPlayStatusChange:(SHAVPlayStatus)status message:(NSString *)message
{
    switch (status)
    {
        case SHAVPlayStatus_readyToPlay: //准备播放
        {
            NSLog(@"播放状态 --- 准备播放");
            if (self.player.isLive)
            {
                self.timeLab.text = @"直播";
            }
            else
            {
                self.slider.maximumValue = self.player.totalTime;
                self.timeLab.text = [NSString stringWithFormat:@"00:00/%@", [SHAVPlayer dealTime:self.player.totalTime]];
            }
        }
            break;
        case SHAVPlayStatus_loading: //加载中
        {
            NSLog(@"播放状态 --- 加载中");
            //加载中 出现
        }
            break;
        case SHAVPlayStatus_canPlay: //可以播放
        {
            NSLog(@"播放状态 --- 可以播放");
            //加载中 消失
        }
            break;
        case SHAVPlayStatus_play: //播放
        {
            NSLog(@"播放状态 --- 播放");
            self.playBtn.selected = YES;
        }
            break;
        case SHAVPlayStatus_pause: //暂停
        {
            NSLog(@"播放状态 --- 暂停");
            self.playBtn.selected = NO;
        }
            break;
        case SHAVPlayStatus_end: //完成
        {
            NSLog(@"播放状态 --- 完成");
            if (self.isDrag)
            { //拖动中不设置
                return;
            }
            [self.player stop];
        }
            break;
        case SHAVPlayStatus_failure: //失败
        {
            NSLog(@"播放状态 --- 失败");
        }
            break;
        case SHAVPlayStatus_downEnd: //下载完成(没有格式的路径)
        {
            NSLog(@"播放状态 --- 下载完成路径为：%@", message);
            //可以在此处保存数据
            //            [[NSFileManager defaultManager] copyItemAtPath:message toPath:@"保存的路径.mp4" error:nil];
        }
            break;
        default:
            break;
    }
}

#pragma mark - action
#pragma mark 滑块离开
- (IBAction)sliderEnd:(id)sender
{
    self.isDrag = NO;
    
    if (!self.player.isLive) {
        //拖拽进度 设置加载中 也可以不设置
        [self shAVPlayStatusChange:SHAVPlayStatus_loading message:@""];
        
        //离开进行跳转
        __weak __typeof__(self) weakSelf = self;
        [self.player seekToTime:self.slider.value
                          block:^(BOOL finish) {
            if (finish)
            {
                [weakSelf shAVPlayStatusChange:SHAVPlayStatus_canPlay message:@""];
            }
        }];
    }
    
}

#pragma mark 滑块按住
- (IBAction)sliderStart:(id)sender
{
    self.isDrag = YES;
}

#pragma mark 滑块改变
- (IBAction)sliderChanged:(id)sender
{
    NSString *str = [self.timeLab.text componentsSeparatedByString:@"/"].lastObject;
    if (self.player.isLive)
    {
        str = @"直播";
    }
    self.timeLab.text = [NSString stringWithFormat:@"%@/%@", [SHAVPlayer dealTime:self.slider.value], str];
}

#pragma mark 按钮点击
- (IBAction)btnAction:(UIButton *)sender
{
    switch (sender.tag)
    {
        case 10:
        {
            if (sender.selected)
            {
                [self.player pause];
            }
            else
            {
                [self.player play];
            }
        }
            break;
        case 11:
        {
            AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
            self.isFullScreen = !self.isFullScreen;
            
            if (self.isFullScreen)
            {
                //支持旋转
                app.isRotation = YES;
                [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
            }
            else
            {
                //不支持旋转
                app.isRotation = NO;
                [self interfaceOrientation:UIInterfaceOrientationPortrait];
            }
        }
            break;
        default:
            break;
    }
}

- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
    //强制转换
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)])
    {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        UIInterfaceOrientation val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
        //为了触发监听
        self.player.frame = self.player.frame;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (app.isRotation)
    {
        app.isRotation = NO;
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
    }
}

@end
