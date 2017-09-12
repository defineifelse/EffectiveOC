//
//  BGMonitorFPS.m
//  EffectiveOC
//
//  Created by Pan on 2016/12/30.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import "BGMonitorFPS.h"

@implementation BGMonitorFPS {
    UILabel *_FPSLabel;
    CADisplayLink *_displayLink;
    NSUInteger _count;
    NSTimeInterval _lastTime;
}

- (void)dealloc {
    [self stop];
}

- (void)start
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    _FPSLabel = [self fpsLabel];
    _FPSLabel.frame = CGRectMake(window.frame.size.width-60, 100, 60, 20);
    [window addSubview:_FPSLabel];
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stop
{
    [_displayLink invalidate];
    [_FPSLabel removeFromSuperview];
}

- (void)tick:(CADisplayLink *)link {
    if (_lastTime == 0) {
        _lastTime = link.timestamp;
        return;
    }
    
    _count++;
    NSTimeInterval delta = link.timestamp - _lastTime;
    if (delta < 1) return;
    _lastTime = link.timestamp;
    float fps = _count / delta;
    _count = 0;
    
    CGFloat progress = fps / 60.0;
    UIColor *color = [UIColor colorWithHue:0.27 * (progress - 0.2) saturation:1 brightness:0.9 alpha:1];
    _FPSLabel.textColor = color;
    _FPSLabel.text = [NSString stringWithFormat:@"%d FPS",(int)round(fps)];
}

- (UILabel *)fpsLabel {
    UILabel *label = [[UILabel alloc] init];
    label.layer.cornerRadius = 3;
    label.clipsToBounds = YES;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    return label;
}

@end
