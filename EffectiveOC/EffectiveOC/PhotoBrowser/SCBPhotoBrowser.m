//
//  SCBPhotoBrowser.m
//  EffectiveOC
//
//  Created by Pan on 16/2/25.
//  Copyright © 2016年 Pan. All rights reserved.
//

#import "SCBPhotoBrowser.h"
#import "SCBPhotoView.h"

@implementation SCBPhotoItem

@end

@interface SCBPhotoBrowser () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) NSArray *photoViewPool;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) NSArray *photoItems;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *toolbar;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UILabel *indicatorLabel;

@property (nonatomic, assign) BOOL fromNavigationBarHidden;
@property (nonatomic, weak) UIView *fromView;
@property (nonatomic, assign) UIViewContentMode fromViewContentMode;

@property (nonatomic, strong) UIGestureRecognizer *singleTap;

@end

@implementation SCBPhotoBrowser {
    CGRect _currentImageFrame;
}

- (instancetype)initWithImagesOrUrls:(NSArray *)images; {
    NSMutableArray *photoItems = [NSMutableArray array];
    [images enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SCBPhotoItem *item = [SCBPhotoItem new];
        if ([obj isKindOfClass:[UIImage class]]) {
            item.image = obj;
        }
        else if ([obj isKindOfClass:[NSString class]]){
            item.imgUrl = obj;
        }
        [photoItems addObject:item];
    }];
    return [self initWithPhotoItems:[photoItems copy]];
}

- (instancetype)initWithThumbViews:(NSArray *)thumbViews imgUrls:(NSArray *)imgUrls {
    NSMutableArray *photoItems = [NSMutableArray array];
    [thumbViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL * _Nonnull stop) {
        SCBPhotoItem *item = [SCBPhotoItem new];
        item.thumbView = view;
        if ([view isKindOfClass:[UIImageView class]]) {
            UIImageView *imgView = (UIImageView *)view;
            item.image = imgView.image;
        }
        if (idx < imgUrls.count) {
            item.imgUrl = imgUrls[idx];
        }
        [photoItems addObject:item];
    }];
    return [self initWithPhotoItems:[photoItems copy]];
}

- (instancetype)initWithPhotoItems:(NSArray *)photoItems {
    if (self = [super init]) {
        
        [self setPhotoItems:photoItems];
        [self addSubview:self.backgroundView];
        [self.backgroundView addSubview:self.scrollView];
        [self.backgroundView addSubview:self.toolbar];
        if (photoItems.count > 1) {
            [self.toolbar addSubview:self.indicatorLabel];
        }
        [self.toolbar addSubview:self.saveButton];

    }
    return self;
}


#pragma mark - show

+ (void)presentFromImageView:(UIImageView *)imageView {
    [self presentFromImageView:imageView url:nil];
}

+ (void)presentFromImageView:(UIImageView *)imageView url:(NSString *)url {
    if (!imageView.image) {
        return;
    }
    NSArray *urls = url.length > 0 ? @[url] : @[];
    SCBPhotoBrowser *photoBrowser = [[SCBPhotoBrowser alloc] initWithThumbViews:@[imageView] imgUrls:urls];
    [photoBrowser.toolbar removeFromSuperview];
    [photoBrowser presentFromImageView:imageView toContainer:[[UIApplication sharedApplication].delegate window] complete:^{
        
    }];
}

- (void)presentFromImageView:(UIImageView *)imageView
                 toContainer:(UIView *)container
                    complete:(void (^)(void))complete {
    [self presentFromView:imageView image:imageView.image toContainer:container complete:complete];
}

