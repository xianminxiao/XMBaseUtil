//
//  NSTimer+Weak.h
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/8/7.
//  Copyright © 2019 xianminxiao. All rights reserved.
//
//  解决低版本NSTimer导致强引用，内存泄露问题

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (Weak)

//block存在了userInfo字段中，是一个强引用，但在invalidate时会解引用，所以可以打破引用循环（如果存在的话）
+ (NSTimer *)weakScheduledTimerWithTimeIntervalByUserInfo:(NSTimeInterval)interval
                                                    block:(void(^)(void))block
                                                  repeats:(BOOL)repeats;

+ (NSTimer *)weakScheduledTimerWithTimeIntervalByUserInfo:(NSTimeInterval)interval
                                               timerBlock:(void(^)(NSTimer *timer))block
                                                  repeats:(BOOL)repeats;


+ (NSTimer *)weakScheduledTimerWithTimeIntervalByThirdObject:(NSTimeInterval)interval
                                                      target:(id)aTarget
                                                    selector:(SEL)aSelector
                                                    userInfo:(id)userInfo
                                                     repeats:(BOOL)repeats;

+ (NSTimer *)weakTimerWithTimeIntervalByThirdObject:(NSTimeInterval)interval
                                            target:(id)aTarget
                                          selector:(SEL)aSelector
                                          userInfo:(id)userInfo
                                           repeats:(BOOL)repeats;


@end

NS_ASSUME_NONNULL_END
