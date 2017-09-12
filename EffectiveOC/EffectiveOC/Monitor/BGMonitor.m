//
//  BGMonitor.m
//  EffectiveOC
//
//  Created by Pan on 2016/12/30.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import "BGMonitor.h"

@implementation BGMonitor

+ (instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)start
{
    
}

@end
