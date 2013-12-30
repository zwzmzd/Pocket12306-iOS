//
//  TDBTrainInfo.h
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDBTrainInfo : NSObject

@property (nonatomic, strong) NSDictionary *original;

- (id)initWithDict: (NSDictionary *)original;

- (NSString *)getTrainNo;

- (NSString *)getDuration;

- (NSString *)getDepartTime;

- (NSString *)getTrainCode;

- (NSString *)getDepartStationTeleCode;

- (NSString *)getArriveStationTeleCode;

- (NSString *)getArriveTime;

- (NSString *)getDapartStationName;

- (NSString *)getArriveStationName;

- (NSString *)getDepartStationNo;

- (NSString *)getArriveStationNo;

- (NSString *)getYPInfoDetail;

- (NSString *)getMMStr;

- (NSString *)getLocationCode;

@end
