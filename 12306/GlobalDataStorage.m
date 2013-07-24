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
static NSString *_date = @"2013-07-28";

@implementation GlobalDataStorage

+ (TDBSession *)tdbss
{
    return _tdbss;
}
+ (void)setTdbss:(TDBSession *)tdbss
{
    _tdbss = tdbss;
}

+ (void)setDate:(NSString *)date
{
    _date = date;
}
+ (NSString *)date
{
    return _date;
}



@end
