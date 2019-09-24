//
//  UIColorEX.m
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/9/24.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import "UIColorEX.h"

@implementation UIColor (EX)

+ (UIColor *)colorWithRGBHexString:(NSString *)rgbString
{
    if ([rgbString length] == 0)
        return nil;

    NSScanner *scanner = [NSScanner scannerWithString:rgbString];
    if ([rgbString hasPrefix:@"#"])
        scanner.scanLocation = 1;
    else if (rgbString.length >= 2 && [[[rgbString substringToIndex:2] lowercaseString] isEqualToString:@"0x"])
        scanner.scanLocation = 2;
    
    unsigned int value = 0;
    [scanner scanHexInt:&value];
    
    return [self colorWithRGBHex:value];
}

+ (UIColor *)colorWithARGBHexString:(NSString *)argbString
{
    if (argbString == nil)
        return nil;

    if ([argbString hasPrefix:@"#"])
        argbString = [argbString substringFromIndex:1];

    if (argbString.length == 6)
        return [self colorWithRGBHexString:argbString];
    
    unsigned int value = 0;
    [[NSScanner scannerWithString:argbString] scanHexInt:&value];
    
    return [self colorWithARGBHex:value];
}

+ (UIColor *)colorWithRGBHex: (unsigned int)hex
{
    unsigned int a = 0xFF << 24;
    hex = a + hex;
    
    return [self colorWithARGBHex:hex];
}

+ (UIColor *)colorWithARGBHex: (unsigned int)hex
{
    int a = (hex >> 24) & 0xFF;
    int r = (hex >> 16) & 0xFF;
    int g = (hex >> 8) & 0xFF;
    int b = (hex) & 0xFF;
    
    return [UIColor colorWithRed:r / 255.0f
                           green:g / 255.0f
                            blue:b / 255.0f
                           alpha:a / 255.0f];
}

+ (NSString*)ARGBHexFromUIColor:(UIColor*)color;
{
    CGFloat red = 0.0, green  = 0.0, blue = 0.0, alpha = 0.0;
    if (color && [color getRed:&red green:&green blue:&blue alpha:&alpha])
    {
        return [NSString stringWithFormat:@"0x%02X%02X%02X%02X", (int)(alpha*255.0), (int)(red*255.0), (int)(green*255.0),  (int)(blue*255.0)];
    }
    
    return @"0xFF000000";
}

- (BOOL)isEqualToColor:(UIColor*)color
{
    CGFloat lr,lg,lb,la;
    CGFloat gr,gg,gb,ga;
    
    [self getRed:&lr green:&lg blue:&lb alpha:&la];
    [color getRed:&gr green:&gg blue:&gb alpha:&ga];
    
    return (lr==gr)&&(lg==gg)&&(lb==gb)&&(la==ga);
}

@end
