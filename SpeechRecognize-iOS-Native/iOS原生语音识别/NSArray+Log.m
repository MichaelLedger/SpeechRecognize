//
//  NSArray+Log.m
//  iOS原生语音识别
//
//  Created by MTX on 2019/12/15.
//  Copyright © 2019 MTX. All rights reserved.
//

#import "NSArray+Log.h"

@implementation NSArray (Log)

/**
 解决数组输出中文乱码的问题

 @return 输出结果
 */
- (NSString *)descriptionWithLocale:(id)locale
{
    NSMutableString *str = [NSMutableString stringWithFormat:@"[\n"];
    for (id obj in self) {
        if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]]) {
            [str appendFormat:@"%@,\n", obj];
        }else{
            [str appendFormat:@"\"%@\",\n", obj];
        }
    }
    [str appendString:@"]"];
    return str;
}

/*升级了Xcode8之后,打印字典时,不再调用descriptionWithLocale*/
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    NSMutableString *str = [NSMutableString stringWithFormat:@"[\n"];
    for (id obj in self) {
        if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]]) {
            [str appendFormat:@"%@,\n", obj];
        }else{
            [str appendFormat:@"\"%@\",\n", obj];
        }
    }
    [str appendString:@"]"];
    return str;
}

@end
