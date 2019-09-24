//
//  UIColorEX.h
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/9/24.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define RGBACOLOR(r,g,b,a)        [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define RGBCOLOR(r,g,b)           [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define COLORWITHRGBA(r,g,b,a)    [UIColor colorWithRed:r green:g blue:b alpha:a]

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (EX)

+ (UIColor*)colorWithRGBHex:(unsigned int)hex;
+ (UIColor*)colorWithARGBHex:(unsigned int)hex;

//支持FFFFFF、#FFFFFF、0xFFFFFF三种格式
+ (UIColor*)colorWithRGBHexString:(NSString*)rgbString;
+ (UIColor*)colorWithARGBHexString:(NSString*)argbString;

+ (NSString*)ARGBHexFromUIColor:(UIColor*)color;

- (BOOL)isEqualToColor:(UIColor*)color; 

@end

NS_ASSUME_NONNULL_END
