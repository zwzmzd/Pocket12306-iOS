//
//  TDBStationName.m
//  12306
//
//  Created by macbook on 13-7-21.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBStationName.h"
#import "TDBSession.h"
#import "Defines.h"

@interface TDBStationName()

@property (nonatomic, copy) NSString *raw;
@property (nonatomic) NSArray *stationNameInfo;
@property (nonatomic) NSDictionary *stationNameIndexUsingChinese;

@end

@implementation TDBStationName

- (BOOL)fetchStationNameRawTextFromNet
{
    NSString *path = [NSString stringWithFormat:SYSURL @"/otn/resources/js/framework/station_name.js"];
    NSURL *url = [NSURL URLWithString:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSRange range = [result rangeOfString:@"station_names"];
    if (range.length == 0)
        return NO;
    
    NSRange startPos = [result rangeOfString:@"='"];
    NSRange endPos = [result rangeOfString:@"';"];
    
    NSAssert(startPos.length && endPos.length, @"TDBSessionName fetchStationNameRawTextFromNet with exception");
    
    self.raw = [result substringWithRange:NSMakeRange(startPos.location + startPos.length, endPos.location - startPos.location - startPos.length)];
    return TRUE;
}

- (BOOL)parseRawText
{
    if (self.raw == nil)
        return NO;
    
    NSMutableArray *container = [[NSMutableArray alloc] init];
    NSMutableDictionary *dictForChinese = [[NSMutableDictionary alloc] init];
    NSArray *array = [self.raw componentsSeparatedByString:@"|"];
    NSUInteger count = [array count] - 1;
    for (NSUInteger i = 0; i < count; i += 5) {
        NSArray *element = [[NSArray alloc] initWithObjects:
                            [array objectAtIndex:i],
                            [array objectAtIndex:i + 1],
                            [array objectAtIndex:i + 2],
                            [array objectAtIndex:i + 3],
                            [array objectAtIndex:i + 4], nil];
        [container addObject:element];
        [dictForChinese setObject:element forKey:[element objectAtIndex:1]];
    }
    self.stationNameInfo = container;
    self.stationNameIndexUsingChinese = dictForChinese;
    
    return YES;
}

- (NSString *)getTelecodeUsingName:(NSString *)name
{
    NSArray *element = [self.stationNameIndexUsingChinese objectForKey:name];
    if (element == nil) {
        return nil;
    } else {
        return [element objectAtIndex:2];
    }
}

- (NSArray *)suggestStationNameUsingAbbr:(NSString *)abbr
{
#warning need to implement
    return nil;
}

@end
