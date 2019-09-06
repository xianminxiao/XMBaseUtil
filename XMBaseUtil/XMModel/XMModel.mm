//
//  XMModel.m
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/8/6.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import "XMModel.h"
#include <objc/runtime.h>
#import "NSData+MD5.h"


@interface XMModel() <NSCoding, NSCopying, NSMutableCopying>
@end


@implementation XMModel

#pragma mark - public method
- (NSString*)genMD5ByAllProperty
{
    NSMutableString* description = [NSMutableString string];
    Class cls = [self class];
    while (cls != [NSObject class])
    {
        unsigned int numberOfProperty = 0;
        objc_property_t* propertList = class_copyPropertyList(cls, &numberOfProperty);
        for(const objc_property_t* p=propertList; p<propertList+numberOfProperty; p++)
        {
            objc_property_t const property = *p;
            const char* type = property_getName(property);
            NSString* key = [NSString stringWithUTF8String:type];
            id value = [self valueForKey:key];
            if(!value)
                continue;
            NSString* dValue = [value description];
            [description appendString:dValue?dValue:@""];
            
        }
        if(propertList)
        {
            free(propertList);
            propertList = nil;
        }
        cls = class_getSuperclass(cls);
    }
    
    NSData* data = [description dataUsingEncoding:NSUTF8StringEncoding];
    return [data genStringOfMd5Hash];
}


#pragma mark - protocol NSCoding
- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        Class cls = [self class];
        [self coderWithClass:cls coder:decoder bEncode:NO];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    Class cls = [self class];
    [self coderWithClass:cls coder:encoder bEncode:YES];
}

#pragma mark - protocol NSCopying
- (id)copyWithZone:(NSZone*)zone
{
    return [self copyWithZone:zone bMutableCopy:NO];
}

#pragma mark - protocol NSMutableCopying
- (id)mutableCopyWithZone:(NSZone*)zone
{
    return [self copyWithZone:zone bMutableCopy:YES];
}

#pragma mark - private method
- (void)coderWithClass:(Class)cls coder:(NSCoder*)coder bEncode:(BOOL)bEncode
{
    while (cls != [NSObject class])
    {
        unsigned int numberOfIvars = 0;
        Ivar* ivars = class_copyIvarList(cls, &numberOfIvars);
        for(const Ivar* p=ivars; p<(ivars + numberOfIvars); p++)
        {
            Ivar const ivar = *p;
            const char *type = ivar_getTypeEncoding(ivar);
            NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
            if ([key length] <= 0)   // 包含了key为nil和length为0
                continue;
            
            id value = bEncode ? [self valueForKey:key] : [coder decodeObjectForKey:key];
            if (!value)
                continue;
            
            switch (type[0])
            {
                case _C_STRUCT_B:
                {
                    NSUInteger ivarSize = 0;
                    NSUInteger ivarAlignment = 0;
                    NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
                    NSData *data = nil;
                    if (bEncode)
                    {
                        [NSData dataWithBytes:reinterpret_cast<char *>((__bridge void *)self) + ivar_getOffset(ivar) length:ivarSize];
                        [coder encodeObject:data forKey:key];
                    }
                    else
                    {
                        NSData *data = [coder decodeObjectForKey:key];
                        char *sourceIvarLocation = reinterpret_cast<char *>((__bridge void *)self) + ivar_getOffset(ivar);
                        
                        [data getBytes:sourceIvarLocation length:ivarSize];
                        memcpy(reinterpret_cast<char *>((__bridge void *)self) + ivar_getOffset(ivar), sourceIvarLocation, ivarSize);
                    }
                }
                    break;
                default:
                    bEncode ? [coder encodeObject:value forKey:key] : [self setValue:value forKey:key];
                    break;
            }
        }
        if (ivars)
            free(ivars);
        
        cls = class_getSuperclass(cls);
    }
}

- (id)copyWithZone:(NSZone *)zone bMutableCopy:(BOOL)bMutableCopy
{
    Class cls = [self class];
    id objCopy = [[cls allocWithZone:zone] init];

    while (cls != [NSObject class])
    {
        [self copyWithObjCopy:objCopy WithClass:cls Zone:zone bMutableCopy:bMutableCopy];
        cls = class_getSuperclass(cls);
    }
    
    return objCopy;
}

- (void)copyWithObjCopy:(id)objCopy WithClass:(Class)cls Zone:(NSZone *)zone bMutableCopy:(BOOL)bMutableCopy
{
    unsigned int propertyCount = 0;
    objc_property_t* propertyArray = class_copyPropertyList(cls, &propertyCount);
    for (int i=0; i<propertyCount; i++)
    {
        objc_property_t property = propertyArray[i];
        const char * propertyName = property_getName(property);
        NSString* key = [NSString stringWithUTF8String:propertyName];
        id value=[self valueForKey:key];
        
        do
        {
            if (bMutableCopy)
            {
                if ([value respondsToSelector:@selector(mutableCopyWithZone:)])
                {
                    [objCopy setValue:[value mutableCopy] forKey:key];
                    break;
                }
            }
            else
            {
                if ([value respondsToSelector:@selector(copyWithZone:)])
                {
                    [objCopy setValue:[value copy] forKey:key];
                    break;
                }
            }
            [objCopy setValue:value forKey:key];
        }while (NO);
    }
    
    if (propertyArray)
        free(propertyArray);
}


@end
