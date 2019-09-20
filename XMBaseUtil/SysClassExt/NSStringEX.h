//
//  NSStringEX.h
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/9/10.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (MD5)

- (NSString *)MD5String;

@end

// 对有特殊符号的URL做处理（将特殊字符进行转码）
@interface NSString (URL)

- (NSString*)URLEncodeString;
- (NSString*)URLDecodeString;

@end

NS_ASSUME_NONNULL_END
