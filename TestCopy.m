//
//  TestBlock.m
//  a
//
//  Created by clobotics_ccp on 2019/9/23.
//  Copyright © 2019 cool-ccp. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
 **  mstr: 0x600002c56f40_0x7ffee2d9bd18, a: 0x600002c56f10_0x7ffee2d9bd10, b: 0xd6830fc8221ae8cb_0x7ffee2d9bd08
 ** str: 0x10ce68128_0x7ffee2d9bd18, a: 0x10ce68128_0x7ffee2d9bd10, b: 0x600002c56f10_0x7ffee2d9bd08, c: 0x10ce68128_0x7ffee2d9bd00, d: 0x600002c56d60_0x7ffee2d9bcf8
 */
void test_mutable() {
    NSMutableString *mstr = [NSMutableString stringWithString:@"mstr"];
    NSMutableString *a = [mstr mutableCopy];
    NSMutableString *b = [mstr copy];
    NSLog(@"mstr: %p_%p, a: %p_%p, b: %p_%p", mstr, mstr, a, a, b, b);
}

void test_immutable() {
    NSString *str = @"str";
    NSString *a = [str copy];
    NSString *b = [str mutableCopy];
    NSMutableString *c = [str copy];
    NSMutableString *d = [str mutableCopy];
    NSLog(@"str: %p_%p, a: %p_%p, b: %p_%p, c: %p_%p, d: %p_%p", str, str, a, a, b, b, c, c, d, d);
}

void test() {
    test_mutable();
    test_immutable();
}



int main(int argc, char * argv[]) {
    test();
    return 0;
}




