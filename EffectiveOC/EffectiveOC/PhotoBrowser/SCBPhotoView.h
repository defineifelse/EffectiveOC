//
//  SCBPhotoView.h
//  EffectiveOC
//
//  Created by Pan on 16/2/25.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Util)

- (CGSize)sizeThatFit:(CGSize)size;
- (CGSize)expandImageWithSize:(CGSize)size;

@end

@interface SCBPhotoView : UIView

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *doubleTap;
@property (nonatomic, strong) UIView *toolbar;

- (void)setThumbImage:(UIImage *)thumbImage;
- (void)setImageWithUrl:(NSString *)url complete:(void (^)(UIImage *image, NSError *error))complete;

- (void)cancelCurrentImageLoad;

- (void)resetZoomScale;

@end
