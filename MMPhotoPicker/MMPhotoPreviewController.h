//
//  MMPhotoPreviewController.h
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//
//  图片预览
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

@interface MMPhotoPreviewController : UIViewController

@property (nonatomic, strong) NSMutableArray<PHAsset *> *assetArray;
@property (nonatomic, copy) void(^assetDeleteHandler)(PHAsset * asset);

@end


@interface MMAVPlayer : AVPlayer

// 正在播放
@property (nonatomic, assign) BOOL isPlaying;
// 视频时长
@property (nonatomic, assign) CMTime duration;

@end

