//
//  ViewController.h
//  news
//
//  Created by li  bo on 16/9/22.
//  Copyright © 2016年 li  bo. All rights reserved.
//

#import "LBBigPictureViewController.h"
#import "UIView+LBExtension.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import <Photos/Photos.h>


#define ScreenW [UIScreen mainScreen].bounds.size.width

#define ScreenH [UIScreen mainScreen].bounds.size.height

@interface LBBigPictureViewController ()

/** 大图scrollView */
@property (nonatomic, weak) UIScrollView *bigScrollView ;

/** 大图图片 */
@property (nonatomic, weak) UIImageView *bigImageView ;

@property (weak, nonatomic) IBOutlet UIButton *saveBtn;


@end

@implementation LBBigPictureViewController


- (UIScrollView *)bigScrollView
{
    if (!_bigScrollView) {
        UIScrollView *bigScrollView = [[UIScrollView alloc] init];
        bigScrollView.x = 0;
        bigScrollView.y = 0;
        bigScrollView.width = ScreenW;
        bigScrollView.height = ScreenH;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBigImageView)];
        [bigScrollView addGestureRecognizer:tap];
        [self.view insertSubview:bigScrollView atIndex:0];
        _bigScrollView = bigScrollView;

    }
    return _bigScrollView;
}

- (UIImageView *)bigImageView
{
    if (!_bigImageView) {
        UIImageView *bigImageView=[[UIImageView alloc]init];

        bigImageView.width = ScreenW;
        [self.bigScrollView addSubview:bigImageView];
        _bigImageView = bigImageView;
    }
    return _bigImageView;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.bigScrollView.backgroundColor = [UIColor grayColor];


    [self setupBigImageView];
}


- (void)awakeFromNib{
    self.view.autoresizingMask = UIViewAutoresizingNone;
    [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bigScrollView setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.bigScrollView.autoresizingMask = UIViewAutoresizingNone;
    [self.bigImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
}

- (void)dismissBigImageView
{

    [self backButtonClick];

}


- (void)setupBigImageView
{

    [self.bigImageView sd_setImageWithURL:[NSURL URLWithString:self.imageSrc] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        self.saveBtn.hidden = NO;
    }];

        CGFloat picH = 220;
        self.bigImageView.height = picH;
        self.bigImageView.center = CGPointMake(ScreenW * 0.5, ScreenH * 0.5);

    }
    //LBLog(@"%@",NSStringFromCGRect(self.bigImageView.frame));


- (IBAction)backButtonClick {
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

/**
 *  获得刚才添加到【相机胶卷】中的图片
 */
- (PHFetchResult<PHAsset *> *)createdAssets
{
    __block NSString *createdAssetId = nil;

    // 添加图片到【相机胶卷】
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdAssetId = [PHAssetChangeRequest creationRequestForAssetFromImage:self.bigImageView.image].placeholderForCreatedAsset.localIdentifier;
    } error:nil];

    if (createdAssetId == nil) return nil;

    // 在保存完毕后取出图片
    return [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetId] options:nil];
}

- (PHAssetCollection *)createdCollection
{
    // 获取软件的名字作为相册的标题
    NSString *title = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];

    // 获得所有的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:title]) {
            return collection;
        }
    }

    // 代码执行到这里，说明还没有自定义相册

    __block NSString *createdCollectionId = nil;

    // 创建一个新的相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdCollectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
    } error:nil];

    if (createdCollectionId == nil) return nil;

    // 创建完毕后再取出相册
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCollectionId] options:nil].firstObject;
}

//保存图片到相册
- (void)saveImageIntoAlbum
{
    // 获得相片
    PHFetchResult<PHAsset *> *createdAssets = self.createdAssets;

    // 获得相册
    PHAssetCollection *createdCollection = self.createdCollection;

    if (createdAssets == nil || createdCollection == nil) {
        [SVProgressHUD showErrorWithStatus:@"保存失败！"];
        return;
    }

    // 将相片添加到相册
    NSError *error = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdCollection];
        [request insertAssets:createdAssets atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];

    // 保存结果
    if (error) {
        [SVProgressHUD showErrorWithStatus:@"保存失败！"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    } else {
        [SVProgressHUD showSuccessWithStatus:@"保存成功！"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }
}

- (IBAction)save {

    PHAuthorizationStatus oldStatus = [PHPhotoLibrary authorizationStatus];

    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case PHAuthorizationStatusAuthorized: {
                    //  保存图片到相册
                    [self saveImageIntoAlbum];
                    break;
                }

                case PHAuthorizationStatusDenied: {
                    if (oldStatus == PHAuthorizationStatusNotDetermined) return;

                    NSLog(@"提醒用户打开相册的访问开关");
                    break;
                }

                case PHAuthorizationStatusRestricted: {
                    [SVProgressHUD showErrorWithStatus:@"因系统原因，无法访问相册！"];
                    break;
                }

                default:
                    break;
            }
        });
    }];


}


- (void)savePhoto
{
    //    UIImageWriteToSavedPhotosAlbum(self.bigImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    //相当于一个标识
    __block NSString *createdAssetId = nil;
    // 添加图片到【相机胶卷】，使用同步方法
    //还有一个异步方法:[[PHPhotoLibrary sharedPhotoLibrary] performChanges
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{//通过传入一个image对象的方式添加图片
        createdAssetId = [PHAssetChangeRequest creationRequestForAssetFromImage:self.bigImageView.image].placeholderForCreatedAsset.localIdentifier;
    } error:nil];

    // 在保存完毕后取出这张刚保存的图片
    PHFetchResult<PHAsset *> *createdAssets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetId] options:nil];

    // 获取软件的名字作为相册的标题
    NSString *title = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];

    // 已经创建的自定义相册
    PHAssetCollection *createdCollection = nil;

    // 获得所有的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:title]) {
            createdCollection = collection;
            break;
        }
    }

    if (!createdCollection) { // 没有创建过相册
        __block NSString *createdCollectionId = nil;
        // 创建一个新的相册
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            createdCollectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
        } error:nil];

        // 创建完毕后再取出相册
        createdCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCollectionId] options:nil].firstObject;
    }
    // 如果照片为空或者相册为空
    if (createdAssets == nil || createdCollection == nil) {
        [SVProgressHUD showErrorWithStatus:@"保存失败！"];
        return;
    }

    //能来到这说明保存成功，将刚才添加到【相机胶卷】的图片，引用（添加）到【自定义相册】
    NSError *error = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdCollection];
        [request insertAssets:createdAssets atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];

    // 保存结果
    if (error) {
        [SVProgressHUD showErrorWithStatus:@"保存失败！"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    } else {
        [SVProgressHUD showSuccessWithStatus:@"保存成功！"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }


}




//- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
//{
//    if (!error) {
//     [SVProgressHUD showSuccessWithStatus:@"保存成功"];
//    }else {
//     [SVProgressHUD showSuccessWithStatus:@"保存失败"];
//    }
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [SVProgressHUD dismiss];
//    });
//
//}
@end
