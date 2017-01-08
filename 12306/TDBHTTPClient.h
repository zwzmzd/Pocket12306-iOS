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

@interface TDBHTTPClient : AFHTTPSessionManager

+ (TDBHTTPClient *)sharedClient;

- (void)cancelAllHTTPRequest;

// 车站代码表
- (void)getStationNameAndTelecode:(void (^)(NSData *))success;

// 登录模块
- (void)getVerifyImage:(void (^)(NSData *))success;
- (void)loginWithName:(NSString *)name AndPassword:(NSString *)password andVerifyCode:(NSString *)verifyCode success:(void (^)(NSDictionary *))success;
// 查询可用车票
// 预操作
- (void)qt:(NSString *)date from:(NSString *)from to:(NSString *)to success:(void (^)())success;
// 查询前记录一下log
- (void)leftTicketLogWithDate:(NSString *)date from:(NSString *)from to:(NSString *)to success:(void (^)(NSData *))success;
// 输入购票时间，起点站，终点站，获取余票信息
- (void)queryLeftTickWithDate:(NSString *)date from:(NSString *)from to:(NSString *)to success:(void (^)(NSData *))success;
// 获取指定列车的停靠站列表
- (void)queryaTrainStopTimeByTrainNo:(NSString *)trainNo
                 fromStationTelecode:(NSString *)fromStationTelecode
                   toStationTelecode:(NSString *)toStationTelecode
                          departDate:(NSString *)departDate
                             success:(void (^)(NSArray *))success;



// 查询车票
- (void)checkUser:(void (^)(BOOL))finish;
- (void)submutOrderRequestWithTrainInfo:(TDBTrainInfo *)train date:(NSString *)date finish:(void (^)(NSDictionary *))finish;
- (void)initDc:(void (^)(NSData *))success;
- (void)getRandpImage:(void (^)(NSData *))success;

// 提交购票
- (void)checkOrderInfo:(NSString *)postBody finish:(void (^)(NSDictionary *))finish;
- (void)getQueueCount:(NSString *)postBody finish:(void (^)(NSDictionary *))finish;
- (void)confirmSingleForQueue:(NSString *)postBody finish:(void (^)(NSDictionary *))finish;



// 订单查看
- (void)queryMyOrder:(void (^)(NSArray *))success;
- (void)queryMyOrderNoComplete:(void (^)(NSArray *))success;
- (void)cancelQueryMyOrderHTTPRequest;

//支付
- (void)cancelNoCompleteMyOrder:(NSString *)sequenceNo success:(void (^)(BOOL, NSArray *))success;
- (void)continuePayNoCompleteMyOrder:(NSString *)sequenceNo success:(void (^)(NSDictionary *))success;
- (void)payOrderInit:(void (^)(NSData *))success;
- (void)paycheck:(void (^)(NSDictionary *))success;


// 根据订单号，apacheToken，还有ticketToken获取一个未完成订单的支付页面
- (void)laterEpayWithOrderSequenceNo:(NSString *)orderSequenceNo apacheToken:(NSString *)apacheToken ticketKey:(NSString *)ticketKey success:(void (^)(NSData *))success;

- (void)getPassengersWithIndex:(NSUInteger)index size:(NSUInteger)size success:(void (^)(NSDictionary *))success;
- (void)addPassenger:(NSString *)postBody finish:(void (^)(BOOL))finish;
- (void)deletePassenger:(NSString *)name idCardNo:(NSString *)idCardNo success:(void (^)(BOOL))success;
- (void)cancelGetPassengers;
@end
