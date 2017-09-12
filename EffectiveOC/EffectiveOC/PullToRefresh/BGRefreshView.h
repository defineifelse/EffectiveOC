//
//  BGRefreshView.h
//  EffectiveOC
//
//  Created by Pan on 16/3/27.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kBGCircleViewHeight 35
#define kBGRefreshViewHeight 50
#define kBGPullToRefreshMinOffset 50

@interface BGRefreshView : UIView

@property (nonatomic, copy) void (^actionHandler)(void);
@property(nonatomic, assign) BOOL refreshEnabled;
@property (nonatomic, strong) UIColor *tintColor; //default is rgb(150,150,150)
@property (nonatomic, readonly, getter=isRefreshing) BOOL refreshing;

- (void)beginRefreshing;
- (void)endRefreshing;

@end

