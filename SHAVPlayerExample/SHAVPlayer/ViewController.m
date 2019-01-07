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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.player = [[SHAVPlayer alloc]init];
    self.player.backgroundColor = [UIColor blackColor];
    self.player.frame = CGRectMake(0, 0, self.view.frame.size.width, 200);
    self.player.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.player.videoUrl = [NSURL URLWithString:@"http://flv3.bn.netease.com/videolib3/1707/03/bGYNX4211/SD/bGYNX4211-mobile.mp4"];
    self.player.delegate = self;
    [self.player preparePlay];
    [self.view addSubview:self.player];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
}

#pragma mark - SHAVPlayerDelegate
#pragma mark 视频总时长(S)
- (void)videoPlayWithTotalTime:(NSInteger)totalTime{
    
    //加载成功
    self.slider.maximumValue = totalTime;
    self.timeLab.text = [NSString stringWithFormat:@"00:00/%@",[self dealTime:self.slider.maximumValue]];
}

#pragma mark 视频当前时长(S)
- (void)videoPlayWithCurrentTime:(NSInteger)currentTime{
    
    //开始播放了
    self.timeLab.text = [NSString stringWithFormat:@"%@/%@",[self dealTime:currentTime],[self dealTime:self.slider.maximumValue]];
    [self.slider setValue:currentTime animated:YES];
}

#pragma mark 视频缓存进度(S)
- (void)videoPlayCacheProgressWithProgress:(CGFloat)progress{
    [self.progress setProgress:progress animated:YES];
}

#pragma mark 视频播放错误
- (void)videoPlayFailedWithError:(NSError *)error{
    NSLog(@"视频播放错误 --- %@",[error description]);
}

#pragma mark 视频播放完成
- (void)videoPlayEnd{
    NSLog(@"视频播放完成");
    [self.player stop];
}

#pragma mark 处理时间
- (NSString *)dealTime:(CGFloat)time{
    
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


#pragma mark - action
#pragma mark 滑块改变
- (IBAction)sliderChange:(id)sender {
    
    if (self.slider.value == 0.000000) {
        [self.player seekToTime:0];
    }
}

#pragma mark 滑块离开
- (IBAction)sliderEnd:(id)sender {
    NSLog(@"跳转到 --- %f",self.slider.value);
    [self.player seekToTime:self.slider.value];
}

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
            if (!self.player.isFullScreen) {
//                CGRect frame = self.player.frame;
//                frame.size.height = self.view.frame.size.height;
//                self.player.frame = frame;
                //支持旋转
                app.isRotation = YES;
                [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
                
            }else{
                //不支持旋转
                app.isRotation = NO;
                [self interfaceOrientation:UIInterfaceOrientationPortrait];
            }
            
            self.player.isFullScreen = !self.player.isFullScreen;
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
