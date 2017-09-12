//
//  UIScrollView+BGPullToRefresh.m
//  EffectiveOC
//
//  Created by Pan on 16/3/27.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import "UIScrollView+BGPullToRefresh.h"
#import <objc/runtime.h>

static char UIScrollViewBGRefreshView;

@implementation UIScrollView (BGPullToRefresh)

@dynamic bgRefreshView;

- (void)bg_addPullToRefreshWithActionHandler:(void (^)(void))actionHandler {
    
    if (self.bgRefreshView) {
        self.bgRefreshView.refreshEnabled = NO;
        [self.bgRefreshView removeFromSuperview];
    }
    
    BGRefreshView *refreshView = [[BGRefreshView alloc] initWithFrame:CGRectMake(0, -kBGRefreshViewHeight, self.frame.size.width, kBGRefreshViewHeight)];
    refreshView.actionHandler = actionHandler;
    refreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:refreshView];

    self.bgRefreshView = refreshView;
    self.bgRefreshView.refreshEnabled = YES;
}

- (void)setBgRefreshView:(BGRefreshView *)bgRefreshView {
    objc_setAssociatedObject(self, &UIScrollViewBGRefreshView, bgRefreshView, OBJC_ASSOCIATION_ASSIGN);
}

- (BGRefreshView *)bgRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewBGRefreshView);
}

@end



