//
//  PassengerInfo.m
//  12306
//
//  Created by macbook on 13-7-19.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "PassengerInfo.h"

@implementation PassengerInfo

- (NSString *)generateTicketString
{
    return [NSString stringWithFormat:@"%@,0,%@,%@,%@,%@,%@,N", self.seat, self.ticket, self.name, self.id_cardtype, self.id_cardno, self.mobileno];
}

@end
