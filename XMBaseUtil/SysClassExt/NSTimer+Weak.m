//
//  NSTimer+Weak.m
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/8/7.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import "NSTimer+Weak.h"
#import "ThirdInvocationWeakObject.h"

@implementation NSTimer (Weak)

#pragma mark - public method
+ (NSTimer *)weakScheduledTimerWithTimeIntervalByUserInfo:(NSTimeInterval)interval
                                                    block:(void(^)(void))block
                                                  repeats:(BOOL)repeats
{
    return [self scheduledTimerWithTimeInterval:interval target:self selector:@selector(handleInvokeBlock:) userInfo:[block copy] repeats:repeats];
}

+ (NSTimer *)weakScheduledTimerWithTimeIntervalByUserInfo:(NSTimeInterval)interval
                                               timerBlock:(void(^)(NSTimer *timer))block
                                                  repeats:(BOOL)repeats
{
    return [self scheduledTimerWithTimeInterval:interval target:self selector:@selector(handleInvokeTimerBlock:) userInfo:[block copy] repeats:repeats];
}

+ (NSTimer *)weakScheduledTimerWithTimeIntervalByThirdObject:(NSTimeInterval)interval
                                                      target:(id)aTarget
                                                    selector:(SEL)aSelector
                                                    userInfo:(id)userInfo
                                                     repeats:(BOOL)repeats
{
    return [self scheduledTimerWithTimeInterval:interval target:[self genThirdObject:aTarget] selector:aSelector userInfo:userInfo repeats:repeats];
}

+ (NSTimer *)weakTimerWithTimeIntervalByThirdObject:(NSTimeInterval)interval
                                             target:(id)aTarget
                                           selector:(SEL)aSelector
                                           userInfo:(id)userInfo
                                            repeats:(BOOL)repeats
{
    return [self timerWithTimeInterval:interval target:[self genThirdObject:aTarget] selector:aSelector userInfo:userInfo repeats:repeats];
}

#pragma mark - private method

+ (ThirdInvocationWeakObject*)genThirdObject:(id)aTarget
{
    ThirdInvocationWeakObject* thirdObject;
    thirdObject = [ThirdInvocationWeakObject new];
    thirdObject.object = aTarget;
    
    return thirdObject;
}

+ (void)handleInvokeBlock:(NSTimer *)timer
{
    void (^block)(void) = timer.userInfo;
    if (block) {
        block();
    }
}

+ (void)handleInvokeTimerBlock:(NSTimer *)timer
{
    void (^block)(NSTimer *) = timer.userInfo;
    if (block) {
        block(timer);
    }
}

@end
