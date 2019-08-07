//
//  ThirdInvocationWeakObject.m
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/8/7.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import "ThirdInvocationWeakObject.h"

@implementation ThirdInvocationWeakObject

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature* methodSignature = nil;
    if (self.object)
    {
        methodSignature = [self.object methodSignatureForSelector:aSelector];
        if (methodSignature)
            return methodSignature;
    }
    
    methodSignature = [super methodSignatureForSelector:aSelector];
    if (methodSignature)
        return methodSignature;
    else
        return [super methodSignatureForSelector:@selector(doNothing:)];
}

- (void)forwardInvocation:(NSInvocation*)anInvocation
{
    SEL sel = anInvocation.selector;
    
    if (self.object && [self.object respondsToSelector:sel])
    {
        [anInvocation invokeWithTarget:self.object];
    }
    else
    {
        if (self && [self respondsToSelector:sel])
            [super forwardInvocation:anInvocation];
    }
}

- (void)doNothing:(id)sender
{
    
}

@end
