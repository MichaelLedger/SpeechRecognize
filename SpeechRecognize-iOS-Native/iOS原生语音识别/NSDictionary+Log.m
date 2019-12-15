//
//  NSDictionary+Log.m
//  iOS原生语音识别
//
//  Created by MTX on 2019/12/15.
//  Copyright © 2019 MTX. All rights reserved.
//

#import "NSDictionary+Log.h"

@implementation NSDictionary (Log)

/**
 解决字典输出中文乱码的问题

 @return 输出结果
 */
- (NSString *)descriptionWithLocale:(id)locale
{
    NSArray *allKeys = [self allKeys];
    NSMutableString *str = [[NSMutableString alloc] initWithFormat:@"{\n "];
    for (NSString *key in allKeys) {
        id value=self[key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
            [str appendFormat:@"\"%@\" : %@,\n",key, value];
        }else{
            [str appendFormat:@"\"%@\" : \"%@\",\n",key, value];
        }
    }
    [str appendString:@"}"];
    return str;
}

/*升级了Xcode8之后,打印字典时,不再调用descriptionWithLocale*/
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    NSArray *allKeys = [self allKeys];
    NSMutableString *str = [[NSMutableString alloc] initWithFormat:@"{\n "];
    for (NSString *key in allKeys) {
        id value=self[key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
            [str appendFormat:@"\"%@\" : %@,\n",key, value];
        }else{
            [str appendFormat:@"\"%@\" : \"%@\",\n",key, value];
        }
    }
    [str appendString:@"}"];
    return str;
}

@end
