//
//  MMPhotoAssetController.m
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import "MMPhotoAssetController.h"
#import "MMPhotoPreviewController.h"
#import "MMPhotoMacro.h"
#import "PHAsset+Category.h"
#import "UIViewController+Top.h"

#pragma mark - ################## MMPhotoAssetController
static NSString *const CellIdentifier = @"MMAssetCell";

@interface MMPhotoAssetController () <UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIButton *previewBtn;
@property (nonatomic, strong) UIButton *finishBtn;
@property (nonatomic, strong) UILabel *numberLab;

@property (nonatomic, strong) NSMutableArray<PHAsset *> *assetArray;
@property (nonatomic, strong) NSMutableArray *selectedArray;

@end

@implementation MMPhotoAssetController

#pragma mark - life cycle
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.showVideo = NO;
        self.mainColor = [UIColor colorWithRed:252.0/255.0 green:41.0/255.0 blue:72.0/255.0 alpha:1.0];
        self.unselectIcon = [MMPhotoUtil imageNamed:@"mmphoto_unselect"];
        self.selectIcon = [MMPhotoUtil imageNamed:@"mmphoto_select"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.photoAlbum.name;
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarItemAction)];
    
    if (self.maximumNumber == 0) {
        self.maximumNumber = 9;
    }
    self.assetArray = [[NSMutableArray alloc] init];
    self.selectedArray = [[NSMutableArray alloc] init];
    // 获取相册
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:self.photoAlbum.collection options:option];
    WEAKSELF
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        PHAsset *asset = (PHAsset *)obj;
        asset.selected = NO;
        if (!weakSelf.showVideo) { // 不显示视频
            if (asset.mediaType == PHAssetMediaTypeImage) {
                [weakSelf.assetArray addObject:asset];
            }
        } else {
            [weakSelf.assetArray addObject:asset];
        }
        [weakSelf.collectionView reloadData];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

// 更新UI
- (void)updateUI
{
    if (![self.selectedArray count]) {
        self.bottomView.alpha = 0.5;
        self.numberLab.hidden = YES;
        self.bottomView.userInteractionEnabled = NO;
    } else {
        self.bottomView.alpha = 1.0;
        self.numberLab.hidden = NO;
        self.numberLab.text = [NSString stringWithFormat:@"%d",(int)[self.selectedArray count]];
        self.bottomView.userInteractionEnabled = YES;
    }
}

#pragma mark - 事件处理
// 取消
- (void)rightBarItemAction
{
    !self.onCancel ?: self.onCancel();
}

// 预览
- (void)previewAction
{
    MMPhotoPreviewController *controller = [[MMPhotoPreviewController alloc] init];
    controller.assetArray = self.selectedArray;
    WEAKSELF
    [controller setAssetDeleteHandler:^(PHAsset *asset) {
        asset.selected = NO;
        [weakSelf.collectionView reloadData];
        [weakSelf updateUI];
    }];
    [self.navigationController pushViewController:controller animated:YES];
}

// 确定
- (void)finishAction
{
    if (!self.onCompletion) {
        NSLog(@"警告:未设置block!!!");
        return;
    }
    [self transformAsset:0 totalNum:[self.selectedArray count]];
}

// asset -> info
- (void)transformAsset:(NSInteger)assetIndex totalNum:(NSInteger)count
{
    PHAsset *asset = [self.selectedArray objectAtIndex:assetIndex];
    WEAKSELF
    [MMPhotoUtil getInfoWithAsset:asset completion:^(NSDictionary *info) {
        // info替换asset
        [weakSelf.selectedArray replaceObjectAtIndex:assetIndex withObject:info];
        // 处理下一个
        if (assetIndex != count - 1) {
            [weakSelf transformAsset:assetIndex + 1 totalNum:count];
        } else { // 全部转换后回传
            weakSelf.onCompletion(weakSelf.selectedArray);
        }
    }];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assetArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = [self.assetArray objectAtIndex:indexPath.row];
    MMAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.asset = asset;
    cell.selectIcon = self.selectIcon;
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    PHAsset *asset = [self.assetArray objectAtIndex:indexPath.row];
    // 提醒
    if (([self.selectedArray count] == self.maximumNumber) && !asset.selected) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"最多可以添加%ld张图片",(long)self.maximumNumber] message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }]];
        [[UIViewController topViewController] presentViewController:alert animated:YES completion:nil];
        return;
    }
    asset.selected = !asset.selected;
    [self.collectionView reloadData];
    
    if (asset.selected) {
        [self.selectedArray addObject:asset];
    } else {
        [self.selectedArray removeObject:asset];
    }
    [self updateUI];
}