- (void)presentFromView:(UIView *)fromView
                  image:(UIImage *)image
            toContainer:(UIView *)container
               complete:(void (^)(void))complete {
    if (!container || self.photoItems.count == 0) {
        return;
    }
    _containerView = container;
    self.frame = container.bounds;
    [container addSubview:self];
    
    self.currentPage = 0;
    [self.photoItems enumerateObjectsUsingBlock:^(SCBPhotoItem *item, NSUInteger idx, BOOL * _Nonnull stop) {
        if (item.thumbView==fromView || image==item.image) {
            self.currentPage = idx;
            *stop = YES;
        }
    }];
    
    _fromViewContentMode = UIViewContentModeScaleAspectFit;
    __block UIImageView *thumbImageView;
    if (fromView && image) {
        _fromView = fromView;
        thumbImageView = [[UIImageView alloc] initWithImage:image];
        if ([fromView isKindOfClass:[UIImageView class]]) {
            _fromViewContentMode = fromView.contentMode;
        }
        thumbImageView.clipsToBounds = YES;
        thumbImageView.contentMode = _fromViewContentMode;
        thumbImageView.center = fromView.center;
        thumbImageView.frame = [_containerView convertRect:fromView.frame fromView:fromView.superview];
        [self.backgroundView addSubview:thumbImageView];
    }
    SCBPhotoItem *currentPhotoItem = self.photoItems[self.currentPage];
    currentPhotoItem.thumbView = fromView;
    currentPhotoItem.image = image;

    [self setupPhotoViewsWithPage:self.currentPage];
    self.scrollView.contentOffset = CGPointMake(self.backgroundView.frame.size.width * self.currentPage, 0);
    self.scrollView.hidden = YES;
    
    for (SCBPhotoView *photoView in self.photoViewPool) {
        [self setImageWithPhotoView:photoView];
    }
    
    CGRect toFrame = thumbImageView.frame;
    toFrame.size = [thumbImageView.image expandImageWithSize:self.backgroundView.frame.size];
    self.backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    [UIView animateWithDuration:0.3f animations:^{
        
        thumbImageView.frame = toFrame;
        thumbImageView.center = self.backgroundView.center;
        
        self.backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1.0];
        
    } completion:^(BOOL finished) {
        
        _fromNavigationBarHidden = [UIApplication sharedApplication].statusBarHidden;
        [UIApplication sharedApplication].statusBarHidden = YES;
        
        [thumbImageView removeFromSuperview];
        thumbImageView = nil;
        self.scrollView.hidden = NO;
        
        if (complete) {
            complete();
        }
    }];
}


#pragma mark - dismiss

- (void)dismissComplete:(void (^)(void))complete {
    [UIApplication sharedApplication].statusBarHidden = _fromNavigationBarHidden;
    SCBPhotoItem *currentPhotoItem = self.photoItems[self.currentPage];
    UIImageView *currentImageView = [self currentImageView];
    if (!currentImageView.image) {
        currentImageView.image = currentPhotoItem.image;
    }
    UIImageView *thumbImageView = [[UIImageView alloc] initWithImage:currentImageView.image];
    thumbImageView.contentMode = _fromViewContentMode;
    thumbImageView.clipsToBounds = YES;
    thumbImageView.frame = [_containerView convertRect:currentImageView.frame fromView:currentImageView.superview];
    [self.backgroundView addSubview:thumbImageView];
    
    [self.scrollView removeFromSuperview];
    [self.toolbar removeFromSuperview];
    
    [UIView animateWithDuration:0.3f animations:^{
        
        self.backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        SCBPhotoItem *item = self.photoItems[self.currentPage];
        if (item.thumbView) {
            thumbImageView.frame = [_containerView convertRect:item.thumbView.frame fromView:item.thumbView.superview];
        }else if (_fromView) {
            thumbImageView.frame = [_containerView convertRect:_fromView.frame fromView:_fromView.superview];
        }else {
            thumbImageView.alpha = 0;
        }
        
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self.photoViewPool enumerateObjectsUsingBlock:^(SCBPhotoView *photoView, NSUInteger idx, BOOL *stop) {
            [photoView cancelCurrentImageLoad];
        }];
        if (complete) {
            complete();
        }
    }];
}

#pragma mark - Pan Action

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)sender {
    SCBPhotoView *photoView = [self photoViewForPage:self.currentPage];
    if (!photoView.imageView.image || photoView.imageView.frame.size.height > self.backgroundView.frame.size.height || photoView.imageView.frame.size.width > self.backgroundView.frame.size.width) {
        return;
    }
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.indicatorLabel.hidden = YES;
        self.saveButton.hidden = YES;
        photoView.toolbar.hidden = YES;
        [UIApplication sharedApplication].statusBarHidden = _fromNavigationBarHidden;
        
        _currentImageFrame = photoView.imageView.frame;
    }
    
    CGPoint p = [sender translationInView:self.backgroundView];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, p.y);
    transform = CGAffineTransformScale(transform, 1 - fabs(p.y) / 1000,
                                       1 - fabs(p.y) / 1000);
    photoView.imageView.transform = transform;
    CGFloat r = 1 - fabs(p.y) / 200;
    self.backgroundView.alpha = MAX(0, MIN(1, r));
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        if (self.backgroundView.alpha < 0.3)  { [self dismiss]; }
        
        else {
            [UIView animateWithDuration:0.3 animations:^{
                [UIApplication sharedApplication].statusBarHidden = YES;
                self.backgroundView.alpha = 1;
                self.indicatorLabel.hidden = NO;
                self.saveButton.hidden = NO;
                photoView.toolbar.hidden = NO;
                photoView.imageView.transform = CGAffineTransformIdentity;
                photoView.imageView.frame = _currentImageFrame;
            }];
        }
    }
}

- (void)dismiss {
    [self dismissComplete:^{
        
    }];
}

#pragma mark - Tap Action

