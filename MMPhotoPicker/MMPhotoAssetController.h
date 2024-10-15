//
//  MMPhotoAssetController.h
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//
//  选择任一相册展示
//

#import <UIKit/UIKit.h>
#import "MMPhotoPickerController.h"

#pragma mark - ################## MMPhotoAssetController
@interface MMPhotoAssetController : UIViewController

// 所选相册
@property (nonatomic, strong) MMPhotoAlbum *photoAlbum;
// 是否显示视频 [默认NO]
@property (nonatomic, assign) BOOL showVideo;
// 最大选择数目[默认9张、如果显示视频，也包括视频数量，如果是1张，则直接返回]
@property (nonatomic, assign) NSInteger maximumNumber;

// 主色调[默认红色#FC2948]
@property (nonatomic, strong) UIColor *mainColor;
// 未选中图片[用于是否选择原图标记]
@property (nonatomic, strong) UIImage *unselectIcon;
// 选中图片[用于是否选择原图标记、图片选择标记]
@property (nonatomic, strong) UIImage *selectIcon;

// 选择回传
@property (nonatomic, copy) void(^onCompletion)(NSArray *mediaInfo);
//取消
@property (nonatomic, copy) void(^onCancel)(void);

@end

#pragma mark - ################## MMAssetCell

@interface MMAssetCell : UICollectionViewCell

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) UIImage *selectIcon;

@end
