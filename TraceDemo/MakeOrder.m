//
//  MakeOrder.m
//  TraceDemo
//
//  Created by 刘方 on 2021/4/9.
//

#import "MakeOrder.h"
#include <stdint.h>
#include <stdio.h>
#include <sanitizer/coverage_interface.h>
#import <dlfcn.h>
#import <libkern/OSAtomic.h>

//定义符号结构体
typedef struct{
    void *pc;
    void *next;
} SYNode;

//定义原子队列
static OSQueueHead symbolList = OS_ATOMIC_QUEUE_INIT;

@implementation MakeOrder

+(void)refreshOrderContent{
    NSMutableArray<NSString *> * symbolNames = [NSMutableArray array];
    while (YES) {
        SYNode * node = OSAtomicDequeue(&symbolList, offsetof(SYNode, next));
        if (node == NULL) break;
        
        Dl_info info = {0};
        dladdr(node->pc, &info);
        NSString *name = @(info.dli_sname);
        free(node);
        
        BOOL isObjc = [name hasPrefix:@"-["] || [name hasPrefix:@"+["];
        NSString * symbolName = isObjc ? name : [@"_" stringByAppendingString:name];
        
        [symbolNames insertObject:symbolName atIndex:0];
    }
    NSLog(@"%@",symbolNames);
    
    NSMutableArray *funcs = [NSMutableArray arrayWithCapacity:symbolNames.count];
    NSEnumerator *enumertator = [symbolNames objectEnumerator];
    
    NSString *name;
    while (name = [enumertator nextObject]) {
        if ([funcs containsObject:name]) {
            continue;
        }
        [funcs addObject:name];
    }
    //删除当前调用的方法(+refreshOrderContent)
    NSString *funcStr = [NSString stringWithFormat:@"%s",__FUNCTION__];
    [funcs removeObject:funcStr];
    
    NSLog(@"%@",funcs);
    //转化为字符串
    NSString *fileContentStr = [funcs componentsJoinedByString:@"\n"];
    NSData *content = [fileContentStr dataUsingEncoding:NSUTF8StringEncoding];
    
    //保存至.order文件
    [self saveOrderContent:content];
}

+(void)saveOrderContent:(NSData *)data{
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"demo.order"];
    
    BOOL result = [[NSFileManager defaultManager] createFileAtPath:filePath contents:data attributes:nil];
    if (!result) {
        NSLog(@"order 文件写入错误");
    }
    
}

void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                                    uint32_t *stop) {
  static uint64_t N;  // Counter for the guards.
  if (start == stop || *start) return;  // Initialize only once.
  printf("INIT: %p %p\n", start, stop);
  for (uint32_t *x = start; x < stop; x++)
    *x = ++N;  // Guards should start from 1.
}

void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
    
    //当前函数返回到上一个调用的地址!!
    void *PC = __builtin_return_address(0);
    
    //创建结构体
    SYNode * node = malloc(sizeof(SYNode));
    *node = (SYNode){PC,NULL};
    
    //加入结构体
    OSAtomicEnqueue(&symbolList, node,offsetof(SYNode, next));
}

@end
