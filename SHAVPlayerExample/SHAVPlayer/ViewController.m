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
@property (nonatomic, assign) BOOL isFullScreen;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.player = [[SHAVPlayer alloc]init];
    self.player.backgroundColor = [UIColor blackColor];
    self.player.frame = CGRectMake(0, 0, self.view.frame.size.width, 200);
    self.player.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    self.player.url = [NSURL URLWithString:@"http://flv3.bn.netease.com/videolib3/1707/03/bGYNX4211/SD/bGYNX4211-mobile.mp4"];
//    self.player.isBackPlay = YES;
//    self.player.isAutomatic = YES;
    self.player.delegate = self;

    [self.player preparePlay];

    
    [self.view addSubview:self.player];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
}

#pragma mark - SHAVPlayerDelegate
#pragma mark 资源总时长(S)
- (void)shAVPlayWithTotalTime:(NSInteger)totalTime{

    self.slider.maximumValue = totalTime;
    self.timeLab.text = [NSString stringWithFormat:@"00:00/%@",[self.player dealTime:self.slider.maximumValue]];
}

#pragma mark 资源当前时长(S)
- (void)shAVPlayWithCurrentTime:(NSInteger)currentTime{
    
    self.timeLab.text = [NSString stringWithFormat:@"%@/%@",[self.player dealTime:currentTime],[self.player dealTime:self.slider.maximumValue]];
    [self.slider setValue:currentTime animated:YES];
}

#pragma mark 资源缓存时长(S)
- (void)shAVPlayWithCacheTime:(NSInteger)cacheTime{
    NSLog(@"当前缓冲时间 --- %ld S",(long)cacheTime);
    [self.progress setProgress:(cacheTime / self.slider.maximumValue) animated:YES];
}

#pragma mark 资源播放错误
- (void)shAVPlayFailedWithError:(NSError *)error{
    NSLog(@"视频播放错误 --- %@",[error description]);
}

#pragma mark 资源播放完成
- (void)shAVPlayEnd{
    NSLog(@"视频播放完成");
    [self.player stop];
}

#pragma mark - action
#pragma mark 滑块离开
- (IBAction)sliderEnd:(id)sender {
    NSLog(@"跳转到 --- %f",self.slider.value);
    
    [self.player seekToTime:self.slider.value];
    
//    //如果资源不支持拖拽缓存，则去查看缓存进度是否达到跳转位置，未达到则不进行跳转
//    NSInteger chace =  (NSInteger)(self.progress.progress*self.slider.maximumValue);
//
//    if (self.slider.value < chace - 5) {
//        [self.player seekToTime:self.slider.value];
//    }else{
//        //监听缓存位置，再进行跳转
//
//    }
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
            if (!self.isFullScreen) {
                //支持旋转
                app.isRotation = YES;
                [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
                
            }else{
                //不支持旋转
                app.isRotation = NO;
                [self interfaceOrientation:UIInterfaceOrientationPortrait];
            }
            
            self.isFullScreen = !self.isFullScreen;
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