- (void)tapAction:(UITapGestureRecognizer *)tap {
    [self dismiss];
}

#pragma mark - save Action

- (void)saveImage:(id)sender {
    UIImageView *currentView = [self currentImageView];
    if (!currentView.image) {
        return;
    }
    
    self.saveButton.hidden = YES;
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicatorView.frame = CGRectMake(self.toolbar.frame.size.width-60, 5, 20, 20);
    [indicatorView startAnimating];
    [self.toolbar addSubview:indicatorView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.saveButton.hidden = NO;
        if (indicatorView.superview) {
            [indicatorView removeFromSuperview];
        }
    });

    UIImageWriteToSavedPhotosAlbum(currentView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *message = NSLocalizedStringFromTableInBundle(@"Saved to Album", @"PhotoBrowser", [self resourceBundle], nil);
    if (error) {
        NSLog(@"------failed to save image-----> error: %@",error);
        message = NSLocalizedStringFromTableInBundle(@"Saved failed", @"PhotoBrowser", [self resourceBundle], nil);
    }
    UILabel *label = [[UILabel alloc] init];
    label.text = message;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:15];
    [label sizeToFit];
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    label.layer.cornerRadius = 5.0f;
    label.clipsToBounds = YES;
    [self.backgroundView addSubview:label];
    label.frame = CGRectMake(self.backgroundView.frame.size.width/2.0f-label.frame.size.width/2.0f, self.backgroundView.frame.size.height-100, label.frame.size.width+20, label.frame.size.height+10);
    label.alpha = 0;
    [UIView animateWithDuration:0.5f animations:^{
        label.alpha = 1.0;
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:1.0f animations:^{
            label.alpha = 0;
        }completion:^(BOOL finished) {
            if (label.superview) {
                [label removeFromSuperview];
            }
        }];
    }];
}

- (void)setSaveImageEnabled:(BOOL)enabled {
    if (enabled && self.saveButton.superview == nil) {
        [self.toolbar addSubview:self.saveButton];
        [self.toolbar bringSubviewToFront:self.saveButton];
    }else if (!enabled && self.saveButton.superview) {
        [self.saveButton removeFromSuperview];
    }
}

#pragma mark - setup PhotoView

