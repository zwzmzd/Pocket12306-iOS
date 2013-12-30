//
//  TDBTrainInfoController.m
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import "TDBTrainInfoController.h"
#import "TDBTrainInfo.h"

@interface TDBTrainInfoController()

@property (nonatomic) NSMutableArray *list;

@end


@implementation TDBTrainInfoController

- (id)init
{
    self = [super init];
    if (self) {
        _list = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addTrainInfo:(TDBTrainInfo *)train
{
    [self.list addObject:train];
}

- (NSUInteger)count
{
    return [self.list count];
}

- (TDBTrainInfo *)getTrainInfoForIndex:(NSUInteger)index
{
    return [self.list objectAtIndex:index];
}

@end