#pragma mark - lazy load
- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        NSInteger numInLine = [UIScreen mainScreen].bounds.size.width >= 414 ? 5 : 4;
        CGFloat margin = 1.f;
        CGFloat itemWidth = (self.view.bounds.size.width - (numInLine - 1) * margin) / numInLine;
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
        flowLayout.minimumLineSpacing = margin;
        flowLayout.minimumInteritemSpacing = 0.f;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - kTopHeight - self.bottomView.bounds.size.height) collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.scrollEnabled = YES;
        [_collectionView registerClass:[MMAssetCell class] forCellWithReuseIdentifier:CellIdentifier];
        [self.view addSubview:_collectionView];
    }
    return _collectionView;
}

- (UIView *)bottomView
{
    if (!_bottomView) {
        CGFloat btHeight = 50.0f;
        CGFloat height = kSafeAreaHeight + btHeight;
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-kTopHeight-height, self.view.bounds.size.width, height)];
        _bottomView.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:20.0/255.0 blue:20.0/255.0 alpha:1.0];
        _bottomView.userInteractionEnabled = NO;
        _bottomView.alpha = 0.5;
        // 预览
        _previewBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, 50, btHeight)];
        [_previewBtn.titleLabel setFont:[UIFont systemFontOfSize:16.0]];
        [_previewBtn setTitle:@"预览" forState:UIControlStateNormal];
        [_previewBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_previewBtn addTarget:self action:@selector(previewAction) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_previewBtn];
        // 选取的数量
        _numberLab = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-70, (btHeight-20)/2, 20, 20)];
        _numberLab.backgroundColor = self.mainColor;
        _numberLab.layer.cornerRadius = _numberLab.frame.size.height/2;
        _numberLab.layer.masksToBounds = YES;
        _numberLab.textColor = [UIColor whiteColor];
        _numberLab.textAlignment = NSTextAlignmentCenter;
        _numberLab.font = [UIFont boldSystemFontOfSize:13.0];
        _numberLab.adjustsFontSizeToFitWidth = YES;
        [_bottomView addSubview:_numberLab];
        _numberLab.hidden = YES;
        // 完成
        _finishBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-60, 0, 60, btHeight)];
        [_finishBtn.titleLabel setFont:[UIFont systemFontOfSize:16.0]];
        [_finishBtn setTitle:@"确定" forState:UIControlStateNormal];
        [_finishBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_finishBtn addTarget:self action:@selector(finishAction) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_finishBtn];
        [self.view addSubview:_bottomView];
    }
    return _bottomView;
}

#pragma mark -
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
 

#pragma mark - ################## MMAssetCell
@interface MMAssetCell ()

@property (nonatomic, strong) UIImageView *imageView; // 显示图片
@property (nonatomic, strong) UIView *selectView; // 显示已选择蒙版
@property (nonatomic, strong) UIImageView *selectIconView; // 显示已选择icon
@property (nonatomic, strong) UILabel *durationLabel; // 时长

@end

@implementation MMAssetCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.layer.masksToBounds = YES;
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.contentScaleFactor = [[UIScreen mainScreen] scale];
        [self addSubview:_imageView];
        
        _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, self.bounds.size.height-20, self.bounds.size.width-10, 20)];
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.textAlignment = NSTextAlignmentRight;
        _durationLabel.font = [UIFont boldSystemFontOfSize:12.0];
        [self addSubview:_durationLabel];
        _durationLabel.hidden = YES;

        _selectView = [[UIView alloc] initWithFrame:self.bounds];
        _selectView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        [self addSubview:_selectView];
        _selectView.hidden = YES;
        
        _selectIconView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width-25, 5, 20, 20)];
        [_selectView addSubview:_selectIconView];
    }
    return self;
}

#pragma mark - setter
- (void)setSelectIcon:(UIImage *)icon
{
    self.selectIconView.image = icon;
}

- (void)setAsset:(PHAsset *)asset
{
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        self.durationLabel.hidden = NO;
        self.durationLabel.text = [MMPhotoUtil getDurationFormat:asset.duration];
    } else {
        self.durationLabel.hidden = YES;
        self.durationLabel.text = nil;
    }
    self.selectView.hidden = !asset.selected;
    WEAKSELF
    [MMPhotoUtil getImageWithAsset:asset imageSize:CGSizeMake(300, 300) completion:^(UIImage *image) {
        weakSelf.imageView.image = image;
    }];
}

@end
