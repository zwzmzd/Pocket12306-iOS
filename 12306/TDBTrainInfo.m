//
//  TDBTrainInfo.m
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBTrainInfo.h"

@implementation TDBTrainInfo

- (id)initWithArray:(NSArray *)original
{
    self = [super init];
    if (self) {
        _original = original;
        NSString *s = (NSString *)[_original objectAtIndex:0];
        _keySplitted = [s componentsSeparatedByString:@"#"];
    }
    
    return self;
}

- (NSString *)getTrainNo
{
    return [self.keySplitted objectAtIndex:0];
}

- (NSString *)getDuration
{
    return [self.keySplitted objectAtIndex:1];
}

- (NSString *)getDepartTime
{
    return [self.keySplitted objectAtIndex:2];
}

- (NSString *)getTrainCode
{
    return [self.keySplitted objectAtIndex:3];
}

- (NSString *)getDepartStationTeleCode
{
    return [self.keySplitted objectAtIndex:4];
}

- (NSString *)getArriveStationTeleCode
{
    return [self.keySplitted objectAtIndex:5];
}

- (NSString *)getArriveTime
{
    return [self.keySplitted objectAtIndex:6];
}

- (NSString *)getDapartStationName
{
    return [self.keySplitted objectAtIndex:7];
}

- (NSString *)getArriveStationName
{
    return [self.keySplitted objectAtIndex:8];
}

- (NSString *)getDepartStationNo
{
    return [self.keySplitted objectAtIndex:9];
}

- (NSString *)getArriveStationNo
{
    return [self.keySplitted objectAtIndex:10];
}

- (NSString *)getYPInfoDetail
{
    return [self.keySplitted objectAtIndex:11];
}

- (NSString *)getMMStr
{
    return [self.keySplitted objectAtIndex:12];
}

- (NSString *)getLocationCode
{
    return [self.keySplitted objectAtIndex:13];
}

@end
