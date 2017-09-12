//
//  BGRefreshView.m
//  EffectiveOC
//
//  Created by Pan on 16/3/27.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import "BGRefreshView.h"
#import "BGCircleView.h"

typedef NS_ENUM(NSInteger, BGRefreshState) {
    BGRefreshStateNormal    = 0,
    BGRefreshStatePulling   = 1,
    BGRefreshStateLoading   = 2,
    BGRefreshStateStopped   = 3,
};

@interface BGRefreshView ()

@property (nonatomic, assign) CGFloat originalContentInsetTop;
@property (nonatomic, strong) BGCircleView *circleView;
@property (nonatomic, assign) BGRefreshState state;

@end

@implementation BGRefreshView

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        BGCircleView *circleView = [[BGCircleView alloc] initWithFrame:CGRectMake(0, 0, kBGCircleViewHeight, kBGCircleViewHeight)];
        circleView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f+5);
        self.circleView = circleView;
        [self addSubview:self.circleView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.circleView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f+5);
}

- (void)dealloc {
    self.circleView = nil;
}


- (void)beginRefreshing {
    if (self.refreshEnabled) {
        self.state = BGRefreshStatePulling;
        self.state = BGRefreshStateLoading;
    }
}

- (void)endRefreshing {
    self.state = BGRefreshStateStopped;
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"frame"]) {
        [self layoutSubviews];
    }
    else if ([keyPath isEqualToString:@"contentOffset"]) {
        CGPoint contentOffset = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
        CGFloat pulledDistance = MAX(0, -contentOffset.y - self.scrollView.contentInset.top);
        if(self.state != BGRefreshStateLoading) {
            
            if(pulledDistance > kBGPullToRefreshMinOffset && !self.scrollView.isDragging && self.state == BGRefreshStatePulling) {
                self.state = BGRefreshStateLoading;
            } else if(pulledDistance > 5.0 && self.scrollView.isDragging) {
                self.state = BGRefreshStatePulling;
                self.circleView.progress = fabs(pulledDistance / self.frame.size.height) + 0.2;
            }else if(pulledDistance <= 5.0 && self.state == BGRefreshStatePulling) {
                self.state = BGRefreshStateStopped;
            }
        }
    }
}

#pragma mark - set Scroll contentInset

- (void)resetScrollViewContentInset {
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    contentInset.top = self.originalContentInsetTop;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.scrollView.contentInset = contentInset;
    } completion:^(BOOL finished) {
        
        self.state = BGRefreshStateNormal;
    }];
}

- (void)setScrollViewContentInsetForLoading {
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    self.scrollView.contentInset = UIEdgeInsetsMake(kBGPullToRefreshMinOffset + self.originalContentInsetTop, contentInset.left, contentInset.bottom, contentInset.right);
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -kBGPullToRefreshMinOffset - self.originalContentInsetTop) animated:YES];
}

#pragma mark - Setter and Getter

- (BOOL)isRefreshing {
    return self.state == BGRefreshStateLoading;
}

- (UIScrollView *)scrollView {
    if ([self.superview isKindOfClass:[UIScrollView class]]) {
        return (UIScrollView *)self.superview;
    }
    return nil;
}

- (void)setRefreshEnabled:(BOOL)refreshEnabled {
    UIScrollView *scrollView = self.scrollView;
    if (scrollView == nil || _refreshEnabled == refreshEnabled) return; 
    _refreshEnabled = refreshEnabled;
    if (refreshEnabled) {
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [scrollView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    }else {
        [scrollView removeObserver:self forKeyPath:@"contentOffset"];
        [scrollView removeObserver:self forKeyPath:@"frame"];
    }
}

- (void)setState:(BGRefreshState)newState {
    if (_state == newState) return;
    BGRefreshState previousState = _state;
    _state = newState;

    switch (newState) {
            
        case BGRefreshStateNormal:
            break;
        case BGRefreshStatePulling:
            self.originalContentInsetTop = self.scrollView.contentInset.top;
            break;
        case BGRefreshStateLoading: {
            
            [self.circleView startAnimating];
            [self setScrollViewContentInsetForLoading];
            if(previousState == BGRefreshStatePulling) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self.actionHandler) {
                        self.actionHandler();
                    }
                });
            }
        }
            break;
        case BGRefreshStateStopped: {
            [self.circleView stopAnimating];
            [self resetScrollViewContentInset];
        }
            break;
        default:
            break;
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    self.circleView.circleColor = tintColor;
}

- (UIColor *)tintColor {
    return self.circleView.circleColor;
}

@end
