//
//  ViewController.m
//  MMPhotoPickerPodDemo
//
//  Created by LEA on 2024/10/14.
//  Copyright © 2024 LEA. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+Color.h"
#import "MMPhotoPickerController.h"
#import <Masonry/Masonry.h>

static NSString * const CellIdentifier = @"PhotoCell";
@interface ViewController () <MMPhotoPickerDelegate,UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView * collectionView;
@property (nonatomic, strong) NSMutableArray * infoArray;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"示例";
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
    // 选择图片
    UIButton *selectButton = [UIButton new];
    selectButton.backgroundColor = [UIColor lightGrayColor];
    [selectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [selectButton setTitle:@"选择图片" forState:UIControlStateNormal];
    [selectButton addTarget:self action:@selector(pickerClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:selectButton];
    [selectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(50);
        make.centerX.equalTo(self.view).offset(-70);
        make.size.mas_equalTo(CGSizeMake(100, 44));
    }];
    // 保存图片
    UIButton *saveButton = [UIButton new];
    saveButton.backgroundColor = [UIColor lightGrayColor];
    [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [saveButton setTitle:@"保存图片" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];
    [saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(50);
        make.centerX.equalTo(self.view).offset(70);
        make.size.mas_equalTo(CGSizeMake(100, 44));
    }];
    // 图片显示
    self.infoArray = [[NSMutableArray alloc] init];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view).offset(0);
        make.top.mas_equalTo(150);
    }];
}

#pragma mark - click
- (void)pickerClicked
{
    // 优先级 cropOption > singleOption > maxNumber
    // cropOption = YES 时，不显示视频
    MMPhotoPickerController *controller = [[MMPhotoPickerController alloc] init];
    controller.maximumNumber = 12;
    controller.showVideo = YES;
    controller.delegate = self;

    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    navigation.modalPresentationStyle = UIModalPresentationFullScreen;
    navigation.navigationBar.tintColor = [UIColor whiteColor];
    navigation.navigationBar.translucent = NO;

    NSMutableDictionary *atts = [NSMutableDictionary new];
    [atts setObject:[UIFont systemFontOfSize:19.0] forKey:NSFontAttributeName];
    [atts setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:20.0/255.0 green:20.0/255.0 blue:20.0/255.0 alpha:1.0]]];
        [appearance setTitleTextAttributes:atts];
        navigation.navigationBar.standardAppearance = appearance;
        navigation.navigationBar.scrollEdgeAppearance = appearance;
    } else {
        [navigation.navigationBar setTitleTextAttributes:atts];
        [navigation.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:20.0/255.0 green:20.0/255.0 blue:20.0/255.0 alpha:1.0]] forBarMetrics:UIBarMetricsDefault];
    }
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)saveClicked
{
    UIImage * image = [UIImage imageNamed:@"default_save"];
    [MMPhotoUtil saveImage:image completion:^(BOOL success) {
        NSString *message = nil;
        if (success) {
            message = @"图片保存成功";
        } else {
            message = @"图片保存出错";
        }
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:message
                                                         message:nil
                                                        delegate:nil
                                               cancelButtonTitle:@"知道了"
                                               otherButtonTitles:nil, nil];
        [alert show];
    }];
}

#pragma mark - lazy load
- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        NSInteger numInLine = [UIScreen mainScreen].bounds.size.width > 414 ? 5 : 4;
        CGFloat margin = 2;
        CGFloat itemWidth = (self.view.bounds.size.width - (numInLine + 1) * margin) / numInLine;
        
        UICollectionViewFlowLayout * flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
        flowLayout.minimumLineSpacing = margin;
        flowLayout.minimumInteritemSpacing = 0.f;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.scrollEnabled = YES;
        [_collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:CellIdentifier];
    }
    return _collectionView;
}

#pragma mark - MMPhotoPickerDelegate
- (void)mmPhotoPickerController:(MMPhotoPickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    [self.infoArray removeAllObjects];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 图片压缩一下，不然大图显示太慢
        for (int i = 0; i < [info count]; i ++) {
            NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:[info objectAtIndex:i]];
            UIImage *image = [dict objectForKey:MMPhotoOriginalImage];
            NSData *imageData = UIImageJPEGRepresentation(image,1.0);
            int size = (int)[imageData length]/1024;
            if (size < 100) {
                imageData = UIImageJPEGRepresentation(image, 0.5);
            } else {
                imageData = UIImageJPEGRepresentation(image, 0.1);
            }
            image = [UIImage imageWithData:imageData];
            [dict setObject:image forKey:MMPhotoOriginalImage];
            [self.infoArray addObject:dict];
        }
        dispatch_async(dispatch_get_main_queue(), ^{ // 主线程
            [self.collectionView reloadData];
            [picker dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

- (void)mmPhotoPickerControllerDidCancel:(MMPhotoPickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.infoArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 赋值
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.info = [self.infoArray objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark -
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end

#pragma mark - ####################  PhotoCell

@interface PhotoCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *durationLabel;  

@end

@implementation PhotoCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor lightGrayColor];
        
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
    }
    return self;
}

#pragma mark - setter
- (void)setInfo:(NSDictionary *)info
{
    PHAssetMediaType mediaType = [[info objectForKey:MMPhotoMediaType] integerValue];
    if (mediaType == PHAssetMediaTypeVideo) {
        self.durationLabel.hidden = NO;
        self.durationLabel.text = [MMPhotoUtil getDurationFormat:[[info objectForKey:MMPhotoVideoDuration] integerValue]];
    } else {
        self.durationLabel.hidden = YES;
        self.durationLabel.text = nil;
    }
    self.imageView.image = [info objectForKey:MMPhotoOriginalImage];
}

@end
