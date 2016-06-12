//
//  QiniuAuthPolicy.m
//  QiniuSDK
//
//  Created by Qiniu Developers 2013
//

#import "QiniuPutPolicy.h"
#import <CommonCrypto/CommonHMAC.h>
//#import "GTMBase64.h"
#import "QN_GTM_Base64.h"

@implementation QiniuPutPolicy

@synthesize scope;
@synthesize callbackUrl;
@synthesize callbackBody;
@synthesize returnUrl;
@synthesize returnBody;
@synthesize asyncOps;
@synthesize endUser;
@synthesize expires;

// Make a token string conform to the UpToken spec.

- (NSString *)makeToken:(NSString *)accessKey secretKey:(NSString *)secretKey
{
    const char *secretKeyStr = [secretKey UTF8String];
    
	NSString *policy = [self marshal];
    
    NSData *policyData = [policy dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *encodedPolicy = [QN_GTM_Base64 stringByWebSafeEncodingData:policyData padded:TRUE];
    const char *encodedPolicyStr = [encodedPolicy cStringUsingEncoding:NSUTF8StringEncoding];
    
    char digestStr[CC_SHA1_DIGEST_LENGTH];
    bzero(digestStr, 0);
    
    CCHmac(kCCHmacAlgSHA1, secretKeyStr, strlen(secretKeyStr), encodedPolicyStr, strlen(encodedPolicyStr), digestStr);
    
    NSString *encodedDigest = [QN_GTM_Base64 stringByWebSafeEncodingBytes:digestStr length:CC_SHA1_DIGEST_LENGTH padded:TRUE];
    
    NSString *token = [NSString stringWithFormat:@"%@:%@:%@",  accessKey, encodedDigest, encodedPolicy];
    
	return token;
}

// Marshal as JSON format string.

- (NSString *)marshal
{
    time_t deadline;
    time(&deadline);
    
    deadline += (self.expires > 0) ? self.expires : 3600; // 1 hour by default.
    NSNumber *deadlineNumber = [NSNumber numberWithLongLong:deadline];

    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    if (self.scope) {
        [dic setObject:self.scope forKey:@"scope"];
    }
    if (self.callbackUrl) {
        [dic setObject:self.callbackUrl forKey:@"callbackUrl"];
    }
    if (self.callbackBody) {
        [dic setObject:self.callbackBody forKey:@"callbackBody"];
    }
    if (self.returnUrl) {
        [dic setObject:self.returnUrl forKey:@"returnUrl"];
    }
    if (self.returnBody) {
        [dic setObject:self.returnBody forKey:@"returnBody"];
    }
    if (self.endUser) {
        [dic setObject:self.endUser forKey:@"endUser"];
    }
    if(self.persistentOps)
    {
        [dic setObject:self.persistentOps forKey:@"persistentOps"];
    }
    if(self.persistentPipeline)
    {
        [dic setObject:self.persistentPipeline forKey:@"persistentPipeline"];
    }
    
    [dic setObject:deadlineNumber forKey:@"deadline"];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    NSString *json =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return json;
}

@end