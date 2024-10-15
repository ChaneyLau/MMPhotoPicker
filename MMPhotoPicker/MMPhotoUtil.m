//
//  MMPhotoUtil.m
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import "MMPhotoUtil.h"
#import "MMPhotoMacro.h"
#import "UIViewController+Top.h"

static NSString *kPhotoAlbum = @"MMPhotoPicker";

@implementation MMPhotoUtil

// 主线程执行
void GCD_MAIN(dispatch_block_t block)
{
    dispatch_async(dispatch_get_main_queue(), block);
}

// 保存图片到自定义相册
+ (void)saveImage:(UIImage *)image completion:(void(^)(BOOL success))completion
{
    PHAuthorizationStatus oldStatus = [PHPhotoLibrary authorizationStatus];
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status)
        {
            case PHAuthorizationStatusAuthorized: // 权限打开
            {
                // 获取所有自定义相册
                PHFetchResult * collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
                // 筛选[如果已经存在，则无需再创建]
                __block PHAssetCollection * createCollection = nil;
                __block NSString * collectionID = nil;
                for (PHAssetCollection * collection in collections)  {
                    if ([collection.localizedTitle isEqualToString:kPhotoAlbum]) {
                        createCollection = collection;
                        break;
                    }
                }
                if (!createCollection) {
                    // 创建相册
                    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                        collectionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:kPhotoAlbum].placeholderForCreatedAssetCollection.localIdentifier;
                    } error:nil];
                    // 取出
                    createCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionID] options:nil].firstObject;
                }
                // 保存图片
                __block NSString * assetId = nil;
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    assetId = [PHAssetChangeRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    if (!success) {
                        NSLog(@"保存至【相机胶卷】失败");
                        dispatch_async(dispatch_get_main_queue(), ^{ // 主线程
                            if (completion) completion(NO);
                        });
                        return ;
                    }
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        PHAssetCollectionChangeRequest * request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createCollection];
                        PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
                        // 添加图片到相册中
                        [request addAssets:@[asset]];
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        if (!success) {
                            NSLog(@"保存【自定义相册】失败");
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{ // 主线程
                            if (completion) completion(success);
                        });
                    }];
                }];
                break;
            }
            case PHAuthorizationStatusDenied: // 权限拒绝
            case PHAuthorizationStatusRestricted: // 权限受限
            {
                if (oldStatus == PHAuthorizationStatusNotDetermined) {
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{ // 主线程
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"请在设置>隐私>照片中开启权限" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    }]];
                    [[UIViewController topViewController] presentViewController:alert animated:YES completion:nil];
                });
                break;
            }
            default:
                break;
        }
    }];
}

// 保存视频到自定义相册
+ (void)saveVideo:(NSURL *)videoURL completion:(void(^)(BOOL success))completion
{
    PHAuthorizationStatus oldStatus = [PHPhotoLibrary authorizationStatus];
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status)
        {
            case PHAuthorizationStatusAuthorized:// 权限打开
            {
                // 获取所有自定义相册
                PHFetchResult * collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
                // 筛选[如果已经存在，则无需再创建]
                __block PHAssetCollection * createCollection = nil;
                __block NSString * collectionID = nil;
                for (PHAssetCollection * collection in collections)  {
                    if ([collection.localizedTitle isEqualToString:kPhotoAlbum]) {
                        createCollection = collection;
                        break;
                    }
                }
                if (!createCollection) {
                    // 创建相册
                    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                        collectionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:kPhotoAlbum].placeholderForCreatedAssetCollection.localIdentifier;
                    } error:nil];
                    // 取出
                    createCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionID] options:nil].firstObject;
                }
                // 保存视频
                __block NSString * assetId = nil;
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    assetId = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL].placeholderForCreatedAsset.localIdentifier;
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    if (!success) {
                        NSLog(@"保存至【相机胶卷】失败");
                        dispatch_async(dispatch_get_main_queue(), ^{ // 主线程
                            if (completion) completion(NO);
                        });
                        return ;
                    }
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        PHAssetCollectionChangeRequest * request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createCollection];
                        PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
                        // 添加视频到相册中
                        [request addAssets:@[asset]];
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        if (!success) {
                            NSLog(@"保存【自定义相册】失败");
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{ // 主线程
                            if (completion) completion(success);
                        });
                    }];
                }];
                break;
            }
            case PHAuthorizationStatusDenied: // 权限拒绝
            case PHAuthorizationStatusRestricted: // 权限受限
            {
                if (oldStatus == PHAuthorizationStatusNotDetermined) {
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{ // 主线程
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"请在设置>隐私>照片中开启权限" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    }]];
                    [[UIViewController topViewController] presentViewController:alert animated:YES completion:nil];
                });
                break;
            }
            default:
                break;
        }
    }];
}

