//
//  SCBPhotoBrowser.h
//  EffectiveOC
//
//  Created by Pan on 16/2/25.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCBPhotoItem : NSObject

@property (nonatomic, strong) UIView *thumbView;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *imgUrl;

@end

@interface SCBPhotoBrowser : UIView

@property (nonatomic, readonly) NSArray *photoItems;
@property (nonatomic, readonly) NSInteger currentPage;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithFrame:(CGRect)frame UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithImagesOrUrls:(NSArray *)images;
- (instancetype)initWithThumbViews:(NSArray *)thumbViews imgUrls:(NSArray *)imgUrls;
- (instancetype)initWithPhotoItems:(NSArray *)photoItems;

+ (void)presentFromImageView:(UIImageView *)imageView;
+ (void)presentFromImageView:(UIImageView *)imageView url:(NSString *)url;

- (void)presentFromImageView:(UIImageView *)fromView
                 toContainer:(UIView *)container
                    complete:(void (^)(void))complete;
- (void)presentFromView:(UIView *)fromView
                  image:(UIImage *)image
            toContainer:(UIView *)container
               complete:(void (^)(void))complete;

- (void)dismissComplete:(void (^)(void))complete;

- (void)setSaveImageEnabled:(BOOL)enabled;

@end
