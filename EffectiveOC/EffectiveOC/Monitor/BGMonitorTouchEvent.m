//
//  BGMonitorTouchEvent.m
//  EffectiveOC
//
//  Created by Pan on 2016/12/30.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import "BGMonitorTouchEvent.h"
#import <objc/runtime.h>

@interface BGMonitorTouchEvent ()

@end

@implementation BGMonitorTouchEvent

- (void)start
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self hookMethodWithOriginalClass:[UIApplication class] swizzledClass:[self class] originalSEL:@selector(sendEvent:) swizzledSEL:@selector(bg_sendEvent:)];
        [self hookMethodWithOriginalClass:[UIApplication class] swizzledClass:[self class] originalSEL:@selector(sendAction:to:from:forEvent:) swizzledSEL:@selector(bg_sendAction:to:from:forEvent:)];
        
    });
}

- (void)bg_sendEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeTouches) {
        [event.allTouches enumerateObjectsUsingBlock:^(UITouch * _Nonnull touch, BOOL * _Nonnull stop) {
            NSMutableString *mStr = [NSMutableString stringWithString:@"检测到点击事件: "];
            [mStr appendString:@"点击状态"];
            [mStr appendString:[self stateWithTouch:touch]];
            printf("%s\n", [mStr UTF8String]);
        }];
    }
    [self bg_sendEvent:event];
}

- (BOOL)bg_sendAction:(SEL)action to:(nullable id)target from:(nullable id)sender forEvent:(nullable UIEvent *)event
{
    if (![NSStringFromSelector(action) isEqualToString:@"_sendAction:withEvent:"]) {
        NSMutableString *mStr = [NSMutableString stringWithString:@"检测到点击事件传递: "];
        [event.allTouches enumerateObjectsUsingBlock:^(UITouch * _Nonnull touch, BOOL * _Nonnull stop) {
            [mStr appendFormat:@"%@", NSStringFromClass([touch.view class])];
            [mStr appendString:@"点击状态"];
            [mStr appendString:[self stateWithTouch:touch]];
            [mStr appendString:@" ->"];
        }];
        [mStr appendFormat:@" %@ -> %@ 调用 %@ 方法", NSStringFromClass([sender class]), NSStringFromClass([target class]), NSStringFromSelector(action)];
        printf("%s\n", [mStr UTF8String]);
    }
    return [self bg_sendAction:action to:target from:sender forEvent:event];
}


- (void)hookMethodWithOriginalClass:(Class)originalClass swizzledClass:(Class)swizzledClass originalSEL:(SEL)originalSEL swizzledSEL:(SEL)swizzledSEL
{
    Method originalMethod = class_getInstanceMethod(originalClass, originalSEL);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSEL);
    
    if (!originalMethod || !swizzledMethod) {
        return;
    }
    
    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    
    class_replaceMethod(originalClass,swizzledSEL,originalIMP,originalType);
    class_replaceMethod(originalClass,originalSEL,swizzledIMP,swizzledType);
}

- (NSString *)stateWithTouch:(UITouch *)touch
{
    NSString *state = nil;
    switch (touch.phase) {
        case UITouchPhaseBegan:
            state = @"(开始)";
            break;
        case UITouchPhaseMoved:
            state = @"(移动)";
            break;
        case UITouchPhaseEnded:
            state = @"(结束)";
            break;
        case UITouchPhaseCancelled:
            state = @"(取消)";
            break;
        case UITouchPhaseStationary:
            state = @"(固定)";
            break;
    }
    return state;
}


@end
