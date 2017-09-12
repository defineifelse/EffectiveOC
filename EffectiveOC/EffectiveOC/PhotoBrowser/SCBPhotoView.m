//
//  SCBPhotoView.m
//  EffectiveOC
//
//  Created by Pan on 16/2/25.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import "SCBPhotoView.h"
#import "UIImageView+WebCache.h"

@implementation UIImage (Util)

- (CGSize)sizeThatFit:(CGSize)size {
    CGSize imageSize = CGSizeMake(self.size.width * self.scale,
                                  self.size.height * self.scale);
    CGFloat widthRatio = imageSize.width / size.width;
    //CGFloat heightRatio = imageSize.height / size.height;
    if (widthRatio <= 1) {
        return imageSize;
    }
    imageSize = CGSizeMake(imageSize.width/widthRatio, imageSize.height/widthRatio);
    return imageSize;
}

- (CGSize)expandImageWithSize:(CGSize)size {
    CGSize imageSize = CGSizeMake(self.size.width * self.scale,
                                  self.size.height * self.scale);
    CGFloat widthRatio = imageSize.width / size.width;
    imageSize = CGSizeMake(imageSize.width/widthRatio, imageSize.height/widthRatio);
    
    return imageSize;
}

@end

@interface SCBPhotoView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) void (^complete)(UIImage *image, NSError *error);
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;

@property (nonatomic, strong) UIImageView *thumbImageView;
@property (nonatomic, strong) UIImage *thumbImage;
@property (nonatomic, assign) CGSize thumbSize;

@end

@implementation SCBPhotoView {
    CGSize _imageExpandSize;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.scrollView];
        [self addSubview:self.thumbImageView];
        [self addSubview:self.toolbar];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.scrollView.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
    
    if (self.imageView.image) {
        [self resetImageViewSize];
    }
    if (self.thumbImageView.image) {
        [self resetThumbImageViewSize];
    }
}

- (void)dealloc {
    [self.imageView removeObserver:self forKeyPath:@"image" context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    UIImage *image = [object valueForKeyPath:@"image"];
    
    [self resetImageViewSize];
    self.thumbImageView.hidden = image != nil;
}


- (void)setThumbImage:(UIImage *)thumbImage {
    self.thumbImageView.image = thumbImage;
    [self resetThumbImageViewSize];
}

- (void)setImageWithUrl:(NSString *)url complete:(void (^)(UIImage *image, NSError *error))complete {
    self.url = url;
    self.complete = [complete copy];
    
    self.toolbar.hidden = NO;
    [self.indicatorView startAnimating];
    self.retryButton.hidden = YES;
    
    self.thumbImageView.hidden = NO;
    
    __weak typeof(self) weakSelf = self;
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil options:SDWebImageContinueInBackground|SDWebImageAllowInvalidSSLCertificates progress:^(NSInteger receivedSize, NSInteger expectedSize) {

    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        if (image) {
            [weakSelf.indicatorView stopAnimating];

        }else{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.indicatorView stopAnimating];
                weakSelf.retryButton.hidden = NO;
            });
        }
        
        if (complete) {
            complete(image, error);
        }
    }];
}

#pragma mark - Actions

- (void)doubleTapAction:(UITapGestureRecognizer *)tap {
    if (!self.imageView.image) {
        return;
    }
    
    CGFloat newZoomscale = MIN(3.0, self.scrollView.maximumZoomScale);
    
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    } else {
        CGPoint touchPoint = [tap locationInView:tap.view];
        
        CGRect zoomRect;
        zoomRect.size.height = self.scrollView.frame.size.height / newZoomscale;
        zoomRect.size.width  = self.scrollView.frame.size.width  / newZoomscale;
        zoomRect.origin.x = touchPoint.x - (zoomRect.size.width  / 2.0);
        zoomRect.origin.y = touchPoint.y - (zoomRect.size.height / 2.0);
        
        [self.scrollView zoomToRect:zoomRect animated:YES];
        [self.scrollView setZoomScale:newZoomscale animated:YES];
    }
}

- (void)imageLoadRetry {
    [self setImageWithUrl:self.url complete:self.complete];
}

- (void)cancelCurrentImageLoad {
    [self.imageView sd_cancelCurrentImageLoad];
}


#pragma mark - UIScrollViewDelegate 

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if(scrollView.zoomScale <= 1) {
        scrollView.zoomScale = 1.0f;
    }
    
    self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, _imageExpandSize.width * scrollView.zoomScale, _imageExpandSize.height * scrollView.zoomScale);    
    scrollView.contentSize = CGSizeMake(_imageExpandSize.width*scrollView.zoomScale, _imageExpandSize.height*scrollView.zoomScale);
    
    [self resetImageViewCenter];
}

#pragma mark - reset size

- (void)resetImageViewCenter {
    CGFloat centerX = self.scrollView.center.x , centerY = self.scrollView.center.y;
    centerX = self.scrollView.contentSize.width > self.scrollView.frame.size.width ? self.scrollView.contentSize.width/2 : centerX;
    centerY = self.scrollView.contentSize.height > self.scrollView.frame.size.height ? self.scrollView.contentSize.height/2 : centerY;
    [self.imageView setCenter:CGPointMake(centerX, centerY)];
}


- (void)resetZoomScale {
    if (self.scrollView.zoomScale != self.scrollView.minimumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:NO];
    }
}

- (void)resetImageViewSize {
    _imageExpandSize = [self.imageView.image expandImageWithSize:self.frame.size];
    CGRect frame = self.imageView.frame;
    frame.size = _imageExpandSize;
    self.imageView.frame = frame;
    self.scrollView.contentSize = _imageExpandSize;
    [self resetImageViewCenter];
}

- (void)resetThumbImageViewSize {
    CGRect frame = self.thumbImageView.frame;
    frame.size = [self.thumbImageView.image expandImageWithSize:self.frame.size];
    self.thumbImageView.frame = frame;
    self.thumbImageView.center = CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f);
}


#pragma mark - getter

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _scrollView.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
        _scrollView.delegate = self;
        _scrollView.maximumZoomScale = 5.0;
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.bounces = YES;
        [_scrollView addSubview:self.imageView];
        
        self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
        self.doubleTap.numberOfTapsRequired = 2;
        [_scrollView addGestureRecognizer:self.doubleTap];
    }
    return _scrollView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        _imageView.userInteractionEnabled = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_imageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
        
    }
    return _imageView;
}

- (UIView *)toolbar {
    if (!_toolbar) {
        _toolbar = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-40, self.frame.size.width, 40)];
        
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _indicatorView.frame = CGRectMake(_toolbar.frame.size.width-60, 5, 20, 20);
        _indicatorView.userInteractionEnabled = YES;
        [_toolbar addSubview:_indicatorView];
        
        _retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _retryButton.frame = CGRectMake(_toolbar.frame.size.width-80, 0, 60, 30);
        [_retryButton setImage:[self retryImage] forState:UIControlStateNormal];
        [_retryButton addTarget:self action:@selector(imageLoadRetry) forControlEvents:UIControlEventTouchUpInside];
        _retryButton.hidden = YES;
        [_toolbar addSubview:_retryButton];
    }
    return _toolbar;
}

- (UIImageView *)thumbImageView {
    if (!_thumbImageView) {
        _thumbImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        _thumbImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _thumbImageView;
}

- (UIImage *)retryImage {
    return [UIImage imageWithContentsOfFile:[[self resourceBundle] pathForResource:@"image_retry" ofType:@"png"]];
}

- (NSBundle *)resourceBundle {
    return [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"PhotoBrowser" ofType:@"bundle"]];
}

@end
