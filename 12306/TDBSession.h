//
//  TDBSession.h
//  12306
//
//  Created by macbook on 13-7-17.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDBTrainInfo;
@class PassengerInfo;
#define SYSURL @"http://dynamic.12306.cn"

typedef enum {
    LOGIN_MSG_SUCCESS = 0,
    LOGIN_MSG_USERNAME_ERR,
    LOGIN_MSG_PASSWORD_ERR,
    LOGIN_MSG_OUTOFSERVICE,
    LOGIN_MSG_UNEXPECTED
} LOGIN_MSG_TYPE;

@interface TDBSession : NSObject

@property (nonatomic, copy) NSData *image;


- (void)getSession;

// 这个是登录页面的验证码获取
- (NSData *)getVerifyImage;

- (NSData *)getLoginPasscode;

// 这个是用于购票页面验证码获取
- (NSData *)getRandpImage;

// 登录12306
- (LOGIN_MSG_TYPE)loginWithName:(NSString *)name AndPassword:(NSString *)password andVerifyCode:(NSString *)verifyCode passkey:(NSString *)passkey passcode:(NSString *)passcode;

// 输入购票时间，起点站，终点站，获取余票信息
- (NSArray *)queryLeftTickWithDate:(NSString *)date from:(NSString *)from to:(NSString *)to;

// 在余票列表中选择一个车次后，获取订票页面
- (NSData *)submutOrderRequestWithTrainInfo:(TDBTrainInfo *)train date:(NSString *)date;

// 购票第一步：验证订单信息正确性。若订单信息正确，返回nil；否则返回错误信息
- (NSString *)checkOrderInfo:(TDBTrainInfo *)train  passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketStr:(NSString *)leftTicketStr apacheToken:(NSString *)apacheToken randCode:(NSString *)randCode;
// 购票第二步，照抄即可
- (BOOL)getQueueCount:(TDBTrainInfo *)train passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketID:(NSString *)leftTicketID;
// 购票第三步，正式提交订单信息
- (BOOL)confirmSingleForQueue:(TDBTrainInfo *)train passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketStr:(NSString *)leftTicketStr apacheToken:(NSString *)apacheToken randCode:(NSString *)randCode;

// 获取用户的未完成（叫未支付更为贴切）订单
- (NSData *)queryMyOrderNotComplete;
// 获取用户一般状态的订单，传入一个订单查询的起始时间和终止时间
- (NSData *)queryMyOrderWithFromOrderDate:(NSString *)fromOrderDate endOrderDate:(NSString *)endOrderDate;

// 根据订单号，apacheToken，还有ticketToken获取一个未完成订单的支付页面
- (NSData *)laterEpayWithOrderSequenceNo:(NSString *)orderSequenceNo
                             apacheToken:(NSString *)apacheToken
                               ticketKey:(NSString *)ticketKey;

// 获取指定列车的停靠站列表
- (NSArray *)queryaTrainStopTimeByTrainNo:(NSString *)trainNo
                           fromStationTelecode:(NSString *)fromStationTelecode
                             toStationTelecode:(NSString *)toStationTelecode
                                    departDate:(NSString *)departDate;

// 取消一个未完成订单
- (NSData *)cancleMyOrderNotComplete:(NSString *)sequenceNo apacheToken:(NSString *)apacheToken;

// 获取联系人
- (NSDictionary *)getPassengersWithIndex:(NSUInteger)index size:(NSUInteger)size;

- (void)restartSession;



@end
