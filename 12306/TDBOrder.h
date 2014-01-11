//
//  TDBOrder.h
//  12306
//
//  Created by macbook on 13-7-28.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ORDER_STATUS_UNFINISHED = 1,
    ORDER_STATUS_PAID,
    ORDER_STATUS_OTHER
} ORDER_STATUS;

@interface PassengerInOrder : NSObject

@property (nonatomic, copy) NSString *vehicle;
@property (nonatomic, copy) NSString *seatNo;
@property (nonatomic, copy) NSString *seatType;
@property (nonatomic, copy) NSString *ticketType;
@property (nonatomic, copy) NSString *price;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *idcardType;
@property (nonatomic, copy) NSString *idcardNo;
@property (nonatomic, copy) NSString *status;

@end

@interface TDBOrder : NSObject

@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSString *orderDate;
@property (nonatomic, copy) NSString *trainNo;
@property (nonatomic, copy) NSString *departStationName;
@property (nonatomic, copy) NSString *arriveStationName;
@property (nonatomic, copy) NSString *departTime;
@property (nonatomic, copy) NSString *statusDescription;
@property (nonatomic, copy) NSString *totalPrice;
@property (nonatomic) ORDER_STATUS status;

@property (nonatomic, copy) NSString *orderSequence_no;
@property (nonatomic, copy) NSString *ticketKey;

@property (nonatomic, strong) NSArray *names;
@property (nonatomic, strong) NSArray *passengers;

@end
