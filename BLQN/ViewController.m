//
//  ViewController.m
//  BLQN
//
//  Created by 班磊 on 16/6/11.
//  Copyright © 2016年 bennyban. All rights reserved.
//

#import "ViewController.h"

#import "QiniuSDK.h"
#import "QiniuPutPolicy.h"
#import "UIImage-Extensions.h"
#import "UIImageView+WebCache.h"

#define kDocumentsPath                      [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0]
#define kIOS7_OR_LATER      ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
#define kMainScreenWidth     [[UIScreen mainScreen] bounds].size.width
#define kMainScreenHeight     [[UIScreen mainScreen] bounds].size.height

#define kImageView2  @"imageView2/2/w/200/h/200"

/**
 *  注册七牛获取
 */
static NSString *QiniuAccessKey        = @"3qkO9TCDgqBlNVMbTSeeF5JWbKTse5Sm0P3IpMaW";
static NSString *QiniuSecretKey        = @"7wd8PzW3NGaSVG916S82nZamxbkZ4o0L1BMDEck2";
static NSString *QiniuBucketName       = @"bennyban";
static NSString *QiniuBaseURL          = @"http://7sbxmz.com1.z0.glb.clouddn.com";


#import "YYUploadImageTool.h"

@interface ViewController ()<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation ViewController

#pragma mark - QINIU Method
- (NSString *)tokenWithScope:(NSString *)scope
{
    QiniuPutPolicy *policy = [QiniuPutPolicy new];
    policy.scope = scope;
    return [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *sendPhoto = [[UIButton alloc] initWithFrame:CGRectMake(0, (kMainScreenHeight-64)/2-20, kMainScreenWidth/2, 40)];
    sendPhoto.backgroundColor = [UIColor orangeColor];
    sendPhoto.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [sendPhoto addTarget:self action:@selector(sendPhoto) forControlEvents:UIControlEventTouchUpInside];
    [sendPhoto setTitle:@"上传图片" forState:UIControlStateNormal];
    [self.view addSubview:sendPhoto];
    
}

- (void)sendPhoto
{
    
    [self testQiNiuUploadImage];
//    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"请选择照片来源" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照",@"照片库", nil];
//    [actionSheet showInView:self.view];
}

#pragma mark - Action Sheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        
        [self albumBtnPressed];
    }else if (buttonIndex == 0){
        
        [self cameraBtnPressed];
    }
    
}

- (void)albumBtnPressed
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"提示" message:@"该设备不支持从相册选取文件" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:NULL];
        [alert show];
    }
    else {
        UIImagePickerController *filePicker = [[UIImagePickerController alloc] init];
        filePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        filePicker.delegate = self;
        filePicker.mediaTypes = [NSArray arrayWithObject:@"public.image"];
        filePicker.allowsEditing = YES;
        filePicker.view.backgroundColor = [UIColor whiteColor];
        [self presentViewController:filePicker animated:YES completion:^{
            
            
        }];
    }
}

- (void)cameraBtnPressed
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"提示" message:@"该设备不支持拍照" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:NULL];
        [alert show];
    }
    else {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.sourceType =  UIImagePickerControllerSourceTypeCamera;
        imagePickerController.delegate = self;
        imagePickerController.mediaTypes = [NSArray arrayWithObject:@"public.image"];
        imagePickerController.allowsEditing = YES;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    {
        UIImage *originImage = [info valueForKey:UIImagePickerControllerEditedImage];
        
        CGSize cropSize;
        cropSize.width = 180;
        cropSize.height = cropSize.width * originImage.size.height / originImage.size.width;
        
        NSDate *date = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMddHHmmss"];
        
        originImage = [originImage imageByScalingToSize:cropSize];
        
        NSData *imageData = UIImageJPEGRepresentation(originImage, 0.9f);
        
        NSString *uniqueName = [NSString stringWithFormat:@"%@.jpg",[formatter stringFromDate:date]];
        NSString *uniquePath = [kDocumentsPath stringByAppendingPathComponent:uniqueName];
        
        NSLog(@"uniquePath: %@",uniquePath);
        
        [imageData writeToFile:uniquePath atomically:NO];
        
        NSLog(@"Upload Image Size: %lu KB",[imageData length] / 1024);
        
        [picker dismissViewControllerAnimated:YES completion:^{
            
            NSString *token = [self tokenWithScope:QiniuBucketName];
            
            NSLog(@"\ntoken：%@",token);
            
            QNUploadManager *upManager = [[QNUploadManager alloc] init];
            
//            NSString *path = [[NSBundle mainBundle] pathForResource:@"06" ofType:@"jpg"];
//            NSData   *data = [NSData dataWithContentsOfFile:path];
//            NSString *key = @"photo.jpg";
            
            NSData *data = [NSData dataWithContentsOfFile:uniquePath];
            
            NSString *key = [NSURL fileURLWithPath:uniquePath].lastPathComponent;
            
            QNUploadOption *opt = [[QNUploadOption alloc] initWithMime:nil
                                                       progressHandler:^(NSString *key, float percent){
                                                           NSLog(@"\n百分比：%.2f",percent);
                                                       }
                                                                params:@{ @"x:foo":@"fooval" }
                                                              checkCrc:YES
                                                    cancellationSignal:nil];
            [upManager putData:data key:key token:token
                      complete: ^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                          if (!info.error) {
                              NSString *contentURL = [NSString stringWithFormat:@"%@/%@?%@",QiniuBaseURL,key,kImageView2];
                              
                              NSLog(@"QN Upload Success URL= %@",contentURL);
                              
                              if (_imageView) {
                                  [_imageView removeFromSuperview];
                              }
                              
                              _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(60, 60, 200, 200)];
                              [_imageView sd_setImageWithURL:[NSURL URLWithString:contentURL] placeholderImage:nil];
                              [self.view addSubview:_imageView];
                              
                              //                      [self.faceImage sd_setImageWithURL:[NSURL URLWithString:contentURL] placeholderImage:[UIImage imageNamed:@"cu_icon_default"]];
                              
                          }
                          else {
                              
                              NSLog(@"%@",info.error);
                          }
                      } option:opt];
        }];
    }
}



/************ 测试 ****************/

- (void)testQiNiuUploadImage
{
    UIImage *holdImage = [UIImage imageNamed:@"06.jpg"];
    BOOL isSignle = 0;  // 0 为单张上传  1 为批量上传
    if (!isSignle) {
        // 单张图片:
        [YYUploadImageTool uploadImage:holdImage progress:^(float percent) {
            NSLog(@"\n上传百分比：%.2f",percent);
        } success:^(NSString *url) {
            NSLog(@"\n页面url:%@",url);
        } error:^{
            NSLog(@"\n失败");
        } isFinish:^(BOOL isFinish) {
            if (isFinish) {
                NSLog(@"上传完成");
            } else
            {
                NSLog(@"正在上传");
            }
        }];
    } else
    {
        // 多张图片:
        NSArray *imgArray = @[holdImage, holdImage, holdImage];
        
        
        [YYUploadImageTool uploadImages:imgArray progress:^(float percent) {
            NSLog(@"\n上传百分比：%.2f",percent);
        } success:^(NSArray *urlArr) {
            NSLog(@"\n页面url:%@",urlArr);
        } error:^{
            NSLog(@"\n失败");
        } isFinish:^(BOOL isFinish) {
            
            if (isFinish) {
                NSLog(@"上传完成");
            } else
            {
                NSLog(@"正在上传");
            }
            
            
        }];
    }
}

@end
