//
//  UIView+SFHidesOnSwipe.m
//  SFHidesOnSwipe
//
//  Created by 陈少华 on 15/11/13.
//  Copyright © 2015年 sofach. All rights reserved.
//
#import <objc/runtime.h>

#import "UIView+SFHidesOnSwipe.h"

@interface SFHidesOnSwipeContext : NSObject

- (void)setOwner:(UIView *)owner scrollView:(UIScrollView *)scrollView fromFrame:(CGRect)orignFrame toFrame:(CGRect)finalFrame thresholdOffset:(CGFloat)offset animated:(BOOL)animated completion:(void(^)(BOOL isOriginal, CGRect frame))completionBlock;

@end

@interface UIView ()

@property (strong, nonatomic) SFHidesOnSwipeContext *sf_hidesOnSwipeContext;

@end

@implementation UIView (SFHidesOnSwipe)

- (void)sf_hidesOnSwipeScrollView:(UIScrollView *)scrollView fromFrame:(CGRect)orignFrame toFrame:(CGRect)finalFrame thresholdOffset:(CGFloat)offset animated:(BOOL)animated completion:(void(^)(BOOL isOriginal, CGRect frame))completionBlock {

    if (!self.sf_hidesOnSwipeContext) {
        self.sf_hidesOnSwipeContext = [SFHidesOnSwipeContext new];
    }
    [self.sf_hidesOnSwipeContext setOwner:self scrollView:scrollView fromFrame:orignFrame toFrame:finalFrame thresholdOffset:offset animated:animated completion:completionBlock];
}

- (void)sf_hidesOnSwipeScrollView:(UIScrollView *)scrollView fromFrame:(CGRect)orignFrame toFrame:(CGRect)finalFrame {
    [self sf_hidesOnSwipeScrollView:scrollView fromFrame:orignFrame toFrame:finalFrame thresholdOffset:self.frame.size.height/2 animated:YES completion:nil];
}

- (void)sf_hidesOnSwipeScrollView:(UIScrollView *)scrollView {
    [self sf_hidesOnSwipeScrollView:scrollView fromFrame:self.frame toFrame:self.frame thresholdOffset:self.frame.size.height/2 animated:YES completion:nil];
}

#pragma mark getter setter
- (SFHidesOnSwipeContext *)sf_hidesOnSwipeContext {
    return objc_getAssociatedObject(self, @selector(sf_hidesOnSwipeContext));
}

- (void)setSf_hidesOnSwipeContext:(SFHidesOnSwipeContext *)sf_hidesOnSwipeContext {
    [self willChangeValueForKey:@"sf_hidesOnSwipeContext"]; // KVO
    objc_setAssociatedObject(self, @selector(sf_hidesOnSwipeContext), sf_hidesOnSwipeContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"sf_hidesOnSwipeContext"]; // KVO
}

@end

typedef enum{
    SFSwipeStateNormal = 0,
    SFSwipeStateWillHide,
    SFSwipeStateHidden,
    SFSwipeStateWillShow
} SFSwipeState;

@interface SFHidesOnSwipeContext ()

@property (weak, nonatomic) UIScrollView *scrollView;
@property (weak, nonatomic) UIView *owner;
@property (assign, nonatomic) CGRect orignFrame;
@property (assign, nonatomic) CGRect finalFrame;
@property (assign, nonatomic) NSInteger direction;
@property (assign, nonatomic) CGFloat thresholdOffset;
@property (assign, nonatomic) BOOL canSwipeHide;

@property (assign, nonatomic) SFSwipeState state;

@property (copy, nonatomic) void(^completion)(BOOL isOriginal, CGRect frame);

//由于一个页面中可能又多个view需要加滑动隐藏效果，所以性能尤为关键，下面几个参数都是为了增加性能
@property (assign, nonatomic) UIGestureRecognizerState panState;
@property (assign, nonatomic) CGFloat preOffset;
@property (assign, nonatomic) CGFloat panY;

@end

@implementation SFHidesOnSwipeContext

- (instancetype)init {
    if (self = [super init]) {
        _canSwipeHide = NO;
        _state = SFSwipeStateNormal;
    }
    return self;
}

