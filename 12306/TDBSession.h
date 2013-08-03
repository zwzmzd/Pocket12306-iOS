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

- (NSData *)getVerifyImage;

- (NSData *)getRandpImage;

- (LOGIN_MSG_TYPE)loginWithName:(NSString *)name AndPassword:(NSString *)password andVerifyCode:(NSString *)verifyCode;

- (NSArray *)queryLeftTickWithDate:(NSString *)date from:(NSString *)from to:(NSString *)to;

- (NSData *)submutOrderRequestWithTrainInfo:(TDBTrainInfo *)train date:(NSString *)date;

- (BOOL)checkOrderInfo:(TDBTrainInfo *)train  passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketStr:(NSString *)leftTicketStr apacheToken:(NSString *)apacheToken randCode:(NSString *)randCode;

- (BOOL)getQueueCount:(TDBTrainInfo *)train passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketID:(NSString *)leftTicketID;

- (BOOL)confirmSingleForQueue:(TDBTrainInfo *)train passenger:(PassengerInfo *)passenger date:(NSString *)date leftTicketStr:(NSString *)leftTicketStr apacheToken:(NSString *)apacheToken randCode:(NSString *)randCode;

- (NSData *)queryMyOrderNotComplete;
- (NSData *)queryMyOrderWithFromOrderDate:(NSString *)fromOrderDate endOrderDate:(NSString *)endOrderDate;

- (NSData *)laterEpayWithOrderSequenceNo:(NSString *)orderSequenceNo
                             apacheToken:(NSString *)apacheToken
                               ticketKey:(NSString *)ticketKey;

- (NSDictionary *)queryaTrainStopTimeByTrainNo:(NSString *)trainNo
                           fromStationTelecode:(NSString *)fromStationTelecode
                             toStationTelecode:(NSString *)toStationTelecode
                                    departDate:(NSString *)departDate;

- (void)restartSession;



@end
