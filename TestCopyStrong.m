//
//  TestBlock.m
//  a
//
//  Created by clobotics_ccp on 2019/9/23.
//  Copyright © 2019 cool-ccp. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface TestClass : NSObject

@property (nonatomic, copy) NSString *mcopyStr;
@property (nonatomic, strong) NSString *mstrongStr;
- (void)test;

@end

@implementation TestClass

- (void)test {
    [self testCopyString_m];
    [self testCopyString];
}

/*
 ** 运行结果
 TestCopyStrong[4818:285488] mstr: mstr<0x7fe500500190>, mcopyStr: mstr<0x5238027c085c0abf>, mstrongStr: mstr<0x7fe500500190>
 TestCopyStrong[4818:285488] mstr: mstr_append<0x7fe500500190>, mcopyStr: mstr<0x5238027c085c0abf>, mstrongStr: mstr_append<0x7fe500500190>
 TestCopyStrong[4818:285488] mstr: mstr_change<0x7fe500500d10>, mcopyStr: mstr<0x5238027c085c0abf>, mstrongStr: mstr_append<0x7fe500500190>
 
 分析:
 1.使用copy修饰的变量进行了深拷贝.其地址发生改变，后续mstr的变化对变量不产生任何影响
 2.使用strong修饰的变量进行了浅拷贝，其地址和mstr一样，后续会随着mstr的改变而改变
 3.mstr重新赋值时，strong修饰的变量不会随着改变，因为二者的地址不一样
 
 */
- (void)testCopyString_m {
    NSLog(@"%s start ---------", __func__);
    NSMutableString *mstr = [NSMutableString stringWithString:@"mstr"];
    self.mcopyStr = mstr;
    self.mstrongStr = mstr;
    NSLog(@"mstr: %@<%p>, mcopyStr: %@<%p>, mstrongStr: %@<%p>", mstr, mstr, self.mcopyStr, self.mcopyStr, self.mstrongStr, self.mstrongStr);
    [mstr appendString: @"_append"];
    NSLog(@"mstr: %@<%p>, mcopyStr: %@<%p>, mstrongStr: %@<%p>", mstr, mstr, self.mcopyStr, self.mcopyStr, self.mstrongStr, self.mstrongStr);
    mstr = [NSMutableString stringWithString:@"mstr_change"];
    NSLog(@"mstr: %@<%p>, mcopyStr: %@<%p>, mstrongStr: %@<%p>", mstr, mstr, self.mcopyStr, self.mcopyStr, self.mstrongStr, self.mstrongStr);
    NSLog(@"%s end ---------", __func__);
}

/*
 ** 运行结果
 TestCopyStrong[4818:285488] mstr: str<0x10c675118>, mcopyStr: str<0x10c675118>, mstrongStr: str<0x10c675118>
 
 分析:
 copy和strong没有区别，都是浅拷贝
 */

- (void)testCopyString {
    NSLog(@"%s start ---------", __func__);
    NSString *str = @"str";
    self.mcopyStr = str;
    self.mstrongStr = str;
    NSLog(@"mstr: %@<%p>, mcopyStr: %@<%p>, mstrongStr: %@<%p>", str, str, self.mcopyStr, self.mcopyStr, self.mstrongStr, self.mstrongStr);
    NSLog(@"%s end ---------", __func__);
}

@end

void test() {
    TestClass *tc = [[TestClass alloc] init];
    [tc test];
}

int main(int argc, char * argv[]) {
    test();
    return 0;
}




