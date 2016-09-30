//
//  LBVideoPlayerController.m
//  news
//
//  Created by li  bo on 16/9/25.
//  Copyright © 2016年 li  bo. All rights reserved.
//

#import "LBVideoPlayerController.h"
#import <MediaPlayer/MediaPlayer.h>
@interface LBVideoPlayerController ()
/** 播放器 */
@property (nonatomic, strong) MPMoviePlayerController *playerController;

@end

@implementation LBVideoPlayerController

- (MPMoviePlayerController *)playerController
{

    if (_playerController == nil) {
        // 1.获取视频的URL
        NSURL *url = [NSURL URLWithString:self.videoSrc];

        // 2.创建控制器
        _playerController = [[MPMoviePlayerController alloc] initWithContentURL:url];

        // 3.设置控制器的View的位置
        _playerController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width * 9 / 16);

        // 4.将View添加到控制器上
        [self.view addSubview:_playerController.view];

        // 5.设置属性
        _playerController.controlStyle = MPMovieControlStyleDefault;
    }
    return _playerController;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *backBtn = [[UIButton alloc] init];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [backBtn sizeToFit];
    backBtn.center = self.view.center;
    [self.view addSubview:backBtn];
    [backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    self.view.backgroundColor = [UIColor grayColor];

    [self.playerController play];

}


-(void)back
{
    [self.playerController stop];
    self.playerController = nil;

    [self dismissViewControllerAnimated:YES completion:nil];

}



@end
