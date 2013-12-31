//
//  DataSerializeUtility.m
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "DataSerializeUtility.h"

@implementation DataSerializeUtility

+ (NSString *)generatePOSTDataWithDictionary:(NSDictionary *)dict
{
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    
    for (NSString *key in dict) {
        NSString *val = [dict objectForKey:key];
        
        [parts addObject:[NSString stringWithFormat:@"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                          [val stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    }
    
    return [parts componentsJoinedByString:@"&"];
}


+ (NSString *)parseLeftTicket:(NSString *)rawdata
{
    if ([rawdata characterAtIndex:0] != '<')
        return rawdata;
    else {
        NSInteger start = [rawdata length] - [@"</font>" length] - 1;
        if (start < 0 || [rawdata length] < 1)
            return nil;
        
        NSRange range = NSMakeRange(start, 1);
        return [rawdata substringWithRange:range];
    }
}

+ (NSString *)parseOrderKey:(NSString *)rawdata
{
    
    NSRange r1 = [rawdata rangeOfString:@"ed('"];
    if (r1.length == 0)
        return nil;
    
    NSRange r2 = [rawdata rangeOfString:@"')>"];
    if (r2.length == 0)
        return nil;
    
    
    NSUInteger start = r1.location + r1.length;
    NSUInteger end = r2.location - 1;
    NSRange range = NSMakeRange(start, end - start + 1);
    
    return [rawdata substringWithRange:range];
}


@end



@interface POSTDataConstructor()

@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation POSTDataConstructor

- (id)init
{
    self = [super init];
    if (self) {
        _array = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(NSString *)encodeURL:(NSString *)urlString
{
    CFStringRef newString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlString, NULL, CFSTR("!*'();:@&=+@,/?#[]"), kCFStringEncodingUTF8);
    return (NSString *)CFBridgingRelease(newString);
}

- (void)setObject:(NSString *)value forKey:(NSString *)key
{
    [self.array addObject:[NSString stringWithFormat:@"%@=%@",
                           [self encodeURL:key],
                           [self encodeURL:value]]];
}

- (NSString *)getFinalData
{
    return [self.array componentsJoinedByString:@"&"];
}

@end



@implementation StationInfo

@end