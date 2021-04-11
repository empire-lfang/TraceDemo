//
//  ViewController.m
//  TraceDemo
//
//  Created by 刘方 on 2021/4/9.
//

#import "ViewController.h"
#import "MakeOrder.h"
#import "TraceDemo-Swift.h"

@interface ViewController ()

@end

@implementation ViewController

void test1(){
    block();
}

void test2(){
    [Test swiftTest];
}

void(^block)(void) = ^{
    
};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    test1();
    
    test2();
    
    //生成新的order文件内容
    [MakeOrder refreshOrderContent];
}


@end
