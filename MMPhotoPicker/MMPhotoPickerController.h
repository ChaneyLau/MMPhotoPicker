//
//  MMPhotoPickerController.h
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//
//  图库列表
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "MMPhotoMacro.h"
#import "MMPhotoUtil.h"

#pragma mark - ################## MMPhotoPickerController

@protocol MMPhotoPickerDelegate;
@interface MMPhotoPickerController : UIViewController

// 是否显示视频 [默认NO]
@property (nonatomic, assign) BOOL showVideo;
// 最大选择数目[默认9张、如果显示视频，也包括视频数量]
@property (nonatomic, assign) NSInteger maximumNumber;

// 主色调[默认红色#FC2948]
@property (nonatomic, strong) UIColor *mainColor;
// 未选中图片[用于是否选择原图标记]
@property (nonatomic, strong) UIImage *unselectIcon;
// 选中图片[用于是否选择原图标记、图片选择标记]
@property (nonatomic, strong) UIImage *selectIcon;

// 代理
@property (nonatomic, assign) id<MMPhotoPickerDelegate> delegate;

@end

@protocol MMPhotoPickerDelegate <NSObject>

@optional

/**
 info释义:
 返回的媒体数据是数组，数组单元为字典，字典中包含以下数据：

 资源类型 MMPhotoMediaType
 位置方向 MMPhotoLocation
 原始图片 MMPhotoOriginalImage
 视频路径 MMPhotoVideoURL
 视频时长 MMPhotoVideoDuration

 */
- (void)mmPhotoPickerController:(MMPhotoPickerController *)picker didFinishPickingMediaWithInfo:(NSArray<NSDictionary *> *)info;
- (void)mmPhotoPickerControllerDidCancel:(MMPhotoPickerController *)picker;

@end

#pragma mark - ################## MMPhotoAlbum
@interface MMPhotoAlbum : NSObject

// 相册名称
@property (nonatomic, copy) NSString *name;
// 内含图片数量
@property (nonatomic, assign) NSInteger assetCount;
// 封面
@property (nonatomic, strong) PHAsset *coverAsset;
// 相册
@property (nonatomic, strong) PHAssetCollection *collection;

@end

#pragma mark - ################## MMPhotoAlbumCell
@interface MMPhotoAlbumCell : UITableViewCell

@end