- (void)setOwner:(UIView *)owner scrollView:(UIScrollView *)scrollView fromFrame:(CGRect)orignFrame toFrame:(CGRect)finalFrame thresholdOffset:(CGFloat)offset animated:(BOOL)animated completion:(void(^)(BOOL isOriginal, CGRect frame))completionBlock {
    if (_scrollView) {
        [self removeObservers];
    }
    _state = SFSwipeStateNormal;
    _scrollView = scrollView;
    _owner = owner;
    _orignFrame = orignFrame;
    _finalFrame = finalFrame;
    _thresholdOffset = offset;
    _direction = fabs(finalFrame.origin.y-orignFrame.origin.y)/(finalFrame.origin.y-orignFrame.origin.y);
    _completion = completionBlock;
    
    CGFloat duration = 0.0;
    if (animated) {
        duration = .25;
    }
    [UIView animateWithDuration:duration animations:^{
        [_owner setFrame:_orignFrame];
    }];

    if (_scrollView) {
        [self addObservers];
    }
}

- (void)addObservers {
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [self.scrollView.panGestureRecognizer addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObservers {
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self.scrollView.panGestureRecognizer removeObserver:self forKeyPath:@"state"];
}

#define mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.scrollView && [keyPath isEqualToString:@"contentOffset"]) {
        [self tableViewDidScroll];
    } else if (object == self.scrollView.panGestureRecognizer && [keyPath isEqualToString:@"state"]) {

        if (self.scrollView.panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
            [self tableViewDidEndDragging];
        } else if (self.scrollView.panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
            [self tableViewBeginScroll];
        }
    }
}

- (void)tableViewBeginScroll {
    if (self.scrollView.contentOffset.y<_thresholdOffset) {
        _canSwipeHide = NO;
    } else {
        _canSwipeHide = YES;
    }
}

- (void)tableViewDidScroll {
    CGFloat deltaOffset = self.scrollView.contentOffset.y - self.preOffset;
    self.preOffset = self.scrollView.contentOffset.y;

    //当隐藏了且继续向下滑，或者显示了继续向上滑，或者panY=0，直接返回可以增加性能
    if ((deltaOffset>=0 && self.state==SFSwipeStateHidden) || (deltaOffset<=0 && self.state==SFSwipeStateNormal)) {
        return;
    }
    _panY = [self.scrollView.panGestureRecognizer translationInView:self.scrollView].y/4;
    if (_panY>0) {
        if (self.state==SFSwipeStateHidden || self.state==SFSwipeStateWillShow) {
            self.state = SFSwipeStateWillShow;
            CGRect frame = self.finalFrame;
            frame.origin.y = self.finalFrame.origin.y - _panY*self.direction;
            if ((frame.origin.y-self.orignFrame.origin.y)*(frame.origin.y-self.finalFrame.origin.y)>0) {
                frame.origin.y = self.orignFrame.origin.y;
                self.state = SFSwipeStateNormal;
            }
            self.owner.frame = frame;
        } else {
            self.state = SFSwipeStateNormal;
        }
    } else {
        if ((self.state==SFSwipeStateNormal || self.state==SFSwipeStateWillHide) && _canSwipeHide) {
            self.state = SFSwipeStateWillHide;
            CGRect frame = self.orignFrame;
            frame.origin.y = self.orignFrame.origin.y - _panY*self.direction;
            if ((frame.origin.y-self.orignFrame.origin.y)*(frame.origin.y-self.finalFrame.origin.y)>0) {
                frame.origin.y = self.finalFrame.origin.y;
                self.state = SFSwipeStateHidden;
            }
            self.owner.frame = frame;
        }
    }
}

- (void)tableViewDidEndDragging {

    if (self.state==SFSwipeStateWillShow) {
        
        self.state = SFSwipeStateNormal;
        
        [UIView animateWithDuration:0.25 animations:^{
            self.owner.frame = self.orignFrame;
        } completion:^(BOOL finished) {
            if (finished && self.completion) {
                self.completion(YES, self.orignFrame);
            }
        }];
    } else if (self.state == SFSwipeStateWillHide) {
        
        self.state = SFSwipeStateHidden;
        
        [UIView animateWithDuration:0.25 animations:^{
            self.owner.frame = self.finalFrame;
        } completion:^(BOOL finished) {
            if (finished && self.completion) {
                self.completion(NO, self.finalFrame);
            }
        }];
    }
}
@end
