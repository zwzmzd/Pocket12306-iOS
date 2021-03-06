//
//  GlobalDataStorage.h
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDBSession;

@interface GlobalDataStorage : NSObject

+ (TDBSession *)tdbss;
+ (void)setTdbss:(TDBSession *)tdbss;

+ (NSArray *)seatNameAbbr;
+ (NSArray *)seatNameFull;

+ (NSString *)userInputDepartStation;
+ (void)setUserInputDepartStation:(NSString *)userInputDepartStation;

+ (NSString *)userInputArriveStation;
+ (void)setUserInputArriveStation:(NSString *)userInputArriveStation;

+ (NSString *)getTodayDateInString;
+ (NSString *)dateInString:(NSDate *)date;

@end
