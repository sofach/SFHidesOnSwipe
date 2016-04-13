//
//  UIView+SFHidesOnSwipe.h
//  SFHidesOnSwipe
//
//  Created by 陈少华 on 15/11/13.
//  Copyright © 2015年 sofach. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (SFHidesOnSwipe)

- (void)sf_hidesOnSwipeScrollView:(UIScrollView *)scrollView;
- (void)sf_hidesOnSwipeScrollView:(UIScrollView *)scrollView fromFrame:(CGRect)orignFrame toFrame:(CGRect)finalFrame;
- (void)sf_hidesOnSwipeScrollView:(UIScrollView *)scrollView fromFrame:(CGRect)orignFrame toFrame:(CGRect)finalFrame animated:(BOOL)animated completion:(void(^)(BOOL isOriginal, CGRect frame))completionBlock;

@end
