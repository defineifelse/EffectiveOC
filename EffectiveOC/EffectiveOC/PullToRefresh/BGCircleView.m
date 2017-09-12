//
//  BGCircleView.m
//  EffectiveOC
//
//  Created by Pan on 16/3/27.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import "BGCircleView.h"

#define kBGCircleScaleDuration 0.6
#define kBGCircleRotateDuration 1.0

@interface BGCircleView ()

@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) BOOL isRotating;

@end

@implementation BGCircleView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];

        _radius = 9;
        _circleColor = [UIColor colorWithRed:(150)/255.0f green:(150)/255.0f blue:(150)/255.0f alpha:1.0];
        
        CALayer *maskLayer = [CALayer layer];
        maskLayer.contents = (id)[[self angleMaskImage] CGImage];
        maskLayer.frame = self.bounds;
        self.layer.mask = maskLayer;
        
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, self.circleColor.CGColor);
    CGContextSetLineWidth(context, 3.0f);
    
    CGFloat radius = _radius;
    static CGFloat startAngle = M_PI;
    CGFloat endAngle = startAngle + _progress * (M_PI * 2) ;
    CGContextAddArc(context, CGRectGetWidth(self.frame) / 2, CGRectGetHeight(self.frame) / 2, radius, startAngle, endAngle, 0);
    
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    if (progress < 1.0) {
        [self setNeedsDisplay];
    }else{
        [self startAnimating];
    }
}

- (void)startAnimating {
    if (self.isRotating) {
        return;
    }
    _progress = 1.0;
    [self setNeedsDisplay];
    
    self.isRotating = YES;
    [self.layer removeAllAnimations];
    
    [self.layer addAnimation:[self scaleAnimation] forKey:@"scaleAnimation"];
    [self.layer addAnimation:[self repeatRotateAnimation] forKey:@"repeatRotateAnimation"];
}

- (void)stopAnimating {
    if (self.isRotating) {
        [self.layer removeAllAnimations];
        self.isRotating = NO;
    }
    self.progress = 0;
}

- (CAKeyframeAnimation*)scaleAnimation {
    
    NSTimeInterval animationDuration = kBGCircleScaleDuration;
    CAMediaTimingFunction *linearCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    //animation.keyTimes = @[@(0), @(0.5), @(1)];
    animation.values = @[@(1.2), @(1.5), @(1.0)];
    animation.duration = animationDuration;
    animation.timingFunction = linearCurve;
    animation.removedOnCompletion = NO;
    animation.repeatCount = 1;
    animation.fillMode = kCAFillModeForwards;
    animation.autoreverses = NO;
    
    return animation;
}

- (CABasicAnimation*)repeatRotateAnimation {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.fromValue = 0;
    animation.toValue = [NSNumber numberWithFloat:M_PI*2];
    animation.duration = kBGCircleRotateDuration;
    CAMediaTimingFunction *linearCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.timingFunction = linearCurve;
    animation.removedOnCompletion = NO;
    animation.repeatCount = INFINITY;
    animation.fillMode = kCAFillModeForwards;
    animation.autoreverses = NO;
    return animation;
    return animation;
}

- (CABasicAnimation*)rotateAnimation {
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.fromValue = 0;
    animation.toValue = [NSNumber numberWithFloat:M_PI*2];
    animation.duration = kBGCircleRotateDuration;
    CAMediaTimingFunction *linearCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.timingFunction = linearCurve;
    animation.removedOnCompletion = NO;
    animation.repeatCount = 1;
    animation.fillMode = kCAFillModeForwards;
    animation.autoreverses = NO;
    return animation;
}

- (UIImage *)angleMaskImage {
    return [UIImage imageWithContentsOfFile:[[self resourceBundle] pathForResource:@"angle_mask" ofType:@"png"]];
}
    
- (NSBundle *)resourceBundle {
    return [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"BGPullToRefresh" ofType:@"bundle"]];
}
    
@end
