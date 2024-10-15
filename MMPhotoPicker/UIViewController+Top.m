//
//  UIViewController+Top.m
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import "UIViewController+Top.h"

@implementation UIViewController (Top)

+ (UIViewController *)topViewController;
{
    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (viewController == nil) {
        viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    }
    return [UIViewController findTopViewController:viewController];
}

+ (UIViewController* )findTopViewController:(UIViewController *)vc
{
    if (vc.presentedViewController) {
        return [UIViewController findTopViewController:vc.presentedViewController];
    } else if ([vc isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *svc = (UISplitViewController*) vc;
        if (svc.viewControllers.count > 0) {
            return [UIViewController findTopViewController:svc.viewControllers.lastObject];
        } else {
            return vc;
        }
    } else if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *svc = (UINavigationController*) vc;
        if (svc.viewControllers.count > 0) {
            return [UIViewController findTopViewController:svc.topViewController];
        } else {
            return vc;
        }
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        UITabBarController *svc = (UITabBarController*) vc;
        if (svc.viewControllers.count > 0) {
            return [UIViewController findTopViewController:svc.selectedViewController];
        } else {
            return vc;
        }
    } else if ([vc isKindOfClass:[UIViewController class]] && vc.childViewControllers.count > 0 && [vc.childViewControllers.firstObject isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController* svc = (UISplitViewController*) vc.childViewControllers.firstObject;
        if (svc.viewControllers.count > 0) {
            return [UIViewController findTopViewController:svc.viewControllers.lastObject];
        } else {
            return vc;
        }
   } else {
        return vc;
    }
}

@end
