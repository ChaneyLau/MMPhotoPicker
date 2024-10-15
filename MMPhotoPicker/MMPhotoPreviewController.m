//
//  MMPhotoPreviewController.m
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import "MMPhotoPreviewController.h"
#import "MMPhotoMacro.h"
#import "MMPhotoUtil.h"

@interface MMPhotoPreviewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *titleLab;
@property (nonatomic, strong) MMAVPlayer *curPlayer;
@property (nonatomic, strong) UIImageView *videoOverLay;

@property (nonatomic, strong) NSMutableArray *mediaInfoArray;
@property (nonatomic, strong) NSMutableArray *playerArray;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) BOOL isHidden;
@property (nonatomic, strong) id timeObserver;

@end

@implementation MMPhotoPreviewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    self.isHidden = NO;
    [self configUI];
    [self configAsset];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.translucent = NO;
}

#pragma mark - 设置UI
- (void)configUI
{
    self.title = [NSString stringWithFormat:@"1/%d",(int)[self.assetArray count]];
    // 删除
    UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [deleteButton setImage:[MMPhotoUtil imageNamed:@"mmphoto_delete"] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(deleteAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *deleteButtonItem = [[UIBarButtonItem alloc] initWithCustomView:deleteButton];
    self.navigationItem.rightBarButtonItem = deleteButtonItem;
    // 滚动视图
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.delegate = self;
    self.scrollView.scrollEnabled = YES;
    self.scrollView.userInteractionEnabled = YES;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.scrollView];
    // 双击
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureCallback:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:doubleTap];
    // 单击
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCallback:)];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.scrollView addGestureRecognizer:singleTap];
}

#pragma mark - 手势处理
- (void)doubleTapGestureCallback:(UITapGestureRecognizer *)gesture
{
    [self resetIndex];
    UIScrollView *scrollView = [self.scrollView viewWithTag:100 + self.index];
    CGFloat zoomScale = scrollView.zoomScale;
    if (zoomScale == scrollView.maximumZoomScale) {
        zoomScale = 0;
    } else {
        zoomScale = scrollView.maximumZoomScale;
    }
    [UIView animateWithDuration:0.35 animations:^{
        scrollView.zoomScale = zoomScale;
    }];
}

- (void)singleTapGestureCallback:(UITapGestureRecognizer *)gesture
{
    if (self.curPlayer) { // 控制播放
        NSDictionary *mediaInfo = [self.mediaInfoArray objectAtIndex:self.index];
        UIImage *image = [mediaInfo objectForKey:MMPhotoOriginalImage];
        CGFloat width = self.view.bounds.size.width;
        CGFloat height = width * (image.size.height/image.size.width);
        CGRect rect = CGRectMake(0, (self.view.bounds.size.height-height)/2.0, width, height);
        CGPoint point = [gesture locationInView:gesture.view];
        if (CGRectContainsPoint(rect, point)) {
            BOOL isPlaying = !self.curPlayer.isPlaying;
            [self avplayControl:isPlaying];
            if (!isPlaying) { // 暂停 -> 播放
                // 监听播放进度
                WEAKSELF
                _timeObserver = [self.curPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                    if (time.value == weakSelf.curPlayer.duration.value) { // 播放完成
                        [weakSelf avplayControl:YES]; // 暂停
                        [weakSelf.curPlayer seekToTime:kCMTimeZero];
                        if (weakSelf.timeObserver) {
                            [weakSelf.curPlayer removeTimeObserver:weakSelf.timeObserver];
                            weakSelf.timeObserver = nil;
                        }
                        [UIView animateWithDuration:0.5 animations:^{
                            weakSelf.titleView.hidden = weakSelf.isHidden;
                        }];
                    }
                }];
            }
        } else {
            self.isHidden = !self.isHidden;
        }
    } else {
        self.isHidden = !self.isHidden;
    }
    self.navigationController.navigationBar.alpha = self.isHidden ? 0.f : 1.f;
}

