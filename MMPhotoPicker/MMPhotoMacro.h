//
//  MMPhotoPickeMacro.h
//  Pods
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#ifndef MMPhotoPickeMacro_h
#define MMPhotoPickeMacro_h

// >>>>> 安全区域高度【头部有刘海的iPhone】
CG_INLINE CGFloat MMSafeAreaHeight() {
    
    CGFloat height = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow * mainWindow = [[[UIApplication sharedApplication] delegate] window];
        height = mainWindow.safeAreaInsets.bottom;
    }
    return height;
}

#ifndef WEAKSELF
#define WEAKSELF                __typeof(&*self) __weak weakSelf = self;
#endif

// 安全区域高度
#define kSafeAreaHeight         MMSafeAreaHeight()
// 顶部整体高度
#define kTopHeight              (kStatusHeight + kNavHeight)
// 状态栏高度
#define kStatusHeight           [[UIApplication sharedApplication] statusBarFrame].size.height
// 导航栏高度
#define kNavHeight              [UIViewController topViewController].navigationController.navigationBar.bounds.size.height


// 资源类型 PHAssetMediaType
#define MMPhotoMediaType        @"mediaType"
// 图片地理位置
#define MMPhotoLocation         @"location"
// 图片方向
#define MMPhotoOrientation      @"orientation"
// 原始图片
#define MMPhotoOriginalImage    @"originalImage"
// 视频路径
#define MMPhotoVideoURL         @"videoURL"
// 视频时长
#define MMPhotoVideoDuration    @"videoDuration"



#endif /* MMPhotoPickeMacro_h */
