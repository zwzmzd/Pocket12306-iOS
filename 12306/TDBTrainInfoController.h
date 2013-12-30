//
//  TDBTrainInfoController.h
//  12306
//
//  Created by macbook on 13-7-18.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDBTrainInfo;

@interface TDBTrainInfoController : NSObject

- (void)addTrainInfo:(TDBTrainInfo *)train;

- (NSUInteger)count;

- (TDBTrainInfo *)getTrainInfoForIndex:(NSUInteger)index;

@end