- (void)avplayControl:(BOOL)isPlaying
{
    if (isPlaying) { // 播放
        [self.curPlayer play];
        self.curPlayer.isPlaying = YES;
        self.videoOverLay.hidden = YES;
        self.isHidden = YES;
    } else { // 暂停
        [self.curPlayer pause];
        self.curPlayer.isPlaying = NO;
        self.videoOverLay.hidden = NO;
        self.isHidden = NO;
    }
}

#pragma mark - 删除处理
- (void)backAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)deleteAction
{
    // 移除视图
    PHAsset * asset = [self.assetArray objectAtIndex:self.index];
    [self deleteAsset];
    [self.assetArray removeObjectAtIndex:self.index];
    [self.playerArray removeObjectAtIndex:self.index];
    // 更新索引
    [self resetIndex];
    self.title = [NSString stringWithFormat:@"%ld/%ld",(long)self.index+1,(long)[self.assetArray count]];
    // block
    if (self.assetDeleteHandler) {
        self.assetDeleteHandler(asset);
    }
    // 返回
    if (![self.assetArray count]) {
        [self backAction];
    }
}

#pragma mark - 图像加载|移除
- (void)configAsset
{
    NSInteger count = [self.assetArray count];
    [self.scrollView setPagingEnabled:YES];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width * count, self.scrollView.bounds.size.height)];
    self.curPlayer = nil;
    self.playerArray = [[NSMutableArray alloc] initWithCapacity:count];
    self.mediaInfoArray = [[NSMutableArray alloc] initWithCapacity:count];
    // 添加图片|视频
    [self loadAsset:0 totalNum:count];
}

- (void)loadAsset:(NSInteger)assetIndex totalNum:(NSInteger)count
{
    PHAsset *asset = [self.assetArray objectAtIndex:assetIndex];
    // asset --> 图片|视频
    WEAKSELF
    [MMPhotoUtil getInfoWithAsset:asset completion:^(NSDictionary *info) {
        [weakSelf.mediaInfoArray addObject:info];
        dispatch_async(dispatch_get_main_queue(), ^{ // 主线程
            // 用于图片的捏合缩放
            UIScrollView *zoomScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(weakSelf.scrollView.bounds.size.width * assetIndex, 0, weakSelf.scrollView.bounds.size.width, weakSelf.scrollView.bounds.size.height)];
            zoomScrollView.contentSize = CGSizeMake(zoomScrollView.bounds.size.width, zoomScrollView.bounds.size.height);
            zoomScrollView.minimumZoomScale = 1.0;
            zoomScrollView.delegate = self;
            zoomScrollView.showsHorizontalScrollIndicator = NO;
            zoomScrollView.showsVerticalScrollIndicator = NO;
            zoomScrollView.backgroundColor = [UIColor clearColor];
            zoomScrollView.tag = 100 + assetIndex;
            
            // == 图片
            if (asset.mediaType == PHAssetMediaTypeImage)
            {
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
                imageView.image = [info objectForKey:MMPhotoOriginalImage];
                imageView.clipsToBounds  = YES;
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                imageView.contentScaleFactor = [[UIScreen mainScreen] scale];
                imageView.backgroundColor = [UIColor clearColor];
                imageView.tag = 1000;
                [zoomScrollView addSubview:imageView];
                
                CGSize imgSize = [imageView.image size];
                CGFloat scaleX = self.view.bounds.size.width/imgSize.width;
                CGFloat scaleY = self.view.bounds.size.height/imgSize.height;
                if (scaleX > scaleY) {
                    CGFloat imgViewWidth = imgSize.width * scaleY;
                    zoomScrollView.maximumZoomScale = self.view.bounds.size.width/imgViewWidth;
                } else {
                    CGFloat imgViewHeight = imgSize.height * scaleX;
                    zoomScrollView.maximumZoomScale = self.view.bounds.size.height/imgViewHeight;
                }
                [self.playerArray addObject:@"占位"];
            }
            else // == 视频
            {
                NSURL *videoURL = [info objectForKey:MMPhotoVideoURL];
                AVPlayerItem *playerItem  = [[AVPlayerItem alloc] initWithURL:videoURL];
                MMAVPlayer *player = [[MMAVPlayer alloc] initWithPlayerItem:playerItem];
                player.isPlaying = NO;
                player.duration = playerItem.asset.duration;
                AVPlayerLayer * playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
                playerLayer.frame = zoomScrollView.bounds;
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                [zoomScrollView.layer addSublayer:playerLayer];
                
                UIImageView *videoImgV = [[UIImageView alloc] initWithImage:[MMPhotoUtil imageNamed:@"mmphoto_video"]];
                videoImgV.tag = 2000;
                videoImgV.center = CGPointMake(zoomScrollView.bounds.size.width/2.0, zoomScrollView.bounds.size.height/2.0);
                [zoomScrollView addSubview:videoImgV];
                zoomScrollView.maximumZoomScale = 1.0; // 不可缩放
                [weakSelf.playerArray addObject:player];
                
                if (assetIndex == 0) {
                    weakSelf.curPlayer = player;
                    weakSelf.videoOverLay = videoImgV;
                }
            }
            [weakSelf.scrollView addSubview:zoomScrollView];
            // 处理下一个
            if (assetIndex != count - 1) {
                [weakSelf loadAsset:assetIndex + 1 totalNum:count];
            }
        });
    }];
}

