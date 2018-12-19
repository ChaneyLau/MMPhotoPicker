//
//  ViewController.m
//  MMPhotoPickerDemo
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import "ViewController.h"
#import "MMPhotoPickerController.h"

static NSString * const CellIdentifier = @"PhotoCell";
@interface ViewController () <MMPhotoPickerDelegate,UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView * collectionView;
@property (nonatomic, strong) NSMutableArray * imageArray;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Demo";
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat margin = (self.view.width - 2 * 100) / 3.0;
    
    // 选择图片
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(margin, 50, 100, 44)];
    btn.backgroundColor = [UIColor lightGrayColor];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:@"选择图片" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(pickerClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
   
    // 保存图片到自定义相册
    btn = [[UIButton alloc] initWithFrame:CGRectMake(btn.right+margin, 50, 100, 44)];
    btn.backgroundColor = [UIColor lightGrayColor];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:@"保存图片" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(saveClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
   
    // 图片显示
    self.imageArray = [[NSMutableArray alloc] init];
    [self.view addSubview:self.collectionView];
}

#pragma mark - click
- (void)pickerClicked
{
    MMPhotoPickerController * controller = [[MMPhotoPickerController alloc] init];
    controller.delegate = self;
    controller.showEmptyAlbum = YES;
    controller.maximumNumberOfImage = 9;
//    controller.cropImageOption = YES;
//    controller.singleImageOption = YES;
    UINavigationController * navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    [navigation.navigationBar setBackgroundImage:[UIImage imageNamed:@"default_bar"] forBarMetrics:UIBarMetricsDefault];
    navigation.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor],NSFontAttributeName:[UIFont boldSystemFontOfSize:19.0]};
    navigation.navigationBar.barStyle = UIBarStyleBlackOpaque;
    navigation.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

- (void)saveClicked
{
    UIImage * image = [UIImage imageNamed:@"IMG_4808.JPG"];
    [MMPhotoUtil writeImageToPhotoAlbum:image completionHandler:^(BOOL success) {
        NSString * message = nil;
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
        NSInteger numInLine = (kIPhone6p || kIPhoneXM) ? 5 : 4;
        CGFloat itemWidth = (self.view.width - (numInLine + 1) * kMargin) / numInLine;
        
        UICollectionViewFlowLayout * flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
        flowLayout.sectionInset = UIEdgeInsetsMake(kMargin, kMargin, kMargin, kMargin);
        flowLayout.minimumLineSpacing = kMargin;
        flowLayout.minimumInteritemSpacing = 0.f;
        
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 150, self.view.width, self.view.height-kTopHeight-150) collectionViewLayout:flowLayout];
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
    [self.imageArray removeAllObjects];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i = 0; i < [info count]; i ++)  {
            NSDictionary * dict = [info objectAtIndex:i];
            UIImage * image = [dict objectForKey:MMPhotoOriginalImage];
            if (picker.isOrigin) { // 原图
                [self.imageArray addObject:image];
            } else {
                NSData * imageData = UIImageJPEGRepresentation(image,1.0);
                int size = (int)[imageData length]/1024;
                if (size < 100) {
                    imageData = UIImageJPEGRepresentation(image, 0.5);
                } else {
                    imageData = UIImageJPEGRepresentation(image, 0.1);
                }
                image = [UIImage imageWithData:imageData];
                [self.imageArray addObject:image];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
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
    return self.imageArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 赋值
    PhotoCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.image = [self.imageArray objectAtIndex:indexPath.row];
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

@property (nonatomic, strong) UIImageView * imageView;

@end

@implementation PhotoCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:self.imageView];
    }
    return self;
}

#pragma mark - lazy load
- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.layer.masksToBounds = YES;
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.contentScaleFactor = [[UIScreen mainScreen] scale];
    }
    return _imageView;
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
}

@end
