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

@implementation GlobalDataStorage

+ (TDBSession *)tdbss
{
    return _tdbss;
}
+ (void)setTdbss:(TDBSession *)tdbss
{
    _tdbss = tdbss;
}



@end
