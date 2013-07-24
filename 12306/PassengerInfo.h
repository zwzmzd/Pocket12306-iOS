//
//  PassengerInfo.h
//  12306
//
//  Created by macbook on 13-7-19.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PassengerInfo : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *id_cardtype;
@property (nonatomic, copy) NSString *id_cardno;
@property (nonatomic, copy) NSString *mobileno;
@property (nonatomic, copy) NSString *seat;
@property (nonatomic, copy) NSString *ticket;

- (NSString *)generateTicketString;

@end
