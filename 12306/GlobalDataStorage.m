//
//  GlobalDataStorage.m
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "GlobalDataStorage.h"
#import "TDBSession.h"

static TDBSession *_tdbss = nil;
static NSArray *_seatNameAbbr;
static NSArray *_seatNameFull;

static NSString *_userInputDepartStation = nil;
static NSString *_userInputArriveStation = nil;

@implementation GlobalDataStorage

+ (TDBSession *)tdbss
{
    return _tdbss;
}
+ (void)setTdbss:(TDBSession *)tdbss
{
    _tdbss = tdbss;
}

+ (NSArray *)seatNameAbbr
{
    if (_seatNameAbbr == nil) {
        _seatNameAbbr = [[NSArray alloc]
                         initWithObjects:@"商务", @"特等", @"一等", @"二等", @"高软", @"软卧", @"硬卧", @"软座", @"硬座", @"无坐", @"其它", nil];
    }
    return _seatNameAbbr;
}

+ (NSArray *)seatNameFull
{
    if (_seatNameFull == nil) {
        _seatNameFull = [[NSArray alloc]
                         initWithObjects:@"商务座", @"特等坐", @"一等座", @"二等座", @"高级软", @"软卧", @"硬卧", @"软座", @"硬座", @"无坐", @"其它", nil];
    }
    return _seatNameFull;
}

+ (NSString *)userInputArriveStation
{
    return _userInputArriveStation;
}
+ (NSString *)userInputDepartStation
{
    return _userInputDepartStation;
}
+ (void)setUserInputDepartStation:(NSString *)userInputDepartStation
{
    _userInputDepartStation = userInputDepartStation;
}
+ (void)setUserInputArriveStation:(NSString *)userInputArriveStation
{
    _userInputArriveStation = userInputArriveStation;
}


@end
