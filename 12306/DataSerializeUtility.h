//
//  DataSerializeUtility.h
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StationInfo;

@interface DataSerializeUtility : NSObject

+ (NSString *)generatePOSTDataWithDictionary:(NSDictionary *)dict;

+ (NSString *)parseLeftTicket:(NSString *)rawdata;

+ (NSString *)parseOrderKey:(NSString *)rawdata;

@end



@interface POSTDataConstructor : NSObject

- (void)addValue:(NSString *)value forKey:(NSString *)key;

- (NSString *)getFinalData;

@end

@interface StationInfo : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *time;

@end