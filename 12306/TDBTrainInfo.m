//
//  TDBTrainInfo.m
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBTrainInfo.h"

@implementation TDBTrainInfo

- (id)initWithDict:(NSDictionary *)original {
    _original = original;
}

- (NSString *)getTrainNo
{
    return [self.original objectForKey:@"train_no"];
}

- (NSString *)getDuration
{
    return [self.original objectForKey:@"lishi"];
}

- (NSString *)getDepartTime
{
    return [self.original objectForKey:@"start_time"];
}

- (NSString *)getTrainCode
{
    return [self.original objectForKey:@"station_train_code"];
}

- (NSString *)getDepartStationTeleCode
{
    return [self.original objectForKey:@"from_station_telecode"];
}

- (NSString *)getArriveStationTeleCode
{
    return [self.original objectForKey:@"to_station_telecode"];
}

- (NSString *)getArriveTime
{
    return [self.original objectForKey:@"arrive_time"];
}

- (NSString *)getDapartStationName
{
    return [self.original objectForKey:@"from_station_name"];
}

- (NSString *)getArriveStationName
{
    return [self.original objectForKey:@"to_station_name"];
}

- (NSString *)getDepartStationNo
{
    return [self.original objectForKey:@"from_station_no"];
}

- (NSString *)getArriveStationNo
{
    return [self.original objectForKey:@"to_station_no"];
}

- (NSString *)getYPInfoDetail
{
    return [self.original objectForKey:@"yp_info"];
}

- (NSString *)getMMStr
{
    return [self.original objectForKey:@"secretStr"];
}

- (NSString *)getLocationCode
{
    return @"";
}

@end
