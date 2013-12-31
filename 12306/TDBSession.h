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
#define SYSURL @"http://kyfw.12306.cn"

typedef enum {
    LOGIN_MSG_SUCCESS = 0,
    LOGIN_MSG_USERNAME_ERR,
    LOGIN_MSG_PASSWORD_ERR,
    LOGIN_MSG_OUTOFSERVICE,
    LOGIN_MSG_UNEXPECTED
} LOGIN_MSG_TYPE;

@interface TDBSession : NSObject

@property (nonatomic, copy) NSData *image;

+ (void)resetSession;

// 购票第一步：验证订单信息正确性。若订单信息正确，返回nil；否则返回错误信息
- (NSString *)checkOrderInfo:(TDBTrainInfo *)train  passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketStr:(NSString *)leftTicketStr apacheToken:(NSString *)apacheToken randCode:(NSString *)randCode;
// 购票第二步，照抄即可
- (BOOL)getQueueCount:(TDBTrainInfo *)train passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketID:(NSString *)leftTicketID;
// 购票第三步，正式提交订单信息
- (BOOL)confirmSingleForQueue:(TDBTrainInfo *)train passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketStr:(NSString *)leftTicketStr apacheToken:(NSString *)apacheToken randCode:(NSString *)randCode;

// 获取用户的未完成（叫未支付更为贴切）订单
- (NSData *)queryMyOrderNotComplete;
// 获取用户一般状态的订单
- (NSData *)queryMyOrder;

// 取消一个未完成订单
- (NSData *)cancleMyOrderNotComplete:(NSString *)sequenceNo apacheToken:(NSString *)apacheToken;

- (void)restartSession;

@end
