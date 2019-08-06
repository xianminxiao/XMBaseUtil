//
//  NSDataEx.m
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/8/6.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import "NSDataEx.h"
#import <CommonCrypto/CommonDigest.h>
#import "ToolFunctions.h"

@implementation NSData(MD5)

- (NSData*)genMd5Hash
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, result);
    
    return [[NSData alloc] initWithBytes:result length:CC_MD5_DIGEST_LENGTH];
}

- (NSString*)genStringOfMd5Hash
{
    return [[self genMd5Hash] convertMd5DataToUpperString];
}

- (NSString*)convertMd5DataToUpperString
{
    if ([self length] != CC_MD5_DIGEST_LENGTH)
        return nil;
    
    unsigned char md5str[CC_MD5_DIGEST_LENGTH*2+1] = {0};
    hex2strUpper((char*)[self bytes], CC_MD5_DIGEST_LENGTH, (char*)md5str);
    NSString* strMd5 = [NSString stringWithUTF8String:(const char*)md5str];
    return strMd5;
}

@end
