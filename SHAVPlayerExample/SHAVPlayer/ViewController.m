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

@interface ViewController ()<SHAVPlayerDelegate>

@property (nonatomic, strong) SHAVPlayer *player;

@property (weak, nonatomic) IBOutlet UILabel *timeLab;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;

//是否全屏
@property (nonatomic, assign) BOOL isFullScreen;
//是否拖动中
@property (nonatomic, assign) BOOL isDrag;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.player = [[SHAVPlayer alloc]init];
    self.player.backgroundColor = [UIColor blackColor];
    self.player.frame = CGRectMake(0, 0, self.view.frame.size.width, 200);
    self.player.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.player.url = [NSURL URLWithString:@"http://flv3.bn.netease.com/videolib3/1707/03/bGYNX4211/SD/bGYNX4211-mobile.mp4"];
    self.player.delegate = self;
    
    [self.player preparePlay];

    [self.view addSubview:self.player];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
}

#pragma mark - SHAVPlayerDelegate
#pragma mark 资源当前时长(S)
- (void)shAVPlayWithCurrentTime:(NSInteger)currentTime{
    
    if (self.isDrag) {//拖动中不设置
        return;
    }
    [self.slider setValue:currentTime animated:YES];
    [self sliderChanged:self.slider];
}

#pragma mark 资源缓存时长(S)
- (void)shAVPlayWithCacheTime:(NSInteger)cacheTime{
    NSLog(@"当前缓冲时间 --- %ld S",(long)cacheTime);
    self.progress.progress = (cacheTime / self.slider.maximumValue);
}

#pragma mark 播放状态
- (void)shAVPlayStatusChange:(SHAVPlayStatus)status{
    switch (status) {
        case SHAVPlayStatus_readyToPlay://准备播放
        {
            NSLog(@"播放状态 --- 准备播放");
            self.slider.maximumValue = self.player.totalTime;
            self.timeLab.text = [NSString stringWithFormat:@"00:00/%@",[SHAVPlayer dealTime:self.player.totalTime]];
        }
            break;
        case SHAVPlayStatus_canPlay://可以播放
        {
            NSLog(@"播放状态 --- 可以播放");
        }
            break;
        case SHAVPlayStatus_play://播放
        {
            NSLog(@"播放状态 --- 播放");
        }
            break;
        case SHAVPlayStatus_pause://暂停
        {
            NSLog(@"播放状态 --- 暂停");
        }
            break;
        case SHAVPlayStatus_end://完成
        {
            NSLog(@"播放状态 --- 完成");
            if (self.isDrag) {//拖动中不设置
                return;
            }
            [self.player stop];
        }
            break;
        case SHAVPlayStatus_loading://加载中
        {
            NSLog(@"播放状态 --- 加载中");
        }
            break;
        case SHAVPlayStatus_failure://失败
        {
            NSLog(@"播放状态 --- 失败");
        }
            break;
        default:
            break;
    }
}

#pragma mark - action
#pragma mark 滑块离开
- (IBAction)sliderEnd:(id)sender {
    
    self.isDrag = NO;
    //离开进行跳转
    [self.player seekToTime:self.slider.value block:nil];
}

#pragma mark 滑块按住
- (IBAction)sliderStart:(id)sender {
    self.isDrag = YES;
}

#pragma mark 滑块改变
- (IBAction)sliderChanged:(id)sender {
    
    self.timeLab.text = [NSString stringWithFormat:@"%@/%@",[SHAVPlayer dealTime:self.slider.value],[self.timeLab.text componentsSeparatedByString:@"/"].lastObject];
}

#pragma mark 按钮点击
- (IBAction)btnAction:(UIButton *)sender {
    
    switch (sender.tag) {
        case 10:
        {
            [self.player play];
        }
            break;
        case 11:
        {
            [self.player pause];
        }
            break;
        case 12:
        {
            AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
            self.isFullScreen = !self.isFullScreen;
            
            if (self.isFullScreen) {
                //支持旋转
                app.isRotation = YES;
                [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
                
                [UIView animateWithDuration:0.25 animations:^{
                    self.player.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                }];
                
            }else{
                //不支持旋转
                app.isRotation = NO;
                [self interfaceOrientation:UIInterfaceOrientationPortrait];
                
                [UIView animateWithDuration:0.25 animations:^{
                    self.player.frame = CGRectMake(0, 0, self.view.frame.size.width, 200);
                }];
            }
        }
            break;
        default:
            break;
    }
}

- (void)interfaceOrientation:(UIInterfaceOrientation)orientation{
    
    //强制转换
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (app.isRotation) {
        app.isRotation = NO;
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
    }
}

@end
