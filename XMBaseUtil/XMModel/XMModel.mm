//
//  XMModel.m
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/8/6.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import "XMModel.h"
#include <objc/runtime.h>
#import "NSDataEx.h"

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
        while (cls != [NSObject class])
        {
            unsigned int numberOfIvars = 0;
            Ivar* ivars = class_copyIvarList(cls, &numberOfIvars);
            
            for(const Ivar* p=ivars; p<ivars+numberOfIvars; p++)
            {
                Ivar const ivar = *p;
                const char *type = ivar_getTypeEncoding(ivar);
                NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
                if ([key length] <= 0)   // 包含了key为nil和length为0
                    continue;

                id value = [decoder decodeObjectForKey:key];
                if (value)
                {
                    switch (type[0])
                    {
                        case _C_STRUCT_B:
                        {
                            NSUInteger ivarSize = 0;
                            NSUInteger ivarAlignment = 0;
                            NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
                            NSData *data = [decoder decodeObjectForKey:key];
                            char *sourceIvarLocation = reinterpret_cast<char *>((__bridge void *)self) + ivar_getOffset(ivar);
                            
                            [data getBytes:sourceIvarLocation length:ivarSize];
                            memcpy(reinterpret_cast<char *>((__bridge void *)self) + ivar_getOffset(ivar), sourceIvarLocation, ivarSize);
                        }
                            break;
                        default:
                            [self setValue:value forKey:key];
                            break;
                    }
                }
            }
            if (ivars)
                free(ivars);
            
            cls = class_getSuperclass(cls);
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    Class cls = [self class];

    while (cls != [NSObject class])
    {
        unsigned int numberOfIvars = 0;
        Ivar* ivars = class_copyIvarList(cls, &numberOfIvars);
        for(const Ivar* p = ivars; p < ivars+numberOfIvars; p++)
        {
            Ivar const ivar = *p;
            const char *type = ivar_getTypeEncoding(ivar);
            NSString *key = [NSString stringWithUTF8String:ivar_getName(ivar)];
            if ([key length] <= 0)   // 包含了key为nil和length为0
                continue;
            
            id value = [self valueForKey:key];
            if (!value)
                continue;
            
            switch (type[0])
            {
                case _C_STRUCT_B:
                {
                    NSUInteger ivarSize = 0;
                    NSUInteger ivarAlignment = 0;
                    NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
                    NSData *data = [NSData dataWithBytes:reinterpret_cast<char *>((__bridge void *)self) + ivar_getOffset(ivar)
                                                  length:ivarSize];
                    [encoder encodeObject:data forKey:key];
                }
                    break;
                default:
                    [encoder encodeObject:value forKey:key];
                    break;
            }
        }
        if (ivars)
            free(ivars);
        
        cls = class_getSuperclass(cls);
    }
}




@end
