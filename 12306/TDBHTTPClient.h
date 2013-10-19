//
//  TDBHTTPClient.h
//  12306
//
//  Created by Wenzhe Zhou on 13-10-19.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "AFNetworking.h"
#import "TDBOrder.h"
#import "TDBTrainInfo.h"

@interface TDBHTTPClient : AFHTTPClient

+ (TDBHTTPClient *)sharedClient;

// 登录模块
- (void)getVerifyImage:(void (^)(NSData *))success;
- (void)getLoginToken:(void (^)(NSData *))success;
- (void)loginAysnSuggest:(void (^)(NSDictionary *))success;
- (void)loginWithName:(NSString *)name AndPassword:(NSString *)password andVerifyCode:(NSString *)verifyCode loginRand:(NSString *)loginRand tokenKey:(NSString *)tokenKey tokenValue:(NSString *)tokenValue success:(void (^)())success;

// 查询可用车票
// 预操作
- (void)qt:(NSString *)date from:(NSString *)from to:(NSString *)to success:(void (^)())success;
// 输入购票时间，起点站，终点站，获取余票信息
- (void)queryLeftTickWithDate:(NSString *)date from:(NSString *)from to:(NSString *)to success:(void (^)(NSData *))success;
// 获取指定列车的停靠站列表
- (void)queryaTrainStopTimeByTrainNo:(NSString *)trainNo
                 fromStationTelecode:(NSString *)fromStationTelecode
                   toStationTelecode:(NSString *)toStationTelecode
                          departDate:(NSString *)departDate
                             success:(void (^)(NSArray *))success;



// 提交购票信息
- (void)getSubmutToken:(void (^)(NSData *))success;
- (void)submutOrderRequestWithTrainInfo:(TDBTrainInfo *)train date:(NSString *)date tokenKey:(NSString *)tokenKey tokenValue:(NSString *)tokenValue success:(void (^)(NSData *))success;
- (void)getRandpImage:(void (^)(NSData *))success;

- (void)getPassengersWithIndex:(NSUInteger)index size:(NSUInteger)size success:(void (^)(NSDictionary *))success;
@end
