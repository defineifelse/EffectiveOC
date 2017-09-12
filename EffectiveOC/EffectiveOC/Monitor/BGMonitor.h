//
//  BGMonitor.h
//  EffectiveOC
//
//  Created by Pan on 2016/12/30.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BGMonitor : NSObject

+ (instancetype)sharedInstance;

- (void)start;

@end