- (void)setupPhotoViewsWithPage:(NSInteger)page {
    NSMutableArray *photoViews = [NSMutableArray array];
    NSInteger location = page - 1;
    NSInteger length = self.photoItems.count < 3 ? self.photoItems.count : 3;
    if (page == self.photoItems.count-1) {
        location = page - 2;
    }
    location = MAX(0, location);
    for (NSInteger i = location; i < location+length; i ++) {
        SCBPhotoView *photoView = [[SCBPhotoView alloc] initWithFrame:CGRectMake(i * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
        photoView.page = i;
        SCBPhotoItem *item = self.photoItems[i];
        [photoView setThumbImage:item.image];
        [self.scrollView addSubview:photoView];
        
        [self.singleTap requireGestureRecognizerToFail:photoView.doubleTap];
        
        [photoViews addObject:photoView];
    }
    self.photoViewPool = [photoViews copy];
}

- (SCBPhotoView *)photoViewForPage:(NSInteger)page {
    for (SCBPhotoView *view in self.photoViewPool) {
        if (view.page == page) {
            return view;
        }
    }
    return nil;
}

- (void)refreshLeftPage:(NSInteger)page {
    SCBPhotoView *leftPhotoView = [self photoViewForPage:page+2];
    if (leftPhotoView) {
        leftPhotoView.page = page - 1;
        leftPhotoView.frame = CGRectMake(leftPhotoView.page * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
        [self setImageWithPhotoView:leftPhotoView];
    }
}

- (void)refreshRightPage:(NSInteger)page {
    SCBPhotoView *rightPhotoView = [self photoViewForPage:page-2];
    if (rightPhotoView) {
        rightPhotoView.page = page + 1;
        rightPhotoView.frame = CGRectMake(rightPhotoView.page * self.scrollView.frame.size.width, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
        [self setImageWithPhotoView:rightPhotoView];
    }
}


- (void)setImageWithPhotoView:(SCBPhotoView *)photoView {
    SCBPhotoItem *photoItem = self.photoItems[photoView.page];
    [photoView setThumbImage:photoItem.image];
    
    if (photoItem.imgUrl && [photoItem.imgUrl isKindOfClass:[NSString class]]){
        
        if (photoView.page == self.currentPage) {
            self.saveButton.hidden = YES;
        }
        __weak typeof(self) weakSelf = self;
        [photoView setImageWithUrl:photoItem.imgUrl complete:^(UIImage *image, NSError *error) {
            if (image && photoView.page == weakSelf.currentPage) {
                self.saveButton.hidden = NO;
            }
        }];
    }else {
        photoView.imageView.image = photoItem.image;
    }
}

#pragma mark - delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger index = scrollView.contentOffset.x/scrollView.frame.size.width;
    if (index > self.currentPage) {
        self.currentPage = index;
        if (index < self.photoItems.count-1) {
            [self refreshRightPage:index];
        }
    }else if (index < self.currentPage) {
        self.currentPage = index;
        if (index > 0) {
            [self refreshLeftPage:index];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger index = scrollView.contentOffset.x/scrollView.frame.size.width;
    self.currentPage = index;
    SCBPhotoView *photoView = [self photoViewForPage:index];
    photoView.toolbar.hidden = NO;
    self.saveButton.hidden = photoView.imageView.image == nil;
    
    for (SCBPhotoView *photoView in self.photoViewPool) {
        [photoView resetZoomScale];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    for (SCBPhotoView *photoView in self.photoViewPool) {
        photoView.toolbar.hidden = YES;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView.contentOffset.x <= 0 || scrollView.contentOffset.x >= (_photoItems.count-1)*self.backgroundView.frame.size.width) {
        SCBPhotoView *photoView = [self photoViewForPage:self.currentPage];
        photoView.toolbar.hidden = NO;
        self.saveButton.hidden = photoView.imageView.image == nil;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        if ([touch.view isKindOfClass:[UIControl class]]) {
            // we touched a button, slider, or other UIControl
            return NO; // ignore the touch
        }
    }
    return YES; // handle the touch
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        
        CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self.backgroundView];
        if (fabs(velocity.y) > 150) { // panning down
            return YES;
        }
        return NO;
    }
    return YES;
}

#pragma mark - setter and getter

- (void)setPhotoItems:(NSArray *)photoItems {
    if (photoItems.count == 0) {
        return;
    }
    _photoItems = photoItems;
    self.scrollView.contentSize = CGSizeMake(self.backgroundView.frame.size.width * photoItems.count, self.backgroundView.frame.size.height);
}

- (void)setCurrentPage:(NSInteger)currentPage{
    _currentPage = currentPage;
    if (currentPage >= _photoItems.count) {
        _currentPage = _photoItems.count - 1;
    }
    self.indicatorLabel.text = [NSString stringWithFormat:@"%zi / %zi",_currentPage+1, self.photoItems.count];
}


- (UIImageView *)currentImageView {
    SCBPhotoView *photoView = [self photoViewForPage:self.currentPage];
    return photoView.imageView;
}

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _backgroundView.backgroundColor = [UIColor blackColor];
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        panGestureRecognizer.delegate = self;
        [_backgroundView addGestureRecognizer:panGestureRecognizer];
        
        self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        self.singleTap.delegate = self;
        [_backgroundView addGestureRecognizer:self.singleTap];
        [self.singleTap requireGestureRecognizerToFail:panGestureRecognizer];
    }
    return _backgroundView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.backgroundView.bounds];
        _scrollView.contentSize = CGSizeMake(self.backgroundView.frame.size.width, self.backgroundView.frame.size.height);
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.bounces = NO;
        _scrollView.delegate = self;
    }
    
    return _scrollView;
}

- (UIView *)toolbar {
    if (!_toolbar) {
        _toolbar = [[UIView alloc] initWithFrame:CGRectMake(0, self.backgroundView.frame.size.height-40, self.backgroundView.frame.size.width, 40)];
    }
    return _toolbar;
}

- (UILabel *)indicatorLabel {
    if (!_indicatorLabel) {
        _indicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.backgroundView.frame.size.width, 30)];
        _indicatorLabel.textColor = [UIColor whiteColor];
        _indicatorLabel.textAlignment = NSTextAlignmentCenter;
        _indicatorLabel.font = [UIFont systemFontOfSize:13];
        _indicatorLabel.userInteractionEnabled = YES;
    }
    return _indicatorLabel;
}

- (UIButton *)saveButton {
    if (!_saveButton) {
        _saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        _saveButton.frame = CGRectMake(self.backgroundView.frame.size.width-80, 0, 60, 30);
        [_saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_saveButton setTitle:NSLocalizedStringFromTableInBundle(@"Save", @"PhotoBrowser", [self resourceBundle], nil) forState:UIControlStateNormal];
        _saveButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _saveButton.layer.cornerRadius = 5.0f;
        _saveButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2].CGColor;
        _saveButton.layer.borderWidth = 1.0f;
        _saveButton.clipsToBounds = YES;
        [_saveButton addTarget:self action:@selector(saveImage:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveButton;
}

- (NSBundle *)resourceBundle {
    return [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"PhotoBrowser" ofType:@"bundle"]];
}
    
@end
