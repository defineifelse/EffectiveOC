//
//  UIScrollView+BGPullToRefresh.h
//  EffectiveOC
//
//  Created by Pan on 16/3/27.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BGRefreshView.h"

@interface UIScrollView (BGPullToRefresh)

@property (nonatomic, strong, readonly) BGRefreshView *bgRefreshView;

- (void)bg_addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;

@end



