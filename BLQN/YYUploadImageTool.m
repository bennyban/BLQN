//
//  YYUploadImageTool.m
//  client
//
//  Created by 班磊 on 16/6/12.
//  Copyright © 2016年 pajser. All rights reserved.
//

#import "YYUploadImageTool.h"
#import "QiniuPutPolicy.h"

/**
 *  注册七牛获取
 */
static NSString *QiniuAccessKey        = @"3qkO9TCDgqBlNVMbTSeeF5JWbKTse5Sm0P3IpMaW";
static NSString *QiniuSecretKey        = @"7wd8PzW3NGaSVG916S82nZamxbkZ4o0L1BMDEck2";
static NSString *QiniuBucketName       = @"bennyban";
static NSString *QiniuBaseURL          = @"http://7sbxmz.com1.z0.glb.clouddn.com";
static NSString *QiniuImageView2       = @"imageView2/2/w/200/h/200";

@interface YYUploadImageTool ()

@property (copy, nonatomic) void(^singleSuccess)(NSString*url);
@property (copy, nonatomic) void(^singleError)();
@property (copy, nonatomic) void(^singleIsFinish)(BOOL isFinish);

@property (assign, nonatomic) BOOL isSigleUpload;
@property (assign, nonatomic) BOOL isMultiUpload;

@end

@implementation YYUploadImageTool

+ (instancetype)sharedUtil
{
  static YYUploadImageTool *globalNativeHandle = nil;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{ globalNativeHandle = [[self alloc] init];});
  return globalNativeHandle;
}


#pragma mark - 给图片命名
#pragma mark
+ (NSString*)getDateTimeString
{
  NSDateFormatter *formatter;
  NSString *dateString;
  formatter = [[NSDateFormatter alloc]init];
  [formatter setDateFormat:@"yyyyMMddHHmmss"];
  dateString = [formatter stringFromDate:[NSDate date]];
  return dateString;
}

#pragma mark - 获取随机数
#pragma mark
+ (NSString*)randomStringWithLength:(int)len
{
  NSString*letters =@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  NSMutableString*randomString = [NSMutableString stringWithCapacity: len];
  for(int i =0; i<len; i++)
  {
    [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random_uniform((int)[letters length])]];
  }
  return randomString;
}


#pragma mark - 获取token
#pragma mark
+ (NSString *)tokenWithScope:(NSString *)scope
{
  QiniuPutPolicy *policy = [QiniuPutPolicy new];
  policy.scope = scope;
  return [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];
}


#pragma mark - 上传单张图片
#pragma mark
+ (void)uploadImage:(UIImage*)image progress:(YYUploadProgress)progress success:(YYUploadSuccess)success error:(YYUploadError)err isFinish:(YYUploadFinish)isFinished
{
    YYUploadImageTool *uploadImageTool = [YYUploadImageTool sharedUtil];
    
    __weak typeof(uploadImageTool) weakUploadImageTool = uploadImageTool;
    
    // 上传过程中，多次触发时间不会执行
    if (uploadImageTool.isSigleUpload) {
        isFinished (NO);
        return;
    }
    
    NSString *token = [YYUploadImageTool tokenWithScope:QiniuBucketName];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.png", [YYUploadImageTool getDateTimeString], [YYUploadImageTool randomStringWithLength:8]];
    NSData *data = UIImagePNGRepresentation(image);

    QNUploadOption *opt = [[QNUploadOption alloc] initWithMime:nil
                                             progressHandler:^(NSString *key, float percent){
                                                 if (progress) progress (percent);
                                             }
                                                      params:@{ @"x:foo":@"fooval" }
                                                    checkCrc:YES
                                          cancellationSignal:nil];

    QNUploadManager *upManager = [[QNUploadManager alloc] init];

    [upManager putData:data key:fileName token:token
            complete: ^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
              if(info.statusCode==200&& resp)
              {
                if (success) {
                    NSString *url = [NSString stringWithFormat:@"%@/%@",QiniuBaseURL, resp[@"key"]];
                    weakUploadImageTool.isSigleUpload = NO;
                    isFinished (YES);
                    success(url);
                }
                
              } else
              {
                  if (err) err ();
              }
            } option:opt];
    
    // 上传过程中再次触发不会多次执行
    uploadImageTool.isSigleUpload = YES;
}

#pragma mark - 批量上传
#pragma mark
+ (void)uploadImages:(NSArray*)imageArray progress:(YYUploadProgress)progress success:(void(^)(NSArray*urlArr))success error:(YYUploadError)err isFinish:(YYUploadFinish)isFinished
{
    YYUploadImageTool *uploadImageTool = [YYUploadImageTool sharedUtil];
    
    // 上传过程中，多次触发时间不会执行
    
    if (uploadImageTool.isMultiUpload) {
        isFinished (NO);
        return;
    }
    
    NSMutableArray *array = [[NSMutableArray alloc]init];
    __block CGFloat totalProgress = 0.0f;
    __block CGFloat partProgress = 1.0f/[imageArray count];
    __block NSUInteger currentIndex = 0;

    __weak typeof(uploadImageTool) weakUploadImageTool = uploadImageTool;

    weakUploadImageTool.singleSuccess = ^(NSString*url)
    {
    [array addObject:url];

    totalProgress += partProgress;

    progress(totalProgress);

    currentIndex++;

    if([array count] == [imageArray count]) {
      
        success([array copy]);
        weakUploadImageTool.isMultiUpload = NO;
        isFinished (YES);
      
      return;
      
    }else
    {
      [YYUploadImageTool uploadImage:imageArray[currentIndex] progress:nil success:weakUploadImageTool.singleSuccess error:weakUploadImageTool.singleError isFinish:weakUploadImageTool.singleIsFinish];
    }
    };

    weakUploadImageTool.singleError = ^{
    err ();
    };

    weakUploadImageTool.singleIsFinish = ^(BOOL isFinish) {
        if([array count] == [imageArray count]) {
            isFinished(YES);
        } else
        {
            isFinished(NO);
        }
    };

    [YYUploadImageTool uploadImage:imageArray[0] progress:nil success:weakUploadImageTool.singleSuccess error:weakUploadImageTool.singleError isFinish:weakUploadImageTool.singleIsFinish];
  
    // 上传过程中再次触发不会多次执行
    uploadImageTool.isMultiUpload = YES;
}

@end