// 获取指定相册中照片
+ (NSArray<PHAsset *> *)getAllAssetWithCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending
{
    // ascending:按照片创建时间排序 >> YES:升序 NO:降序
    NSMutableArray<PHAsset *> * assets = [NSMutableArray array];
    PHFetchOptions * option = [[PHFetchOptions alloc] init];
    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascending]];
    PHFetchResult * result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:option];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (((PHAsset *)obj).mediaType == PHAssetMediaTypeImage || ((PHAsset *)obj).mediaType == PHAssetMediaTypeVideo) {
            [assets addObject:obj];
        }
    }];
    return assets;
}

// 获取asset对应的图片
+ (void)getImageWithAsset:(PHAsset *)asset imageSize:(CGSize)size completion:(void (^)(UIImage *image))completion
{
    PHImageRequestOptions * option = [[PHImageRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    option.networkAccessAllowed = YES;
    [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:option resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
        if (completion) completion(image);
    }];
}

// 获取asset对应图片|视频信息
+ (void)getInfoWithAsset:(PHAsset *)phAsset completion:(void (^)(NSDictionary *info))completion
{
    NSMutableDictionary * assetInfo = [[NSMutableDictionary alloc] init];
    [assetInfo setObject:@(phAsset.mediaType) forKey:MMPhotoMediaType];
    if (phAsset.location) {
        [assetInfo setObject:phAsset.location forKey:MMPhotoLocation];
    }
    // == 请求图片和视频资源
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    option.networkAccessAllowed = YES;
    
    PHImageManager * manager = [PHImageManager defaultManager];
    [manager requestImageDataForAsset:phAsset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        // == 图片
        UIImage *image = [UIImage imageWithData:imageData];
        [assetInfo setObject:image forKey:MMPhotoOriginalImage];
        [assetInfo setObject:@(orientation) forKey:MMPhotoOrientation];
        // == 视频
        if (phAsset.mediaType == PHAssetMediaTypeVideo) {
            [manager requestAVAssetForVideo:phAsset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                [assetInfo setObject:((AVURLAsset *)asset).URL forKey:MMPhotoVideoURL];
                [assetInfo setObject:@(phAsset.duration) forKey:MMPhotoVideoDuration];
                if (completion) completion(assetInfo);
            }];
        } else {
            if (completion) completion(assetInfo);
        }
    }];
}

// 获取视频时长(不适用视频时长超过xx:xx:xx这个格式)
+ (NSString *)getDurationFormat:(NSInteger)duration
{
    NSInteger second = duration % 60;  // 秒
    NSInteger minute = duration / 60; // 分
    NSInteger hour = minute / 60; // 时
    minute = minute % 60;
    
    NSString * format = nil;
    if (hour == 0) {
        format = [NSString stringWithFormat:@"%02ld:%02ld",(long)minute,(long)second];
    } else {
        format = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",(long)hour,(long)minute,(long)second];
    }
    return format;
}

// 获取图片
+ (UIImage *)imageNamed:(NSString *)imageName
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

@end

