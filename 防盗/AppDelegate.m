//
//  AppDelegate.m
//  防盗
//
//  Created by Tempo on 16/10/24.
//  Copyright © 2016年 Tempo. All rights reserved.
//

#import "AppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ViewController.h"
@interface AppDelegate ()<AVAudioPlayerDelegate>{

    SystemSoundID myAlertSound;
    AVAudioPlayer *player;
    
    MPVolumeView *volumeView;
    UISlider* volumeViewSlider;
    
    NSTimer *myTimer;
    int _time;

}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
   
    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application {
    
    if (kStarApp == YES) {
        //开启后台处理多媒体事件
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        AVAudioSession *session=[AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        //后台播放
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
   
    
    
    
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    if (kStarApp == YES) {
        _time = 0;
        NSString *path = [[NSBundle mainBundle]pathForResource:@"cyx.m4r" ofType:nil];
        NSURL *url = [NSURL fileURLWithPath:path];
        player = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
        player.numberOfLoops = -1;
        [player prepareToPlay];
        [player play];
        
        myTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        
        
        ///////
        UIApplication*   app = [UIApplication sharedApplication];
        __block    UIBackgroundTaskIdentifier bgTask;
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bgTask != UIBackgroundTaskInvalid)
                {
                    bgTask = UIBackgroundTaskInvalid;
                }
            });
        }];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bgTask != UIBackgroundTaskInvalid)
                {
                    bgTask = UIBackgroundTaskInvalid;
                }
            });
        });
        
        BOOL backgroundAccepted = [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^(void){
            
            [self backgroundHandler];
            
        }];
        
        if (backgroundAccepted) {
            NSLog(@"------------------------------Start new alive.");
        }
        [self backgroundHandler];
    }else{
    
        [player pause];
    }
    
    

}


- (void)timerAction{
    
    if (![player isPlaying]) {
        _time += 3;
        if (_time >= 30) {
            [player play];
            NSLog(@"循环播放1kb音频");
            _time = 0;
        }
        
    }
    NSLog(@"%d",_time);
    
}

- (void)backgroundHandler{

    UIApplication*   app = [UIApplication sharedApplication];
    __block    UIBackgroundTaskIdentifier bgTask;
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    });

}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
