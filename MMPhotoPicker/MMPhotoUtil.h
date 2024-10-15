//
//  MMPhotoUtil.h
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <UIKit/UIKit.h>

@interface MMPhotoUtil : NSObject

// 保存图片到自定义相册
+ (void)saveImage:(UIImage *)image completion:(void(^)(BOOL success))completion;
// 保存视频到自定义相册
+ (void)saveVideo:(NSURL *)videoURL completion:(void(^)(BOOL success))completion;

// 获取指定相册中照片（ascending：按照片创建时间排序 >> YES:升序 NO:降序）
+ (NSArray<PHAsset *> *)getAllAssetWithCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending;
// 获取asset对应的图片
+ (void)getImageWithAsset:(PHAsset *)asset imageSize:(CGSize)size completion:(void (^)(UIImage *image))completion;
// 获取asset对应图片|视频信息
+ (void)getInfoWithAsset:(PHAsset *)phAsset completion:(void (^)(NSDictionary *info))completion;

// 获取视频时长
+ (NSString *)getDurationFormat:(NSInteger)duration;
// 获取图片
+ (UIImage *)imageNamed:(NSString *)imageName;

@end
