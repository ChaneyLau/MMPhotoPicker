//
//  PHAsset+Category.m
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import "PHAsset+Category.h"
#import <objc/runtime.h>

static NSString * MSelectedKey = @"selected";

@implementation PHAsset (Category)

- (void)setSelected:(BOOL)selected
{
    objc_setAssociatedObject(self, &MSelectedKey, @(selected), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)selected
{
    NSNumber *selected = objc_getAssociatedObject(self, &MSelectedKey);
    return selected.boolValue;
}

@end
