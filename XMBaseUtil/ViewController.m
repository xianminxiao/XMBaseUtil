//
//  ViewController.m
//  XMBaseUtil
//
//  Created by xianminxiao on 2019/8/6.
//  Copyright © 2019 xianminxiao. All rights reserved.
//

#import "ViewController.h"
#import "XMModel/XMModel.h"

@interface ViewController ()

@end

@interface TestModel : XMModel

@property(nonatomic, assign) NSUInteger age;
@property(nonatomic, assign) BOOL       bTag;

@end

@implementation TestModel

@end

@interface TestSubModel : TestModel

@property(nonatomic, strong) NSString*   info;

@end

@implementation TestSubModel

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    XMModel* model = [XMModel new];
    model = nil;

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //    TestModel* testModel = [TestModel new];
    //    testModel.bTag = YES;
    //    testModel.age = 20;
    //
    //    TestModel* testModel2 = [testModel mutableCopy];
    //    testModel2 = nil;
    

    TestSubModel* testSubModel = [TestSubModel new];
    testSubModel.info = @"xxmtest";
    testSubModel.age = 19;
    testSubModel.bTag = YES;
    
    TestSubModel* testSubModel2 = [testSubModel mutableCopy];
    testSubModel2 = nil;
}


@end
