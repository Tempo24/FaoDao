//
//  AccManager.m
//  elf_vrdrone
//
//  Created by elecfreaks on 15/8/6.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import "AccManager.h"

static AccManager *shareManager;

@implementation AccManager
@synthesize motionManager = _motionManager;

+(id)shareManager {
    if (shareManager == nil) {
        shareManager = [[super alloc]init];
        return shareManager;
    }
    return shareManager;
}

-(CMMotionManager *)motionManager {
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc]init];
    }
    return _motionManager;
}

@end
