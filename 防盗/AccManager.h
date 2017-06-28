//
//  AccManager.h
//  elf_vrdrone
//
//  Created by elecfreaks on 15/8/6.
//  Copyright (c) 2015年 elecfreaks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@interface AccManager : NSObject

@property (nonatomic, readonly) CMMotionManager *motionManager;

+(id)shareManager;

@end
