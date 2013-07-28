//
//  TDBOrder.h
//  12306
//
//  Created by macbook on 13-7-28.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PassengerInOrder : NSObject

@property (nonatomic, copy) NSString *vehicle;
@property (nonatomic, copy) NSString *seatNo;
@property (nonatomic, copy) NSString *seatType;
@property (nonatomic, copy) NSString *ticketType;
@property (nonatomic, copy) NSString *price;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *idcardType;

@end

@interface TDBOrder : NSObject

@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSString *trainNo;
@property (nonatomic, copy) NSString *departStationName;
@property (nonatomic, copy) NSString *arriveStationName;
@property (nonatomic, copy) NSString *departTime;
@property (nonatomic) BOOL unfinished;

@property (nonatomic, copy) NSString *orderSquence_no;
@property (nonatomic, copy) NSString *ticketKey;

@property (nonatomic) NSArray *passengers;

@end