- (void)deleteAsset
{
    // 移除当前视图
    NSInteger tag = 100 + self.index;
    UIScrollView * scrollView = [self.scrollView viewWithTag:tag];
    [scrollView removeFromSuperview];
    // 更新后面视图的Frame和TAG(箭头内的执行过程)
    // ↓↓↓
    NSInteger count = [self.assetArray count];
    UIScrollView * sv = nil;
    // 记录上一个的信息
    CGRect setRect = scrollView.frame;
    NSInteger setTag = tag;
    // 临时数据存储变量
    CGRect tempRect;
    NSInteger tempTag;
    for (NSInteger i = 1; i < count-self.index; i ++) {
        tag ++;
        sv = [self.scrollView viewWithTag:tag];
        // 临时存储
        tempRect = sv.frame;
        tempTag = sv.tag;
        // 将上一个数据赋值给sv
        sv.frame = setRect;
        sv.tag = setTag;
        // 将临时存储赋值
        setRect = tempRect;
        setTag = tempTag;
    }
    // ↑↑↑
    // 更新主滚动视图
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width * (count-1), self.scrollView.bounds.size.height)];
}

- (void)resetIndex
{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    self.index = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return [scrollView viewWithTag:1000];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self resetIndex];
    self.title = [NSString stringWithFormat:@"%ld/%ld",(long)self.index + 1,(long)[self.assetArray count]];
    // 将上一个暂停，记录当前
    if (self.curPlayer) {
        [self.curPlayer pause];
        [self.curPlayer seekToTime:kCMTimeZero];
        if (self.timeObserver) {
            [self.curPlayer removeTimeObserver:self.timeObserver];
            self.timeObserver = nil;
        }
        self.videoOverLay.hidden = NO;
    }
    NSObject *obj = [self.playerArray objectAtIndex:self.index];
    if ([obj isKindOfClass:[MMAVPlayer class]]) {
        UIScrollView * scrollView = [self.scrollView viewWithTag:100+self.index];
        self.videoOverLay = [scrollView viewWithTag:2000];
        self.videoOverLay.hidden = NO;
        self.curPlayer = (MMAVPlayer *)obj;
        self.curPlayer.isPlaying = NO;
    } else {
        self.curPlayer = nil;
        self.videoOverLay = nil;
    }
}

#pragma mark -
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end


@implementation MMAVPlayer

@end
