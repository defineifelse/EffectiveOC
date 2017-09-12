//
//  BGMonitorLags.m
//  EffectiveOC
//
//  Created by Pan on 2016/12/30.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import "BGMonitorLags.h"

@implementation BGMonitorLags {
    NSInteger _timeoutCount;
    CFRunLoopObserverRef _observer;
    dispatch_semaphore_t _semaphore;
    CFRunLoopActivity _activity;
}

- (void)dealloc {
    [self stop];
}

- (void)stop {
    if (!_observer)
        return;
    
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

- (void)start {
    if (_observer) return;
    [self registerObserver];
}

- (void)registerObserver {
    // 注册RunLoop状态观察
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                       kCFRunLoopAllActivities,
                                       YES,
                                       0,
                                       &runLoopObserverCallBack,
                                       &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    // 信号
    _semaphore = dispatch_semaphore_create(0);
    
    // 在子线程监控时长
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        while (YES && _observer)
        {
            // 假定连续5次超时50ms认为卡顿(当然也包含了单次超时250ms)
            long st = dispatch_semaphore_wait(_semaphore, dispatch_time(DISPATCH_TIME_NOW, 50*NSEC_PER_MSEC));
            if (st != 0)
            {
                if (_activity==kCFRunLoopBeforeSources || _activity==kCFRunLoopAfterWaiting)
                {
                    if (++_timeoutCount < 5)
                        continue;
                    
                    NSLog(@"检测到卡顿");
                }
            }
            _timeoutCount = 0;
        }
    });
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    BGMonitorLags *moniotr = (__bridge BGMonitorLags*)info;
    
    moniotr->_activity = activity;
    
    dispatch_semaphore_t semaphore = moniotr->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

@end
