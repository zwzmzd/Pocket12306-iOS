//
//  TDBContactList.m
//  12306
//
//  Created by Wenzhe Zhou on 14-3-6.
//  Copyright (c) 2014年 zwz. All rights reserved.
//

#import "TDBContactList.h"
#import "PassengerInfo.h"

@interface TDBContactList()

@property (nonatomic, strong) NSMutableDictionary *index;

@end

@implementation TDBContactList

+ (NSString *)_keyFromContact:(NSDictionary *)contact {
    NSString *raw = [NSString stringWithFormat:@"%@%@",
            [contact objectForKey:@"passenger_id_no"], [contact objectForKey:@"passenger_name"]];
    return raw;
}

+ (NSString *)_keyFromPassenger:(PassengerInfo *)passenger {
    NSString *raw = [NSString stringWithFormat:@"%@%@",
                     passenger.id_cardno, passenger.name];
    return raw;
}

- (BOOL)isValid:(PassengerInfo *)passenger {
    NSString *key = [[self class] _keyFromPassenger:passenger];
    NSNumber *index = [self.index objectForKey:key];
    if (index) {
        NSInteger nn = [index intValue];
        NSDictionary *contact = [self.data objectAtIndex:nn];
        
        NSString *num = [contact objectForKey:@"total_times"];
        if (num == nil) {
            num = @"0";
        }
        
        NSInteger i = [num intValue];
        if (i == 93 || i == 95 || i == 97 || i == 99) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (id)initWithArray:(NSArray *)data {
    if (self = [super init]) {
        self.data = [data copy];
        
        self.index = [NSMutableDictionary new];
        for (NSInteger i = 0; i < self.data.count; i++) {
            NSDictionary *info = [self.data objectAtIndex:i];
            NSString *key = [[self class] _keyFromContact:info];
            NSNumber *target = [NSNumber numberWithInt:i];
            
            if ([self.index objectForKey:key] == nil) {
                [self.index setObject:target forKey:key];
            }
        }
    }
    return self;
}

- (BOOL)isInSet:(PassengerInfo *)passenger {
    NSString *key = [[self class] _keyFromPassenger:passenger];
    return ([self.index objectForKey:key] != nil);
}

@end
