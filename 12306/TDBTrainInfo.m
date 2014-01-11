//
//  TDBTrainInfo.m
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBTrainInfo.h"

@implementation TDBTrainInfo

- (id)initWithOriginal:(NSDictionary *)raw {
    self = [super init];
    if (self) {
        _original = [raw objectForKey:@"queryLeftNewDTO"];
        _mmStr = [[raw objectForKey:@"secretStr"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    return self;
}

- (NSString *)getTrainNo
{
    return [self.original objectForKey:@"station_train_code"];
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
    return [self.original objectForKey:@"train_no"];
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

- (NSString *)getLocationCode
{
    return @"";
}

- (NSArray *)getLeftTicketStatistics {
    //    @"商务", @"特等", @"一等", @"二等", @"高软", @"软卧", @"硬卧", @"软座", @"硬座", @"无坐", @"其它"
    NSArray *keys = [[NSArray alloc] initWithObjects:@"swz", @"tz", @"zy", @"ze", @"gr", @"rw", @"yw", @"rz", @"yz", @"wz", @"qt", nil];
    NSMutableArray *leftTickets = [NSMutableArray new];
    
    for (NSString *key in keys) {
        NSString *absoluteKey = [NSString stringWithFormat:@"%@_num", key];
        [leftTickets addObject:[_original objectForKey:absoluteKey]];
    };
    return leftTickets;
}

@end
