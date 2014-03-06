//
//  TDBContactList.h
//  12306
//
//  Created by Wenzhe Zhou on 14-3-6.
//  Copyright (c) 2014年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PassengerInfo;
@interface TDBContactList : NSObject

@property (nonatomic, strong) NSArray *data;

- (id)initWithArray:(NSArray *)data;
- (BOOL)isValid:(PassengerInfo *)passenger;
- (BOOL)isInSet:(PassengerInfo *)passenger;

@end
