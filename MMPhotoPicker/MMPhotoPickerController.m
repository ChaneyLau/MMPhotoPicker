//
//  MMPhotoPickerController.m
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import "MMPhotoPickerController.h"
#import "MMPhotoAssetController.h"
#import "MMPhotoMacro.h"
#import "MMPhotoUtil.h"
#import "UIViewController+Top.h"

static CGFloat kRowHeight = 60.f;

#pragma mark - ################## MMPhotoPickerController
@interface MMPhotoPickerController () <UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<MMPhotoAlbum *> *photoAlbums;
@property (nonatomic, strong) MMPhotoAlbum *selectPhotoAlbum;

@end

@implementation MMPhotoPickerController

#pragma mark - life cycle
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.showVideo = NO;
        self.maximumNumber = 9;
        self.mainColor = [UIColor colorWithRed:252.0/255.0 green:41.0/255.0 blue:72.0/255.0 alpha:1.0];
        self.unselectIcon = [MMPhotoUtil imageNamed:@"mmphoto_unselect"];
        self.selectIcon = [MMPhotoUtil imageNamed:@"mmphoto_select"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"照片";
    self.view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarItemAction)];
    [self.view addSubview:self.tableView];
    // 相册权限
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{ // 主线程
            switch (status) {
                case PHAuthorizationStatusAuthorized: { // 权限打开
                    [self loadAlbumData]; // 加载相册
                    break;
                }
                case PHAuthorizationStatusDenied: // 权限拒绝
                case PHAuthorizationStatusRestricted: { // 权限受限
                    if (authStatus == PHAuthorizationStatusNotDetermined) {
                        [self rightBarItemAction]; // 返回
                        return;
                    }
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"请在设置>隐私>照片中开启权限" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self rightBarItemAction];
                    }]];
                    [[UIViewController topViewController] presentViewController:alert animated:YES completion:nil];
                    break;
                }
                default:
                    break;
            }
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

#pragma mark - 相册列表
- (void)loadAlbumData
{
    self.photoAlbums = [[NSMutableArray alloc] init];
    // 获取智能相册
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    WEAKSELF
    [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL *stop) {
        // 过滤掉已隐藏、最近删除
        BOOL condition = (collection.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumAllHidden) && (collection.assetCollectionSubtype != 1000000201);
        if (!self.showVideo) { // 过滤掉视频
            condition = condition && (collection.assetCollectionSubtype !=  PHAssetCollectionSubtypeSmartAlbumVideos);
        }
        if (condition) {
            NSArray<PHAsset *> * assets = [MMPhotoUtil getAllAssetWithCollection:collection ascending:NO];
            if ([assets count] > 0) { // 不显示空相册
                MMPhotoAlbum *album = [[MMPhotoAlbum alloc] init];
                album.name = collection.localizedTitle;
                album.assetCount = assets.count;
                album.collection = collection;
                album.coverAsset = assets.firstObject;
                // '所有照片'置顶
                if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                    [weakSelf.photoAlbums insertObject:album atIndex:0];
                    weakSelf.selectPhotoAlbum = album;
                } else {
                    [weakSelf.photoAlbums addObject:album];
                }
            }
        }
    }];
    // 获取用户创建相册
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<PHAsset *> *assets = [MMPhotoUtil getAllAssetWithCollection:collection ascending:NO];
        if (assets.count > 0) {
            MMPhotoAlbum *album = [[MMPhotoAlbum alloc] init];
            album.name = collection.localizedTitle;
            album.assetCount = assets.count;
            album.coverAsset = assets.firstObject;
            album.collection = collection;
            [self.photoAlbums addObject:album];
        }
    }];
    [self.tableView reloadData];
    // 跳转
    [self jumpToAlbum:_selectPhotoAlbum animated:NO];
}

#pragma mark - 跳转
- (void)jumpToAlbum:(MMPhotoAlbum *)photoAlbum animated:(BOOL)animated
{
    MMPhotoAssetController * controller = [[MMPhotoAssetController alloc] init];
    controller.photoAlbum = photoAlbum;
    controller.showVideo = self.showVideo;
    controller.maximumNumber = self.maximumNumber;
    controller.mainColor = self.mainColor;
    controller.unselectIcon = self.unselectIcon;
    controller.selectIcon = self.selectIcon;
    WEAKSELF
    [controller setOnCompletion:^(NSArray *mediaInfo) { // 确认选择
        if ([weakSelf.delegate respondsToSelector:@selector(mmPhotoPickerController:didFinishPickingMediaWithInfo:)]) {
            [weakSelf.delegate mmPhotoPickerController:weakSelf didFinishPickingMediaWithInfo:mediaInfo];
        }
    }];
    [controller setOnCancel:^{ // 取消
        if ([weakSelf.delegate respondsToSelector:@selector(mmPhotoPickerControllerDidCancel:)]) {
            [weakSelf.delegate mmPhotoPickerControllerDidCancel:weakSelf];
        } else {
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [self.navigationController pushViewController:controller animated:animated];
}

#pragma mark - 取消
- (void)rightBarItemAction
{
    if ([self.delegate respondsToSelector:@selector(mmPhotoPickerControllerDidCancel:)]) {
        [self.delegate mmPhotoPickerControllerDidCancel:self];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.photoAlbums count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MMPhotoAlbumCell";
    MMPhotoAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MMPhotoAlbumCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.textLabel.textColor = [UIColor grayColor];
    // 封面
    MMPhotoAlbum *album = [self.photoAlbums objectAtIndex:indexPath.row];
    if (album.coverAsset) {
        [MMPhotoUtil getImageWithAsset:album.coverAsset imageSize:cell.imageView.bounds.size completion:^(UIImage *image) {
            cell.imageView.image = image;
        }];
    } else {
        cell.imageView.image = [MMPhotoUtil imageNamed:@"mmphoto_empty"];
    }
    // 数量
    NSString *text = [NSString stringWithFormat:@"%@  (%ld)",album.name, (long)album.assetCount];
    NSMutableAttributedString *attText = [[NSMutableAttributedString alloc] initWithString:text];
    [attText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0,[album.name length])];
    [attText addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0] range:NSMakeRange(0,[album.name length])];
    cell.textLabel.attributedText = attText;
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // 跳转
    MMPhotoAlbum *album = [self.photoAlbums objectAtIndex:indexPath.row];
    [self jumpToAlbum:album animated:YES];
}

#pragma mark - lazy load
- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-kTopHeight) style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = kRowHeight;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
        _tableView.tableFooterView = [UIView new];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _tableView;
}

#pragma mark -
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end

#pragma mark - ################## MMPhotoAlbum
@implementation MMPhotoAlbum

@end

#pragma mark - ################## MMPhotoAlbumCell
@implementation MMPhotoAlbumCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.contentScaleFactor = [UIScreen mainScreen].scale;
    self.imageView.clipsToBounds = YES;
    self.imageView.frame = CGRectMake(0, 0, kRowHeight, kRowHeight);
    self.textLabel.frame = CGRectMake(kRowHeight + 10, 0, self.bounds.size.width - kRowHeight - 40, kRowHeight);
    self.separatorInset = UIEdgeInsetsZero;
}

@end
