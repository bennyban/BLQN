//
//  YYUploadImageTool.h
//  client
//
//  Created by 班磊 on 16/6/12.
//  Copyright © 2016年 pajser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "QiniuSDK.h"

typedef void(^YYUploadProgress)(float percent);   /**< 文件上传进度条 */
typedef void(^YYUploadSuccess)(NSString*url);     /**< 上传成功的URL */
typedef void(^YYUploadError)();                   /**< 错误 */
typedef void(^YYUploadFinish)(BOOL isFinish);     /**< 是否上传完成 */

@interface YYUploadImageTool : NSObject

/*!
 *  @brief 单张上传
 *
 *  @param image    图片
 *  @param progress 上传的进度
 *  @param success  成功的URL链接
 *  @param err      错误
 */
+ (void)uploadImage:(UIImage*)image progress:(YYUploadProgress)progress success:(YYUploadSuccess)success error:(YYUploadError)err isFinish:(YYUploadFinish)isFinished;

/*!
 *  @brief 批量上传
 *
 *  @param imageArray 图片的数组
 *  @param progress   上传进度条
 *  @param success    成功的URL链接数组
 *  @param err        错误
 */
+ (void)uploadImages:(NSArray*)imageArray progress:(YYUploadProgress)progress success:(void(^)(NSArray*urlArr))success error:(YYUploadError)err isFinish:(YYUploadFinish)isFinished;

@end
