//
//  TDBTrainTimetableViewController.h
//  12306
//
//  Created by macbook on 13-8-10.
//  Copyright (c) 2013年 zwz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TDBTrainInfo;

@interface TDBTrainTimetableViewController : UITableViewController

@property (nonatomic) TDBTrainInfo *train;
@property (nonatomic) NSString *departDate;

@end
