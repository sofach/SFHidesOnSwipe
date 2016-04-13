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

- (void)setOwner:(UIView *)owner scrollView:(UIScrollView *)scrollView fromFrame:(CGRect)orignFrame toFrame:(CGRect)finalFrame animated:(BOOL)animated completion:(void(^)(BOOL isOriginal, CGRect frame))completionBlock;

@end

@interface UIView ()

@property (strong, nonatomic) SFHidesOnSwipeContext *sf_hidesOnSwipeContext;

@end

@implementation UIView (SFHidesOnSwipe)

- (void)sf_hidesOnSwipeScrollView:(UIScrollView *)scrollView fromFrame:(CGRect)orignFrame toFrame:(CGRect)finalFrame animated:(BOOL)animated completion:(void(^)(BOOL isOriginal, CGRect frame))completionBlock {
    
    if (!self.sf_hidesOnSwipeContext) {
        self.sf_hidesOnSwipeContext = [SFHidesOnSwipeContext new];
    }
    [self.sf_hidesOnSwipeContext setOwner:self scrollView:scrollView fromFrame:orignFrame toFrame:finalFrame animated:animated completion:completionBlock];
}

- (void)sf_hidesOnSwipeScrollView:(UIScrollView *)scrollView fromFrame:(CGRect)orignFrame toFrame:(CGRect)finalFrame {
    [self sf_hidesOnSwipeScrollView:scrollView fromFrame:orignFrame toFrame:finalFrame animated:YES completion:nil];
}

- (void)sf_hidesOnSwipeScrollView:(UIScrollView *)scrollView {
    [self sf_hidesOnSwipeScrollView:scrollView fromFrame:self.frame toFrame:self.frame animated:YES completion:nil];
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

#define DefaultPanY -10000

@interface SFHidesOnSwipeContext ()

@property (weak, nonatomic) UIScrollView *scrollView;
@property (weak, nonatomic) UIView *owner;
@property (assign, nonatomic) CGRect orignFrame;
@property (assign, nonatomic) CGRect finalFrame;
@property (assign, nonatomic) NSInteger direction;
@property (assign, nonatomic) BOOL isOwnerHidden;
@property (copy, nonatomic) void(^completion)(BOOL isOriginal, CGRect frame);

//由于一个页面中可能又多个view需要加滑动隐藏效果，所以性能尤为关键，下面几个参数都是为了增加性能
@property (assign, nonatomic) BOOL isOwnerPartAppear;
@property (assign, nonatomic) UIGestureRecognizerState panState;
@property (assign, nonatomic) CGFloat preOffset;
@property (assign, nonatomic) CGFloat panY;

@end

@implementation SFHidesOnSwipeContext

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (void)setOwner:(UIView *)owner scrollView:(UIScrollView *)scrollView fromFrame:(CGRect)orignFrame toFrame:(CGRect)finalFrame animated:(BOOL)animated completion:(void(^)(BOOL isOriginal, CGRect frame))completionBlock {
    if (_scrollView) {
        [self removeObservers];
    }
    _isOwnerHidden = NO;
    _scrollView = scrollView;
    _owner = owner;
    _orignFrame = orignFrame;
    _finalFrame = finalFrame;
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
        self.panState = self.scrollView.panGestureRecognizer.state;
        if (self.scrollView.panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
            [self tableViewDidEndDragging];
        }
    }
}

- (void)tableViewDidScroll {

    CGFloat deltaOffset = self.scrollView.contentOffset.y - self.preOffset;
    self.preOffset = self.scrollView.contentOffset.y;
    
    //当隐藏了且继续向下滑，或者显示了继续向上滑，或者panY=0，直接返回可以增加性能
    if ((deltaOffset>=0 && self.isOwnerHidden && self.panY == DefaultPanY) || (deltaOffset<=0 && !self.isOwnerHidden && self.panY == DefaultPanY)) {
        return;
    }
    if (self.panState == UIGestureRecognizerStateBegan || self.panState == UIGestureRecognizerStateChanged) {
        _panY = [self.scrollView.panGestureRecognizer translationInView:self.scrollView].y/3;

        if (self.isOwnerHidden && _panY>0) {
            CGRect frame = self.finalFrame;
            frame.origin.y = self.finalFrame.origin.y - _panY*self.direction;
            if ((frame.origin.y-self.orignFrame.origin.y)*(frame.origin.y-self.finalFrame.origin.y)>0) {
                frame.origin.y = self.orignFrame.origin.y;
            }
            self.owner.frame = frame;
        } else if (!self.isOwnerHidden && _panY<-20) {
            CGRect frame = self.orignFrame;
            frame.origin.y = self.orignFrame.origin.y - (_panY+20)*self.direction;
            if ((frame.origin.y-self.orignFrame.origin.y)*(frame.origin.y-self.finalFrame.origin.y)>0) {
                frame.origin.y = self.finalFrame.origin.y;
            }
            self.owner.frame = frame;
        }
    }
}

- (void)tableViewDidEndDragging {

    if (self.panY==DefaultPanY || (self.panY<0&&self.panY>-20)) {
        return;
    }
    if (self.isOwnerHidden) {
        if (_panY>0) {
            [UIView animateWithDuration:0.25 animations:^{
                self.owner.frame = self.orignFrame;
            } completion:^(BOOL finished) {
                self.isOwnerHidden = NO;
                if (finished && self.completion) {
                    self.completion(YES, self.orignFrame);
                }
            }];
        } else { //这里是必须的，因为可能露出一点
            [UIView animateWithDuration:0.25 animations:^{
                self.owner.frame = self.finalFrame;
            } completion:^(BOOL finished) {
                if (finished && self.completion) {
                    self.completion(NO, self.finalFrame);
                }
            }];
        }
    } else {
        if (_panY<0) {
            [UIView animateWithDuration:0.25 animations:^{
                self.owner.frame = self.finalFrame;
            } completion:^(BOOL finished) {
                self.isOwnerHidden = YES;
                if (finished && self.completion) {
                    self.completion(NO, self.finalFrame);
                }
            }];
        } else {
            [UIView animateWithDuration:0.25 animations:^{
                self.owner.frame = self.orignFrame;
            } completion:^(BOOL finished) {
                if (finished && self.completion) {
                    self.completion(YES, self.orignFrame);
                }
            }];
        }
    }
    self.panY = DefaultPanY; //拖拽结束时，需要设置pany=0
}
@end