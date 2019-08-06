//
//  NSDataEx.h
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/8/6.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData(MD5)

- (NSData*)genMd5Hash;

- (NSString*)genStringOfMd5Hash;

- (NSString*)convertMd5DataToUpperString;

@end

NS_ASSUME_NONNULL_END
