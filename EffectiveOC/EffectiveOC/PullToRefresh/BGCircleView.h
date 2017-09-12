//
//  BGCircleView.h
//  EffectiveOC
//
//  Created by Pan on 16/3/27.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BGCircleView : UIView

@property (nonatomic, strong) UIColor *circleColor;
@property (nonatomic, assign) CGFloat progress;

- (void)startAnimating;
- (void)stopAnimating;

@end
